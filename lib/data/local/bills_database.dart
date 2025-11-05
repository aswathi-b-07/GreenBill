import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/bill_item.dart';

class BillsDatabase {
  static final BillsDatabase _instance = BillsDatabase._internal();
  static Database? _database;

  factory BillsDatabase() => _instance;

  BillsDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bills.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Bills table
    await db.execute('''
      CREATE TABLE bills(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        bill_type TEXT NOT NULL,
        total_amount REAL NOT NULL,
        carbon_footprint REAL NOT NULL,
        date INTEGER NOT NULL,
        image_path TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Bill items table
    await db.execute('''
      CREATE TABLE bill_items(
        id TEXT PRIMARY KEY,
        bill_id TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total REAL NOT NULL,
        carbon_footprint REAL NOT NULL,
        category TEXT,
        FOREIGN KEY (bill_id) REFERENCES bills(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_bills_user_id ON bills(user_id)');
    await db.execute('CREATE INDEX idx_bill_items_bill_id ON bill_items(bill_id)');
  }

  // Save a bill with its items
  Future<String> saveBill({
    required String userId,
    required String billType,
    required double totalAmount,
    required double carbonFootprint,
    required DateTime date,
    required List<BillItem> items,
    String? imagePath,
  }) async {
    final db = await database;
    final billId = DateTime.now().millisecondsSinceEpoch.toString();

    // Begin transaction
    await db.transaction((txn) async {
      // Insert bill
      await txn.insert('bills', {
        'id': billId,
        'user_id': userId,
        'bill_type': billType,
        'total_amount': totalAmount,
        'carbon_footprint': carbonFootprint,
        'date': date.millisecondsSinceEpoch,
        'image_path': imagePath,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Insert bill items
      for (var item in items) {
        await txn.insert('bill_items', {
          'id': item.id,
          'bill_id': billId,
          'name': item.name,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total': item.total,
          'carbon_footprint': item.carbonFootprint ?? 0.0,
          'category': item.category,
        });
      }
    });

    return billId;
  }

  // Get bills for a user
  Future<List<Map<String, dynamic>>> getUserBills(String userId) async {
    final db = await database;
    
    final bills = await db.query(
      'bills',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    // For each bill, get its items
    final results = <Map<String, dynamic>>[];
    for (var bill in bills) {
      final items = await db.query(
        'bill_items',
        where: 'bill_id = ?',
        whereArgs: [bill['id']],
      );

      results.add({
        ...bill,
        'items': items,
      });
    }

    return results;
  }

  // Get user's carbon footprint stats
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final db = await database;
    
    // Get total carbon footprint
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_bills,
        SUM(carbon_footprint) as total_carbon,
        AVG(carbon_footprint) as avg_carbon,
        MIN(date) as first_bill_date,
        MAX(date) as last_bill_date
      FROM bills
      WHERE user_id = ?
    ''', [userId]);

    // Get carbon footprint by category
    final categoryStats = await db.rawQuery('''
      SELECT 
        bi.category,
        SUM(bi.carbon_footprint) as category_carbon
      FROM bill_items bi
      INNER JOIN bills b ON bi.bill_id = b.id
      WHERE b.user_id = ? AND bi.category IS NOT NULL
      GROUP BY bi.category
    ''', [userId]);

    return {
      'summary': result.first,
      'categories': categoryStats,
    };
  }

  // Delete a bill
  Future<void> deleteBill(String billId) async {
    final db = await database;
    
    await db.delete(
      'bills',
      where: 'id = ?',
      whereArgs: [billId],
    );
    // Note: bill_items will be deleted automatically due to CASCADE
  }

  // Delete all bills for a user
  Future<void> deleteUserBills(String userId) async {
    final db = await database;
    
    await db.delete(
      'bills',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    // Note: bill_items will be deleted automatically due to CASCADE
  }
}