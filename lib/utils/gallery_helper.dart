import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';

class GalleryHelper {
  static Future<void> copyAssetsToGallery() async {
    try {
      final directory = await getTemporaryDirectory();
      
      // List all images from assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = Map.from(json.decode(manifestContent));
      
      final imageAssets = manifestMap.keys
          .where((String key) => key.startsWith('assets/images/') && 
                (key.endsWith('.jpg') || key.endsWith('.jpeg') || key.endsWith('.png')))
          .toList();

      for (String assetPath in imageAssets) {
        final ByteData data = await rootBundle.load(assetPath);
        final fileName = assetPath.split('/').last;
        final file = File('${directory.path}/$fileName');
        
        await file.writeAsBytes(data.buffer.asUint8List());
        await GallerySaver.saveImage(file.path);
      }
    } catch (e) {
      print('Error copying assets to gallery: $e');
    }
  }
}