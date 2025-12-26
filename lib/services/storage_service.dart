import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'drive_service.dart';

class HiddenItem {
  final String id;
  final String name;
  final String path; // encrypted file path in app storage
  final String thumbnailPath;

  HiddenItem({
    required this.id,
    required this.name,
    required this.path,
    required this.thumbnailPath,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'path': path,
        'thumbnailPath': thumbnailPath,
      };

  HiddenItem.fromMap(Map map)
      : id = map['id'],
        name = map['name'],
        path = map['path'],
        thumbnailPath = map['thumbnailPath'];
}

class StorageService extends ChangeNotifier {
  static const _boxName = 'hidden_items';
  static late Box _box;
  static late Directory _appDir;
  static const _aesKeyStorageKey = 'king_gallery_aes_key';
  static final _secure = const FlutterSecureStorage();

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    _appDir = await getApplicationDocumentsDirectory();
    // ensure thumbnail dir exists
    final thumbDir = Directory('${_appDir.path}/thumbnails');
    if (!thumbDir.existsSync()) thumbDir.createSync(recursive: true);
    // ensure AES key exists
    var key = await _secure.read(key: _aesKeyStorageKey);
    if (key == null) {
      final rnd = Random.secure();
      final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
      final b64 = base64Encode(bytes);
      await _secure.write(key: _aesKeyStorageKey, value: b64);
    }
  }

  List<HiddenItem> get items {
    return _box.values
        .map((e) => HiddenItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addHiddenItem(HiddenItem item, File original) async {
    // create thumbnail (simple copy for prototype)
    final thumbDir = Directory('${_appDir.path}/thumbnails');
    if (!thumbDir.existsSync()) thumbDir.createSync(recursive: true);
    final thumbPath = '${thumbDir.path}/${item.id}.jpg';
    try {
      await original.copy(thumbPath);
    } catch (_) {
      // ignore thumbnail failures
    }

    // encrypt file and store in app dir
    final encryptedPath = await _encryptAndStore(original, item.id);
    final newItem = HiddenItem(
      id: item.id,
      name: item.name,
      path: encryptedPath,
      thumbnailPath: thumbPath,
    );
    await _box.put(item.id, newItem.toMap());
    notifyListeners();
  }

  Future<String> _encryptAndStore(File file, String id) async {
    final keyB64 = await _secure.read(key: _aesKeyStorageKey);
    final key = keyB64 != null
        ? encrypt.Key(base64Decode(keyB64))
        : encrypt.Key.fromLength(32);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final bytes = await file.readAsBytes();
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);
    final out = File('${_appDir.path}/$id.enc');
    await out.writeAsBytes(encrypted.bytes, flush: true);
    return out.path;
  }

  Future<File?> retrieveItemFile(HiddenItem item) async {
    final file = File(item.path);
    if (!file.existsSync()) return null;
    final keyB64 = await _secure.read(key: _aesKeyStorageKey);
    final key = keyB64 != null
        ? encrypt.Key(base64Decode(keyB64))
        : encrypt.Key.fromLength(32);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = await file.readAsBytes();
    final decrypted = encrypter.decryptBytes(encrypt.Encrypted(encrypted), iv: iv);
    final out = File('${_appDir.path}/${item.id}.dec');
    await out.writeAsBytes(decrypted, flush: true);
    return out;
  }

  Future<String?> uploadToDrive(BuildContext context, HiddenItem item) async {
    try {
      final file = File(item.path);
      if (!file.existsSync()) return null;
      final driveService = Provider.of<DriveService>(context, listen: false);
      if (!driveService.isSignedIn) return null;
      return await driveService.uploadFile(file, '${item.id}.enc');
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteHiddenItem(HiddenItem item) async {
    // remove from box and delete files
    await _box.delete(item.id);
    try {
      final f1 = File(item.path);
      if (f1.existsSync()) f1.deleteSync();
    } catch (_) {}
    try {
      final f2 = File(item.thumbnailPath);
      if (f2.existsSync()) f2.deleteSync();
    } catch (_) {}
    notifyListeners();
  }
}
