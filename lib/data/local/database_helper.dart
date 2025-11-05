import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/bill_report.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'greenbill.db');
    
    // Delete the existing database to start fresh
    await deleteDatabase(path);
    
    return await openDatabase(
      path,
      version: 1, // Start with version 1
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create the tables in the correct order
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        name TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE bill_reports(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        billType TEXT NOT NULL,
        items TEXT NOT NULL,
        totalCarbonFootprint REAL NOT NULL,
        totalAmount REAL NOT NULL,
        categoryBreakdown TEXT NOT NULL,
        ecoScore INTEGER NOT NULL,
        imagePath TEXT,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.transaction((txn) async {
        // Add userId column to bill_reports table if it doesn't exist
        var columns = await txn.rawQuery('PRAGMA table_info("bill_reports")');
        bool hasUserIdColumn = columns.any((col) => col['name'].toString() == 'userId');
        
        if (!hasUserIdColumn) {
          await txn.execute('ALTER TABLE bill_reports ADD COLUMN userId TEXT');
        }

        // Update existing records to link to a default user if needed
        const defaultUserId = 'legacy_user';
        final defaultTimestamp = DateTime.now().toIso8601String();
        
        // Set default values for all NULL fields
        final updates = [
          {'column': 'userId', 'value': defaultUserId},
          {'column': 'timestamp', 'value': defaultTimestamp},
          {'column': 'billType', 'value': 'unknown'},
          {'column': 'items', 'value': '[]'},
          {'column': 'totalCarbonFootprint', 'value': 0},
          {'column': 'totalAmount', 'value': 0},
          {'column': 'categoryBreakdown', 'value': '{}'},
          {'column': 'ecoScore', 'value': 0}
        ];

        for (var update in updates) {
          await txn.execute(
            'UPDATE bill_reports SET ${update['column']} = ? WHERE ${update['column']} IS NULL',
            [update['value']]
          );
        }

        // Verify no NULL values remain
        final nullCheck = await txn.rawQuery('''
          SELECT COUNT(*) as count FROM bill_reports 
          WHERE userId IS NULL 
             OR timestamp IS NULL
             OR billType IS NULL 
             OR items IS NULL
             OR totalCarbonFootprint IS NULL
             OR totalAmount IS NULL
             OR categoryBreakdown IS NULL
             OR ecoScore IS NULL
        ''');

        if (nullCheck.first['count'] as int > 0) {
          throw Exception('Found NULL values in required fields after update');
        }

        // Create new table with NOT NULL constraints
        await txn.execute('''
          CREATE TABLE bill_reports_new(
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            billType TEXT NOT NULL,
            items TEXT NOT NULL,
            totalCarbonFootprint REAL NOT NULL,
            totalAmount REAL NOT NULL,
            categoryBreakdown TEXT NOT NULL,
            ecoScore INTEGER NOT NULL,
            imagePath TEXT,
            FOREIGN KEY (userId) REFERENCES users(id)
          )
        ''');

        // Copy data to new table
        await txn.execute('INSERT INTO bill_reports_new SELECT * FROM bill_reports');

        // Drop old table and rename new one
        await txn.execute('DROP TABLE bill_reports');
        await txn.execute('ALTER TABLE bill_reports_new RENAME TO bill_reports');

        // Create indexes for faster lookups
        await txn.execute('CREATE INDEX idx_bill_reports_user_id ON bill_reports(userId)');
        await txn.execute('CREATE INDEX idx_bill_reports_timestamp ON bill_reports(timestamp)');
      });
    }
  }

  Future<int> insertBillReport(BillReport report) async {
    try {
      final db = await database;
      final reportMap = report.toMap();
      
      print('Inserting bill report: $reportMap');
      
      await db.insert(
        'bill_reports',
        reportMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return 1;
    } catch (e, stackTrace) {
      print('Error inserting bill report: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<List<BillReport>> getAllBillReports(String userId) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'bill_reports',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
      );

      return List.generate(maps.length, (i) {
        try {
          return BillReport.fromMap(maps[i]);
        } catch (e, stackTrace) {
          print('Error parsing bill report: $e');
          print(stackTrace);
          return BillReport(
            id: maps[i]['id'] as String? ?? 'error',
            userId: maps[i]['userId'] as String? ?? userId,
            billType: maps[i]['billType'] as String? ?? 'unknown',
            timestamp: DateTime.tryParse(maps[i]['timestamp'] as String? ?? '') ?? DateTime.now(),
            items: [],
            totalCarbonFootprint: 0,
            totalAmount: 0,
            categoryBreakdown: {},
            ecoScore: 0,
          );
        }
      });
    } catch (e, stackTrace) {
      print('Error querying database: $e');
      print(stackTrace);
      return [];
    }
  }

  Future<BillReport?> getBillReport(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bill_reports',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return BillReport.fromMap(maps.first);
  }

  Future<int> deleteBillReport(String id) async {
    final db = await database;
    return await db.delete(
      'bill_reports',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<BillReport>> getBillReportsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bill_reports',
      where: 'userId = ? AND timestamp BETWEEN ? AND ?',
      whereArgs: [userId, startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return BillReport.fromMap(maps[i]);
    });
  }

  Future<Map<String, double>> getMonthlyStats(String userId, int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));
    
    final reports = await getBillReportsByDateRange(userId, startDate, endDate);
    
    double totalCarbon = 0;
    double totalAmount = 0;
    
    for (var report in reports) {
      totalCarbon += report.totalCarbonFootprint;
      totalAmount += report.totalAmount;
    }
    
    return {
      'totalCarbon': totalCarbon,
      'totalAmount': totalAmount,
      'count': reports.length.toDouble(),
    };
  }
}
