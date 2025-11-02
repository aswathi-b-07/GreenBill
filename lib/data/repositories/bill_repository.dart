import '../local/database_helper.dart';
import '../models/bill_report.dart';

class BillRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> saveBillReport(BillReport report) async {
    await _dbHelper.insertBillReport(report);
  }

  Future<List<BillReport>> getAllReports() async {
    return await _dbHelper.getAllBillReports();
  }

  Future<BillReport?> getReportById(String id) async {
    return await _dbHelper.getBillReport(id);
  }

  Future<void> deleteReport(String id) async {
    await _dbHelper.deleteBillReport(id);
  }

  Future<List<BillReport>> getReportsByMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    return await _dbHelper.getBillReportsByDateRange(startDate, endDate);
  }

  Future<Map<String, double>> getMonthlyStatistics(int year, int month) async {
    return await _dbHelper.getMonthlyStats(year, month);
  }
}
