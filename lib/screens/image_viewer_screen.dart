import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewerScreen extends StatelessWidget {
  final File file;
  const ImageViewerScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [IconButton(icon: const Icon(Icons.delete), onPressed: () => Navigator.pop(context))]),
      body: Center(
        child: PhotoView(imageProvider: FileImage(file)),
      ),
    );
  }
}
