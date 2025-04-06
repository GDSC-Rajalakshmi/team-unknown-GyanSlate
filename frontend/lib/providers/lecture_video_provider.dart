import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/lecture_video.dart';
import '../services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class LectureVideoProvider with ChangeNotifier {
  final DatabaseService _dbService;
  List<LectureVideo> _videos = [];
  bool _isLoading = false;
  String? _error;

  LectureVideoProvider(this._dbService) {
    loadVideos();
  }

  List<LectureVideo> get videos => _videos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadVideos() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get values from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userClass = prefs.getString('class') ?? '10';
      final userState = prefs.getString('state') ?? 'Tamil Nadu';
      
 // Get the stored token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final response = await http.post(
        Uri.parse('http://192.168.255.209:5000/student/list_video'),
        headers: {'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',},
        body: json.encode({
          "class": userClass,
          "state": userState
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _videos = data.map((item) => LectureVideo.fromJson(item)).toList();
      } else {
        _error = 'Failed to load videos: ${response.statusCode}';
        print(_error);
      }
    } catch (e) {
      _error = 'Error loading videos: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initializeData() async {
    // Make sure the database is initialized
    try {
      // This is a placeholder - you need to implement the actual initialization
      // based on your DatabaseService implementation
      await _dbService.initialize();
    } catch (e) {
      debugPrint('Error initializing database: $e');
    }
  }

  Future<void> uploadVideo({
    required String title,
    required String className,
    required String subject,
    required String chapter,
    required String state,
    required String videoPath,
    required String duration,
    String subtopic = '',
  }) async {
    try {
      final video = LectureVideo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        className: className,
        subject: subject,
        chapter: chapter,
        state: state,
        duration: duration,
        videoUrl: videoPath,
        status: 'Pending',
        subtopic: subtopic,
        uploadDate: DateTime.now(),
      );

      try {
        await _dbService.addLectureVideo(video.toJson());
      } catch (e) {
        debugPrint('Database error: $e');
        _videos.add(video);
        notifyListeners();
        return;
      }
      
      _videos.add(video);
      notifyListeners();
    } catch (e) {
      debugPrint('Error uploading video: $e');
      rethrow;
    }
  }

  Future<void> updateLectureVideo(LectureVideo video) async {
    try {
      await _dbService.updateLectureVideo(video.id.toString(), video.toJson());
      
      final index = _videos.indexWhere((v) => v.id == video.id);
      if (index >= 0) {
        _videos[index] = video;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating lecture video: $e');
      rethrow;
    }
  }

  Future<void> deleteVideo(String id) async {
    try {
      await _dbService.deleteLectureVideo(id);
      _videos.removeWhere((video) => video.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting video: $e');
      rethrow;
    }
  }

  List<LectureVideo> getVideosByFilters({
    String? subject,
    String? chapter,
  }) {
    return _videos.where((video) {
      // Apply subject filter
      if (subject != null && video.subject != subject) {
        return false;
      }
      
      // Apply chapter filter
      if (chapter != null && video.chapter != chapter) {
        return false;
      }
      
      return true;
    }).toList();
  }

  List<String> getUniqueValues(String field) {
    final Set<String> uniqueValues = {};
    
    for (var video in _videos) {
      String value = '';
      switch (field) {
        case 'subject':
          value = video.subject;
          break;
        case 'chapter':
          value = video.chapter;
          break;
      }
      
      if (value.isNotEmpty) {
        uniqueValues.add(value);
      }
    }
    
    return uniqueValues.toList()..sort();
  }

  Future<void> fetchVideos({
    String? className,
    String? subject,
    String? chapter,
    String? state,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = {
        if (className != null) 'class': className,
        if (subject != null) 'subject': subject,
        if (chapter != null) 'chapter': chapter,
        if (state != null) 'state': state,
      };

      // Get the stored token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final uri = Uri.parse('http://192.168.255.209:5000/admin/video_list')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _videos = data.map((json) => LectureVideo(
          id: json['id'].toString(),
          title: json['title'] ?? '${json['subject']} - ${json['chapter']} - ${json['subtopic']}',
          className: json['class'].toString(),
          subject: json['subject'] ?? '',
          chapter: json['chapter'] ?? '',
          state: json['state'] ?? '',
          duration: json['duration'] ?? 'N/A',
          videoUrl: json['videoUrl'] ?? '',
          status: json['status'] ?? 'Unknown',
          subtopic: json['subtopic'] ?? '',
          uploadDate: json['uploadDate'] != null 
              ? DateTime.parse(json['uploadDate']) 
              : null,
        )).toList();
      } else {
        _error = 'Failed to fetch videos';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}