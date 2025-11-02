import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ImageHelper {
  static Future<List<String>> getLocalBillImages() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final billImagesDir = Directory('${appDir.path}/bill_images');
      
      // Create directory if it doesn't exist
      if (!await billImagesDir.exists()) {
        await billImagesDir.create(recursive: true);
        
        // Copy assets to local storage
        final manifestContent = await rootBundle.loadString('AssetManifest.json');
        final manifestMap = json.decode(manifestContent) as Map<String, dynamic>;
        
        final imageAssets = manifestMap.keys
            .where((String key) => key.startsWith('assets/images/') && 
                  (key.endsWith('.jpg') || key.endsWith('.jpeg') || key.endsWith('.png')))
            .toList();

        for (String assetPath in imageAssets) {
          final ByteData data = await rootBundle.load(assetPath);
          final fileName = assetPath.split('/').last;
          final file = File('${billImagesDir.path}/$fileName');
          
          await file.writeAsBytes(data.buffer.asUint8List());
        }
      }
      
      // Return list of local image paths
      final files = await billImagesDir.list().toList();
      return files
          .whereType<File>()
          .map((file) => file.path)
          .toList();
    } catch (e) {
      print('Error setting up local images: $e');
      return [];
    }
  }
}