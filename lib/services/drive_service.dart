import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Lightweight authenticated http client that injects Google OAuth headers.
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

class DriveService extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  GoogleSignInAccount? get account => _currentUser;

  bool get isSignedIn => _currentUser != null;

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) return false;
      final auth = await _currentUser!.authentication;
      final headers = {'Authorization': 'Bearer ${auth.accessToken}'};
      final client = _GoogleAuthClient(headers);
      _driveApi = drive.DriveApi(client);
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('Drive signIn error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    _currentUser = null;
    _driveApi = null;
    notifyListeners();
  }

  Future<String?> uploadFile(File file, String remoteName) async {
    if (_driveApi == null) return null;
    try {
      final media = drive.Media(file.openRead(), await file.length());
      final fileMeta = drive.File();
      fileMeta.name = remoteName;
      // upload into the user's Drive root
      final result = await _driveApi!.files.create(
        fileMeta,
        uploadMedia: media,
      );
      return result.id;
    } catch (e) {
      if (kDebugMode) print('Upload error: $e');
      return null;
    }
  }

  Future<List<drive.File>> listFiles({int pageSize = 50}) async {
    if (_driveApi == null) return [];
    try {
      final list = await _driveApi!.files.list(pageSize: pageSize);
      return list.files ?? [];
    } catch (e) {
      if (kDebugMode) print('List files error: $e');
      return [];
    }
  }

  Future<bool> downloadFile(String fileId, File target) async {
    if (_driveApi == null) return false;
    try {
      final media = await _driveApi!.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final stream = media.stream;
      final out = target.openWrite();
      await stream.pipe(out);
      await out.flush();
      await out.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('Download error: $e');
      return false;
    }
  }
}
