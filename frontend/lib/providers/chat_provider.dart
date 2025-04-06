import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import '../models/message.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<List<int>>? fileBytes;
  final List<String>? fileNames;
  final List<String>? fileTypes;
  final String? audioData;
  final bool isLoading;
  final bool? isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.fileBytes,
    this.fileNames,
    this.fileTypes,
    this.audioData,
    this.isLoading = false,
    this.isError,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'fileTypes': fileTypes,
    'fileNames': fileNames,
    'fileBytes': fileBytes?.map((bytes) => base64Encode(bytes)).toList(),
    'audioData': audioData,
    'isError': isError,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
    fileTypes: json['fileTypes']?.cast<String>(),
    fileNames: json['fileNames']?.cast<String>(),
    fileBytes: (json['fileBytes'] as List?)?.map((bytes) => base64Decode(bytes)).toList(),
    audioData: json['audioData'],
    isError: json['isError'],
  );

  // Add a debug method
  void debugPrint() {
    print('ChatMessage: text=$text, isUser=$isUser, isLoading=$isLoading');
    print('Has fileBytes: ${fileBytes != null}');
    if (fileBytes != null) {
      print('fileBytes length: ${fileBytes!.length}');
      if (fileBytes!.isNotEmpty) {
        print('First file size: ${fileBytes!.first.length} bytes');
      }
    }
  }
}

class ChatProvider extends ChangeNotifier {
  List<ChatMessage> messages = [];
  bool _isLoading = false;
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ChatProvider(this._prefs) {
    _loadChatHistory();
  }

  bool get isLoading => _isLoading;

  Future<void> sendMessage(
    String message, {
    List<PlatformFile>? files,
    String? audioData,
    required String apiEndpoint,
    required Map<String, dynamic> apiData,
    required String? token,
  }) async {
    try {
      if (message.isEmpty && files == null && audioData == null) return;

      // Add the message to the chat immediately
      final userMessage = ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
        fileBytes: files?.map((file) => file.bytes!).toList(),
        fileNames: files?.map((file) => file.name).toList(),
        fileTypes: files?.map((file) => file.extension ?? '').toList(),
        audioData: audioData,
      );

      messages.add(userMessage);
      notifyListeners();

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.255.209:5000$apiEndpoint'),
      );

      // Add authorization header if token is provided
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add the data as a field
      request.fields['data'] = jsonEncode(apiData);

      // Add files if any
      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          if (file.bytes != null) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'image',
                file.bytes!,
                filename: file.name,
              ),
            );
          } else if (file.path != null) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'image',
                file.path!,
                filename: file.name,
              ),
            );
          }
        }
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Add AI response to chat
        final aiMessage = ChatMessage(
          text: response.body,
          isUser: false,
          timestamp: DateTime.now(),
        );

        messages.add(aiMessage);
        notifyListeners();
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in sendMessage: $e');
      rethrow;
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final history = messages.map((msg) {
        final map = {
          'text': msg.text,
          'isUser': msg.isUser,
          'timestamp': msg.timestamp.toIso8601String(),
          'fileTypes': msg.fileTypes,
          'fileNames': msg.fileNames,
          'audioData': msg.audioData,
        };
        // Only save file bytes for web platform
        if (kIsWeb && msg.fileBytes != null) {
          map['fileBytes'] = msg.fileBytes!.map((bytes) => base64Encode(bytes)).toList();
        }
        return jsonEncode(map);
      }).toList();
      
      await _prefs.setStringList('chat_history', history);
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = _prefs.getStringList('chat_history') ?? [];
      messages.addAll(
        history.map((msg) {
          final map = jsonDecode(msg);
          final fileBytes = (map['fileBytes'] as List?)?.map((bytes) => base64Decode(bytes)).toList();
          return ChatMessage(
            text: map['text'],
            isUser: map['isUser'],
            timestamp: DateTime.parse(map['timestamp']),
            fileTypes: map['fileTypes']?.cast<String>(),
            fileNames: map['fileNames']?.cast<String>(),
            fileBytes: fileBytes,
            audioData: map['audioData'],
          );
        }),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  Future<void> clearChat() async {
    messages.clear();
    await _prefs.remove('chat_history');
    notifyListeners();
  }
} 