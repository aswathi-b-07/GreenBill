import 'package:sqflite/sqflite.dart';

class MigrationHelper {
  static Future<void> migrateToUserAssociation(Database db) async {
    // First, check if the userId column exists
    var columns = await db.rawQuery('PRAGMA table_info(bill_reports)');
    bool hasUserIdColumn = columns.any((col) => col['name'] == 'userId');

    if (!hasUserIdColumn) {
      // Start a transaction
      await db.transaction((txn) async {
        // Add the userId column
        await txn.execute('ALTER TABLE bill_reports ADD COLUMN userId TEXT NOT NULL DEFAULT "system"');
        
        // Create index for faster lookups
        await txn.execute('CREATE INDEX idx_bill_reports_user_id ON bill_reports(userId)');
      });
    }
  }
}