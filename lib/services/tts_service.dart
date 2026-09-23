import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  static const Map<String, String> _localeMap = {
    'English': 'en-US',
    'Hindi': 'hi-IN',
    'Marathi': 'mr-IN',
    'Tamil': 'ta-IN',
    'Telugu': 'te-IN',
    'Punjabi': 'pa-IN',
    'Bengali': 'bn-IN',
    'Gujarati': 'gu-IN',
  };

  Future<void> speak(String text, {required String languageName}) async {
    final locale = _localeMap[languageName] ?? 'en-US';

    // Check if this language's voice data is actually available on the device
    final isAvailable = await _tts.isLanguageAvailable(locale);
    // ignore: avoid_print
    print('TTS: $locale available on device = $isAvailable');

    if (isAvailable == true || isAvailable == 1) {
      await _tts.setLanguage(locale);
    } else {
      // Voice pack not installed on this device - falls back to default
      // ignore: avoid_print
      print('TTS: $locale NOT available, falling back to device default voice');
      await _tts.setLanguage('en-US');
    }

    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);

    _isSpeaking = true;
    await _tts.speak(text);
  }

  Future<bool> isLanguageAvailable(String languageName) async {
    final locale = _localeMap[languageName] ?? 'en-US';
    final result = await _tts.isLanguageAvailable(locale);
    return result == true || result == 1;
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }
}