import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: $error');
        },
      );
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    String languageCode = 'en-US',
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_isInitialized) {
        await _speech.listen(
          onResult: (result) {
            onResult(result.recognizedWords);
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          listenMode: stt.ListenMode.confirmation,
          localeId: languageCode,
        );
      }
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      rethrow;
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
      rethrow;
    }
  }

  static const Map<String, String> languageCodes = {
    'en': 'en-US',
    'ta': 'ta-IN',
    'hi': 'hi-IN',
    'te': 'te-IN',
    'ml': 'ml-IN',
    'kn': 'kn-IN',
  };

  Future<String> transcribeAudio(List<int> audioData, String languageCode) async {
    try {
      final uri = Uri.parse('https://dharsan-rural-edu-101392092221.asia-south1.run.app/transcribe');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'audio_data': base64Encode(audioData),
          'language_code': languageCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['transcript'] as String;
      } else {
        throw Exception('Failed to transcribe audio: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in speech service: $e');
      throw Exception('Failed to transcribe audio: $e');
    }
  }
} 