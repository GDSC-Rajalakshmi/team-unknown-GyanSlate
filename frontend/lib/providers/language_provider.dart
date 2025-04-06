import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_loader_service.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en';
  final TranslationLoaderService _translationService = TranslationLoaderService();
  bool _isInitialized = false;
  
  static const Map<String, String> _languageNames = {
    'en': 'English',
    'ta': 'Tamil',
    'hi': 'Hindi',
    'te': 'Telugu',
  };

  static const List<String> _supportedLanguages = ['en', 'ta', 'hi', 'te'];

  static Map<String, String> get languageNames => _languageNames;
  static List<String> get supportedLanguages => _supportedLanguages;

  String get currentLanguage => _currentLanguage;

  bool get isInitialized => _isInitialized;

  LanguageProvider() {
    initialize();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('language') ?? 'en';
      
      // Validate saved language
      if (_supportedLanguages.contains(savedLanguage)) {
        _currentLanguage = savedLanguage;
      } else {
        print('Warning: Unsupported language $savedLanguage found, defaulting to English');
        _currentLanguage = 'en';
      }
      
      await _translationService.loadTranslations();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing language provider: $e');
      _currentLanguage = 'en'; // Fallback to English
    }
  }

  Future<void> changeLanguage(String language) async {
    if (_currentLanguage == language) return;
    
    if (!_supportedLanguages.contains(language)) {
      print('Error: Unsupported language $language');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', language);
      _currentLanguage = language;
      notifyListeners();
    } catch (e) {
      print('Error changing language to $language: $e');
    }
  }

  String? getTranslation(String key) {
    if (!_isInitialized) {
      print('Warning: Language provider not initialized when requesting translation for key: $key');
      return key;
    }
    return _translationService.getTranslation(key, _currentLanguage);
  }

  bool isLanguageSupported(String language) {
    return _supportedLanguages.contains(language);
  }

  void setLanguage(String language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      notifyListeners();
    }
  }
}