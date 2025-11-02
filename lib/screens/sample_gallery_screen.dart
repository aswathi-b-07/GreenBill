import 'dart:convert';
import 'package:flutter/material.dart';

class SampleGalleryScreen extends StatefulWidget {
  const SampleGalleryScreen({Key? key}) : super(key: key);

  @override
  State<SampleGalleryScreen> createState() => _SampleGalleryScreenState();
}

class _SampleGalleryScreenState extends State<SampleGalleryScreen> {
  List<String> _images = [];
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAssetManifest();
  }

  Future<void> _loadAssetManifest() async {
    try {
      final manifestContent = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final images = manifestMap.keys
          .where((String key) => key.startsWith('assets/images/sample_bills/'))
          .toList(growable: false);
      setState(() {
        _images = images;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _images = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Bills'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _images.isEmpty
                ? const Center(child: Text('No sample images found'))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      final asset = _images[index];
                      return GestureDetector(
                        onTap: () => Navigator.pop(context, asset),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.asset(
                                    asset,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  asset.split('/').last,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
