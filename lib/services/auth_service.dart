import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService extends ChangeNotifier {
  final _secure = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  // Keys
  static const _pinKey = 'king_gallery_pin';
  static const _patternKey = 'king_gallery_pattern';

  Future<bool> hasBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final available = await _localAuth.isDeviceSupported();
      if (!available) return false;
      return await _localAuth.authenticate(
        localizedReason: 'Unlock King Gallery',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> setPin(String pin) async {
    await _secure.write(key: _pinKey, value: pin);
    notifyListeners();
  }

  Future<String?> getPin() async {
    return await _secure.read(key: _pinKey);
  }

  Future<void> setPattern(String pattern) async {
    await _secure.write(key: _patternKey, value: pattern);
    notifyListeners();
  }

  Future<String?> getPattern() async {
    return await _secure.read(key: _patternKey);
  }
}
