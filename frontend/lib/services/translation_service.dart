import 'package:translator/translator.dart';

class TranslationService {
  final translator = GoogleTranslator();
  final Map<String, String> _cache = {};

  Future<String> translate(String text, String targetLanguage) async {
    try {
      if (targetLanguage == 'en') return text;
      
      // Check cache first
      final cacheKey = '$text:$targetLanguage';
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!;
      }
      
      final translation = await translator.translate(
        text,
        to: targetLanguage,
      );
      
      // Cache the result
      _cache[cacheKey] = translation.text;
      return translation.text;
    } catch (e) {
      print('Translation error for text "$text" to $targetLanguage: $e');
      return text;
    }
  }

  bool _isEnglish(String text) {
    // Simple check if text contains only ASCII characters
    return text.codeUnits.every((char) => char < 128);
  }

  void clearCache() {
    _cache.clear();
  }
}