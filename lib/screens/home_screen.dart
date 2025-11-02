import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/local/database_helper.dart';
import '../data/models/bill_report.dart';
import 'dart:io';
import '../utils/helpers.dart';
import '../utils/constants.dart';
import '../widgets/bill_picker/bill_image_picker.dart';
import 'scan_screen.dart';
import 'carbon_diary_screen.dart';
import 'gallery_screen.dart';
import 'bill_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<BillReport> _recentReports = [];
  bool _isLoading = true;
  double _totalMonthlyCarbon = 0;
  int _totalScans = 0;
  double _averagePerBill = 0;

  @override
  void initState() {
    super.initState();
    _loadRecentReports();
    _loadMonthlyStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this screen
    _refreshData();
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadRecentReports(),
      _loadMonthlyStats(),
    ]);
  }

  Future<void> _loadRecentReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await _dbHelper.getAllBillReports();
      setState(() {
        _recentReports = reports.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reports: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMonthlyStats() async {
    final now = DateTime.now();
    final stats = await _dbHelper.getMonthlyStats(now.year, now.month);
    setState(() {
      _totalMonthlyCarbon = stats['totalCarbon'] ?? 0;
      _totalScans = stats['count']?.toInt() ?? 0;
      _averagePerBill = _totalScans > 0 ? _totalMonthlyCarbon / _totalScans : 0;
    });
  }

  Future<String?> _showBillTypeDialog() {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Bill Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.local_gas_station, color: AppConstants.fuelColor),
                title: const Text('Petrol Bill'),
                onTap: () => Navigator.pop(context, AppConstants.billTypePetrol),
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart, color: AppConstants.foodColor),
                title: const Text('Grocery Bill'),
                onTap: () => Navigator.pop(context, AppConstants.billTypeGrocery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processImage() async {
    try {
      final XFile? selectedImage = await BillImagePicker.pickImage(context);
      
      if (selectedImage == null) {
        if (mounted) {
          Helpers.showSnackBar(
            context,
            'No image selected',
            isError: true,
          );
        }
        return;
      }

      // Show bill type selection dialog
      final billType = await _showBillTypeDialog();
      
      if (billType != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanScreen(
              imageFile: selectedImage,
              billType: billType,
            ),
          ),
        ).then((_) {
          _refreshData();
        });
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error picking image: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _openGallery() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GalleryScreen(),
      ),
    ).then((_) {
      _loadRecentReports();
      _loadMonthlyStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.surfaceColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        backgroundColor: AppConstants.primaryGreen,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppConstants.primaryGreen,
                AppConstants.darkGreen,
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              _buildActionButtons(),
              _buildMonthlyStats(),
              _buildRecentScans(),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryGreen.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CarbonDiaryScreen()),
            ).then((_) {
              _loadRecentReports();
              _loadMonthlyStats();
            });
          },
          label: const Text(
            'Carbon Diary',
            style: AppConstants.buttonStyle,
          ),
          icon: const Icon(Icons.analytics_outlined, color: Colors.white),
          backgroundColor: AppConstants.primaryGreen,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConstants.primaryGreen, AppConstants.accentGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.eco,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to GreenBill',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Track your carbon footprint with every bill',
                      style: TextStyle(
                        color: Colors.white70, 
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: AppConstants.subheadingStyle,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.upload_file,
                  label: 'Upload Bill',
                  subtitle: 'Scan from gallery',
                  color: AppConstants.primaryGreen,
                  onTap: _processImage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.photo_library,
                  label: 'Sample Gallery',
                  subtitle: 'Try sample bills',
                  color: AppConstants.packagingColor,
                  onTap: _openGallery,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: AppConstants.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppConstants.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: AppConstants.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Monthly Overview',
                style: AppConstants.subheadingStyle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.co2,
                  Helpers.formatCarbon(_totalMonthlyCarbon),
                  'Total Emissions',
                  AppConstants.fuelColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  Icons.receipt_long,
                  '$_totalScans',
                  'Scans',
                  AppConstants.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  Icons.trending_down,
                  Helpers.formatCarbon(_averagePerBill),
                  'Avg/Bill',
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppConstants.captionStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScans() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: AppConstants.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Recent Scans',
                    style: AppConstants.subheadingStyle,
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CarbonDiaryScreen(),
                    ),
                  ).then((_) {
                    _loadRecentReports();
                    _loadMonthlyStats();
                  });
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View All'),
                style: TextButton.styleFrom(
                  foregroundColor: AppConstants.primaryGreen,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _recentReports.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentReports.length,
                      itemBuilder: (context, index) {
                        return _buildReportCard(_recentReports[index]);
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppConstants.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.receipt_long,
              size: 48,
              color: AppConstants.primaryGreen,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No scans yet',
            style: AppConstants.subheadingStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Scan your first bill to get started',
            style: AppConstants.captionStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BillReport report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: report.billType == AppConstants.billTypePetrol
                  ? [AppConstants.fuelColor, AppConstants.fuelColor.withOpacity(0.7)]
                  : [AppConstants.foodColor, AppConstants.foodColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (report.billType == AppConstants.billTypePetrol
                    ? AppConstants.fuelColor
                    : AppConstants.foodColor).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            report.billType == AppConstants.billTypePetrol
                ? Icons.local_gas_station
                : Icons.shopping_cart,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          Helpers.formatCarbon(report.totalCarbonFootprint),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppConstants.textPrimary,
          ),
        ),
        subtitle: Text(
          'Scanned on ${Helpers.formatDate(report.timestamp)}',
          style: AppConstants.captionStyle,
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.arrow_forward_ios,
            color: AppConstants.primaryGreen,
            size: 16,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BillDetailsScreen(report: report),
            ),
          );
        },
      ),
    );
  }
}