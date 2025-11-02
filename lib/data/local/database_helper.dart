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
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bill_reports(
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        billType TEXT NOT NULL,
        items TEXT NOT NULL,
        totalCarbonFootprint REAL NOT NULL,
        totalAmount REAL NOT NULL,
        categoryBreakdown TEXT NOT NULL,
        ecoScore INTEGER NOT NULL,
        imagePath TEXT
      )
    ''');
  }

  Future<int> insertBillReport(BillReport report) async {
    final db = await database;
    await db.insert(
      'bill_reports',
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return 1;
  }

  Future<List<BillReport>> getAllBillReports() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bill_reports',
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return BillReport.fromMap(maps[i]);
    });
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
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bill_reports',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return BillReport.fromMap(maps[i]);
    });
  }

  Future<Map<String, double>> getMonthlyStats(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));
    
    final reports = await getBillReportsByDateRange(startDate, endDate);
    
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
