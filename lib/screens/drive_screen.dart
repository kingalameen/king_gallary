import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/drive_service.dart';
import '../services/storage_service.dart';

class DriveScreen extends StatefulWidget {
  const DriveScreen({super.key});

  @override
  State<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends State<DriveScreen> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    final ok = await Provider.of<DriveService>(context, listen: false).signIn();
    setState(() => _loading = false);
    if (!ok) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google sign-in failed')));
  }

  Future<void> _uploadAll() async {
    setState(() => _loading = true);
    final storage = Provider.of<StorageService>(context, listen: false);
    final drive = Provider.of<DriveService>(context, listen: false);
    for (final item in storage.items) {
      final file = File(item.path);
      if (await file.exists()) {
        await drive.uploadFile(file, item.name);
      }
    }
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload finished')));
  }

  @override
  Widget build(BuildContext context) {
    final drive = Provider.of<DriveService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Drive Backup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (drive.account == null)
              ElevatedButton(onPressed: _signIn, child: const Text('Sign in with Google'))
            else
              ListTile(
                title: Text('Signed in as ${drive.account!.email}'),
                trailing: ElevatedButton(onPressed: drive.signOut, child: const Text('Sign out')),
              ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _uploadAll, child: const Text('Upload all hidden items')),
            if (_loading) const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
