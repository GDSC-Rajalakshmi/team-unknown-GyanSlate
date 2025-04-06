import 'dart:convert';
import 'package:flutter/services.dart';

class TranslationLoaderService {
  static final TranslationLoaderService _instance = TranslationLoaderService._internal();
  factory TranslationLoaderService() => _instance;
  TranslationLoaderService._internal();

  Map<String, dynamic>? _translations;
  bool _isLoading = false;
  bool _hasLoaded = false;

  // Add cache for frequently used translations
  final Map<String, String> _translationCache = {};

  Future<void> loadTranslations() async {
    if (_isLoading) return;
    if (_hasLoaded) {
     // print('Translations already loaded with ${_translations?.length ?? 0} root keys');
      return;
    }

    try {
      _isLoading = true;
      print('Starting to load translations...');

      // Initialize empty translations map
      _translations = {};

      // List of translation files to load
      final translationFiles = [
        'main.json',
        'student_login.json',
        'student_dashboard.json',
        'ai_tutor_chat.json',
        'lecture_video_list.json',
        'teacher_dashboard.json',
        'assessment_management.json',
        'assessment_creation.json',
        'admin_dashboard.json',
        'question_generator.json',
        'lecturemanagement.json',
        'lecture_video_management.json',
        'lecture_history.json',
        'available_assessments.json',
        'authorization_page.json',
        'question_paper_generator.json',
        'question_paper_view.json',
        'generated_papers.json',
        'general_doubt_resolver.json',
        'student_profile.json',
        'upload_notes.json',
        'student_leaderboard.json',
        'performance_analysis.json'
      ];

      // Load and parse each JSON file
      for (final file in translationFiles) {
        try {
          final jsonString = await rootBundle.loadString('assets/translations/$file');
        //  print('Loading translations from $file...');
          
          final translations = json.decode(jsonString);
        //  print('Keys in $file: ${translations.keys.join(', ')}');
          
          // Debug log for question_paper_view.json
          if (file == 'question_paper_view.json') {
          //  print('Loading question_paper_view.json...');
          //  print('Available keys: ${translations.keys.join(', ')}');
            if (translations.containsKey('questionPaper')) {
           //   print('questionPaper keys: ${(translations['questionPaper'] as Map).keys.join(', ')}');
            }
          }
          
          _mergeMap(_translations!, translations);
        } catch (e) {
         // print('Warning: Failed to load $file: $e');
          // Continue with other files even if one fails
        }
      }

      _hasLoaded = true;
      // print('All translations loaded. Available keys: ${_translations!.keys.join(', ')}');
      // print('Translation structure: ${json.encode(_translations)}');
      
      // Debug log for questionPaper specifically
      if (_translations!.containsKey('questionPaper')) {
        // print('questionPaper found in translations: ${json.encode(_translations!['questionPaper'])}');
      } else {
        // print('questionPaper NOT found in translations!');
      }
    } catch (e) {
      print('Error loading translations: $e');
      _translations = {};
    } finally {
      _isLoading = false;
    }
  }

  void _mergeMap(Map<String, dynamic> target, Map<String, dynamic> source) {
    source.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        target[key] = target[key] is Map<String, dynamic> 
            ? target[key] as Map<String, dynamic>
            : <String, dynamic>{};
        _mergeMap(target[key] as Map<String, dynamic>, value);
      } else {
        target[key] = value;
      }
      if (key == 'examplePercentage') {
        // print('Debug: Merged examplePercentage translation: ${json.encode(value)}');
      }
    });
  }

  String getTranslation(String key, String languageCode) {
    if (!_hasLoaded) {
      // print('Warning: Translations not loaded when requesting key: $key');
      return key;
    }

    // Add debug logging
    // print('Getting translation for key: $key, language: $languageCode');
    // print('Available translations: ${_translations?.keys.join(', ')}');
    if (key == 'examplePercentage') {
      // print('Debug: Looking for examplePercentage translation');
      // print('Debug: Translations map: ${json.encode(_translations)}');
    }

    // Check cache first
    final cacheKey = '$key:$languageCode';
    if (_translationCache.containsKey(cacheKey)) {
      // print('Found in cache: $cacheKey');
      return _translationCache[cacheKey]!;
    }

    try {
      final keys = key.split('.');
      dynamic current = _translations;
      
      // Debug log the navigation through the translation tree
      for (final k in keys) {
        // print('Navigating through key: $k');
        if (current is! Map) {
          // print('Warning: Translation path broken at $k for key: $key');
          return key;
        }
        current = current[k];
        if (current == null) {
          // print('Warning: No translation found at $k for key: $key');
          return key;
        }
      }

      if (current is Map) {
        final translation = current[languageCode] ?? current['en'] ?? key;
        // print('Found translation: $translation');
        _translationCache[cacheKey] = translation.toString();
        return translation.toString();
      }
      
      // print('Found direct value: $current');
      _translationCache[cacheKey] = current.toString();
      return current.toString();
    } catch (e) {
      // print('Error getting translation for key $key: $e');
      return key;
    }
  }

  String debugPrintTranslations() {
    if (!_hasLoaded) {
      return 'Translations not loaded yet';
    }
    try {
      return json.encode(_translations);
    } catch (e) {
      return 'Error printing translations: $e';
    }
  }
}