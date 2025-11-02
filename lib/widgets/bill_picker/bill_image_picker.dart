import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'bill_image_source_dialog.dart';

class BillImagePicker {
  static Future<XFile?> pickImage(BuildContext context) async {
    // Show source selection dialog
    final source = await showDialog<BillImageSource>(
      context: context,
      builder: (context) => const BillImageSourceDialog(),
    );

    if (source == null) return null;

    switch (source) {
      case BillImageSource.gallery:
        final ImagePicker picker = ImagePicker();
        return await picker.pickImage(source: ImageSource.gallery);

      case BillImageSource.sample:
        return await _getSampleBill();

      default:
        return null;
    }
  }

  static Future<XFile?> _getSampleBill() async {
    try {
      // Get list of sample bills from assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = Map<String, dynamic>.from(
        manifestContent.isNotEmpty 
          ? json.decode(manifestContent) as Map 
          : {}
      );
      
      final sampleBills = manifestMap.keys
          .where((String key) => key.contains('assets/images/sample_bills/'))
          .toList();

      if (sampleBills.isEmpty) {
        print('No sample bills found in assets');
        return null;
      }

      // For now, just use the first sample bill
      final samplePath = sampleBills.first;
      
      // Load the image data
      final ByteData data = await rootBundle.load(samplePath);
      final Uint8List bytes = data.buffer.asUint8List();

      // Get temporary directory to store the file
      final tempDir = await getTemporaryDirectory();
      final String fileName = path.basename(samplePath);
      final File tempFile = File('${tempDir.path}/$fileName');
      
      // Write the file
      await tempFile.writeAsBytes(bytes);
      
      return XFile(tempFile.path);
    } catch (e) {
      print('Error loading sample bill: $e');
      return null;
    }
  }
}