import 'package:flutter/material.dart';

enum BillImageSource {
  gallery,
  sample
}

class BillImageSourceDialog extends StatelessWidget {
  const BillImageSourceDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Select Image Source'),
      children: [
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context, BillImageSource.gallery);
          },
          child: const ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Choose from Gallery'),
          ),
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context, BillImageSource.sample);
          },
          child: const ListTile(
            leading: Icon(Icons.receipt),
            title: Text('Use Sample Bill'),
          ),
        ),
      ],
    );
  }
}