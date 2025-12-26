import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService extends ChangeNotifier {
  static const _voiceKey = 'king_gallery_voice_phrase';
  final _secure = const FlutterSecureStorage();
  final stt.SpeechToText _speech = stt.SpeechToText();

  String? _phrase;
  String? get phrase => _phrase;

  Future<void> init() async {
    _phrase = await _secure.read(key: _voiceKey);
    notifyListeners();
  }

  Future<void> setPhrase(String phrase) async {
    await _secure.write(key: _voiceKey, value: phrase);
    _phrase = phrase;
    notifyListeners();
  }

  Future<void> clearPhrase() async {
    await _secure.delete(key: _voiceKey);
    _phrase = null;
    notifyListeners();
  }

  Future<bool> listenAndCompare({required void Function(String) onPartial}) async {
    final available = await _speech.initialize();
    if (!available) return false;
    String last = '';
    _speech.listen(onResult: (res) {
      last = res.recognizedWords;
      onPartial(last);
    });

    // Wait until speech stops or timeout
    await Future.delayed(const Duration(seconds: 4));
    _speech.stop();

    if (_phrase == null) return false;
    // simple prototype: exact (case-insensitive) match after trimming
    return last.trim().toLowerCase() == _phrase!.trim().toLowerCase();
  }
}
