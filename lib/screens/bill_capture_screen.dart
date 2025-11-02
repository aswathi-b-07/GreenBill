import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import 'scan_screen.dart';

class BillCaptureScreen extends StatelessWidget {
  const BillCaptureScreen({Key? key}) : super(key: key);

  Future<void> _captureAndProcessBill(BuildContext context, String billType) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 100,
      );
      
      if (photo == null) return;
      
      if (!context.mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanScreen(
            imageFile: photo,
            billType: billType,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Bill'),
        backgroundColor: AppConstants.primaryGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Bill Type',
              style: AppConstants.headingStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildBillTypeButton(
              context,
              'Petrol Bill',
              Icons.local_gas_station,
              AppConstants.fuelColor,
              'petrol',
            ),
            const SizedBox(height: 16),
            _buildBillTypeButton(
              context,
              'Grocery Bill',
              Icons.shopping_basket,
              AppConstants.foodColor,
              'grocery',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillTypeButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    String billType,
  ) {
    return ElevatedButton(
      onPressed: () => _captureAndProcessBill(context, billType),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}