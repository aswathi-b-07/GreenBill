import 'package:flutter/material.dart';
import '../data/repositories/bill_repository.dart';
import '../data/models/bill_report.dart';
import '../widgets/trend_chart.dart';
import '../widgets/carbon_insight_card.dart';
import '../widgets/time_range_selector.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import 'bill_details_screen.dart';

class CarbonDiaryScreen extends StatefulWidget {
  const CarbonDiaryScreen({Key? key}) : super(key: key);

  @override
  State<CarbonDiaryScreen> createState() => _CarbonDiaryScreenState();
}

class _CarbonDiaryScreenState extends State<CarbonDiaryScreen> {
  final BillRepository _billRepository = BillRepository();
  List<BillReport> _allReports = [];
  bool _isLoading = true;
  String _filterType = 'all'; // 'all', 'petrol', 'supermarket'
  String _timeRange = '1M'; // '1W', '1M', '3M', '6M', '1Y', 'ALL'

  DateTime get _rangeStartDate {
    final now = DateTime.now();
    switch (_timeRange) {
      case '1W':
        return now.subtract(const Duration(days: 7));
      case '1M':
        return DateTime(now.year, now.month - 1, now.day);
      case '3M':
        return DateTime(now.year, now.month - 3, now.day);
      case '6M':
        return DateTime(now.year, now.month - 6, now.day);
      case '1Y':
        return DateTime(now.year - 1, now.month, now.day);
      case 'ALL':
      default:
        return DateTime(2000); // A date far in the past
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAndLoadReports();
  }

  Future<void> _initializeAndLoadReports() async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Please login to view your carbon diary',
          isError: true,
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }
    _billRepository.setCurrentUser(currentUser.id);
    await _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await _billRepository.getAllReports();
      setState(() {
        _allReports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error loading reports: $e',
          isError: true,
        );
      }
    }
  }

  List<BillReport> get _filteredReports {
    final dateFiltered = _allReports
        .where((r) => r.timestamp.isAfter(_rangeStartDate))
        .toList();
    if (_filterType == 'all') return dateFiltered;
    return dateFiltered.where((r) => r.billType == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carbon Diary'),
        backgroundColor: AppConstants.primaryGreen,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allReports.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFilterChips(),
                      TimeRangeSelector(
                        selectedRange: _timeRange,
                        onRangeSelected: (value) {
                          setState(() {
                            _timeRange = value;
                          });
                        },
                      ),
                      _buildStatsCard(),
                      if (_filteredReports.length >= 3) ...[
                        TrendChart(reports: _filteredReports),
                        CarbonInsightCard(reports: _filteredReports),
                      ],
                      _buildReportsList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No reports yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning bills to track your carbon footprint',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Fuel', AppConstants.billTypePetrol),
          const SizedBox(width: 8),
          _buildFilterChip('Grocery', AppConstants.billTypeGrocery),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppConstants.primaryGreen.withOpacity(0.2),
      checkmarkColor: AppConstants.primaryGreen,
    );
  }

  Widget _buildStatsCard() {
    final totalCarbon = _filteredReports.fold<double>(
      0,
      (sum, report) => sum + report.totalCarbonFootprint,
    );
    final avgCarbon = _filteredReports.isEmpty
        ? 0.0
        : totalCarbon / _filteredReports.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConstants.primaryGreen, AppConstants.lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Total Scans', '${_filteredReports.length}'),
          _buildStatColumn('Total CO₂', '${totalCarbon.toStringAsFixed(1)} kg'),
          _buildStatColumn('Average', '${avgCarbon.toStringAsFixed(1)} kg'),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildReportsList() {
    final groupedReports = _groupReportsByMonth(_filteredReports);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groupedReports.length,
      itemBuilder: (context, index) {
        final entry = groupedReports.entries.elementAt(index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${Helpers.getMonthName(entry.key.month)} ${entry.key.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...entry.value.map((report) => _buildReportCard(report)).toList(),
          ],
        );
      },
    );
  }

  Map<DateTime, List<BillReport>> _groupReportsByMonth(List<BillReport> reports) {
    final grouped = <DateTime, List<BillReport>>{};
    for (var report in reports) {
      final key = DateTime(report.timestamp.year, report.timestamp.month);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(report);
    }
    return Map.fromEntries(
        grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
  }

  Widget _buildReportCard(BillReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BillDetailsScreen(report: report),
            ),
          );
        },
        child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: report.billType == AppConstants.billTypePetrol
              ? AppConstants.fuelColor.withOpacity(0.2)
              : AppConstants.foodColor.withOpacity(0.2),
          child: Icon(
            report.billType == AppConstants.billTypePetrol
                ? Icons.local_gas_station
                : Icons.shopping_cart,
            color: report.billType == AppConstants.billTypePetrol
                ? AppConstants.fuelColor
                : AppConstants.foodColor,
          ),
        ),
        title: Text(
          Helpers.formatCarbon(report.totalCarbonFootprint),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(Helpers.formatDateTime(report.timestamp)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Helpers.getScoreColor(report.ecoScore),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${report.ecoScore}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...report.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.name} (${item.quantity} ${item.unit})',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            Helpers.formatCarbon(item.carbonFootprint ?? 0),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _deleteReport(report.id),
                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
        ),
    );
  }

  Future<void> _deleteReport(String reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _billRepository.deleteReport(reportId);
        await _loadReports();
        if (mounted) {
          Helpers.showSnackBar(context, 'Report deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          Helpers.showSnackBar(
            context,
            'Error deleting report: $e',
            isError: true,
          );
        }
      }
    }
  }
}
