import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'scan_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<String> _sampleImages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSampleImages();
  }

  Future<void> _loadSampleImages() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final manifestMap = json.decode(manifestContent) as Map<String, dynamic>;
      
      final sampleBills = manifestMap.keys
          .where((String key) => key.startsWith('assets/images/sample_bills/') && 
                (key.endsWith('.jpg') || key.endsWith('.jpeg') || key.endsWith('.png')))
          .toList();
      
      setState(() {
        _sampleImages = sampleBills;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading sample images: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Bills Gallery'),
        backgroundColor: AppConstants.primaryGreen,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppConstants.primaryGreen, AppConstants.lightGreen],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: const Text(
                'Choose a sample bill to test the app',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _sampleImages.isEmpty
                        ? _buildEmptyState()
                        : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _sampleImages.length,
                        itemBuilder: (context, index) {
                          return _buildSampleImageCard(_sampleImages[index]);
                        },
                      ),
              ),
            ),
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
          Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No sample images available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add sample bill images to assets/images/sample_bills/',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSampleImageCard(String imagePath) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _selectSampleImage(imagePath),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample Bill ${imagePath.split('/').last.split('.').first}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to process',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectSampleImage(String imagePath) async {
    try {
      // Show bill type selection dialog
      final billType = await _showBillTypeDialog();
      
      if (billType != null && mounted) {
        // Create a temporary file from the asset
        final tempFile = await _createTempFileFromAsset(imagePath);
        
        if (tempFile != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScanScreen(
                imageFile: tempFile,
                billType: billType,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error loading sample image: $e',
          isError: true,
        );
      }
    }
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

  Future<XFile?> _createTempFileFromAsset(String assetPath) async {
    try {
      // Load the asset as bytes
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      
      // Create a temporary file
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/sample_bill_${DateTime.now().millisecondsSinceEpoch}.png');
      
      // Write bytes to temp file
      await tempFile.writeAsBytes(bytes);
      
      // Return as XFile
      return XFile(tempFile.path);
    } catch (e) {
      print('Error creating temp file: $e');
      return null;
    }
  }
}
