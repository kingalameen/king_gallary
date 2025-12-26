import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'image_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _importAndHide() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) return;

    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final original = File(picked.path);
    // Create hidden item metadata
    final id = const Uuid().v4();
    final item = HiddenItem(
      id: id,
      name: original.path.split('/').last,
      path: '',
      thumbnailPath: '',
    );

    await Provider.of<StorageService>(context, listen: false).addHiddenItem(item, original);

    // delete original
    try {
      await original.delete();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final items = storage.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('King Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: () => Navigator.pushNamed(context, '/drive'),
          ),
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () => Navigator.pushNamed(context, '/lock-setup'),
          )
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: _importAndHide,
              child: Container(
                color: Colors.grey[800],
                child: const Center(child: Icon(Icons.add, size: 40)),
              ),
            );
          }
          final item = items[index - 1];
          final thumb = File(item.thumbnailPath);
          return GestureDetector(
            onTap: () async {
              final dec = await storage.retrieveItemFile(item);
              if (dec != null) Navigator.push(context, MaterialPageRoute(builder: (_) => ImageViewerScreen(file: dec)));
            },
            child: Container(
              color: Colors.grey[900],
              child: thumb.existsSync()
                  ? Image.file(thumb, fit: BoxFit.cover)
                  : Center(child: Text(item.name, textAlign: TextAlign.center)),
            ),
          );
        },
      ),
    );
  }
}
