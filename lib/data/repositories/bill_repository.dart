import '../local/database_helper.dart';
import '../models/bill_report.dart';

class BillRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String? _currentUserId;

  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  String get currentUserId {
    if (_currentUserId == null) {
      throw Exception('User ID not set. Call setCurrentUser first.');
    }
    return _currentUserId!;
  }

  Future<void> saveBillReport(BillReport report) async {
    await _dbHelper.insertBillReport(report);
  }

  Future<List<BillReport>> getAllReports() async {
    return await _dbHelper.getAllBillReports(currentUserId);
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
    return await _dbHelper.getBillReportsByDateRange(currentUserId, startDate, endDate);
  }

  Future<Map<String, double>> getMonthlyStatistics(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    final reports = await _dbHelper.getBillReportsByDateRange(currentUserId, startDate, endDate);

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
