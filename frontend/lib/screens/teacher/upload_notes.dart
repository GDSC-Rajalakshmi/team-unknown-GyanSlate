import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_header.dart';
import '../../widgets/translated_text.dart';
import '../../providers/language_provider.dart';
import '../../services/translation_loader_service.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:translator/translator.dart';

class UploadNotes extends StatefulWidget {
  const UploadNotes({super.key});

  @override
  State<UploadNotes> createState() => _UploadNotesState();
}

class _UploadNotesState extends State<UploadNotes> {
  final _formKey = GlobalKey<FormState>();
  final _translationService = TranslationLoaderService();
  late LanguageProvider _languageProvider;
  String? _selectedClass;
  String? _selectedSubject;
  String? _selectedChapter;
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  // Dynamic data structures
  Map<String, Map<String, Map<String, List<String>>>> _availableContent = {};
  List<String> _availableClasses = [];
  List<String> _availableSubjects = [];
  List<String> _availableChapters = [];

  late GoogleTranslator translator;
  
  @override
  void initState() {
    super.initState();
    translator = GoogleTranslator();
    _languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    _fetchAvailableContent();
  }

  // Update the translation helper method
  Future<String> _getTranslatedText(BuildContext context, String text) async {
    try {
      final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      
      // If current language is English, return original text
      if (currentLang == 'en') return text;
      
      // Translate the text to the target language
      final translation = await translator.translate(
        text,
        to: currentLang,
      );
      
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      return text; // Return original text if translation fails
    }
  }

  Future<void> _fetchAvailableContent() async {
    setState(() => _isLoading = true);
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      
      final dio = Dio();
      final response = await dio.get(
        'http://192.168.255.209:5000/teacher/mcq_availability',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        // Process and store the data
        setState(() {
          _availableContent = Map<String, Map<String, Map<String, List<String>>>>.from(
            response.data.map((key, value) => MapEntry(
              key.toString(),
              Map<String, Map<String, List<String>>>.from(
                value.map((subKey, subValue) => MapEntry(
                  subKey.toString(),
                  Map<String, List<String>>.from(
                    subValue.map((chapKey, chapValue) => MapEntry(
                      chapKey.toString(),
                      List<String>.from(chapValue),
                    )),
                  ),
                )),
              ),
            )),
          );
          _availableClasses = _availableContent.keys.toList();
        });

        // Pre-translate all available content
        await _preTranslateContent();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslation('uploadNotes.fetchError')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Add method to pre-translate content
  Future<void> _preTranslateContent() async {
    final currentLang = _languageProvider.currentLanguage;
    if (currentLang == 'en') return;

    try {
      // Pre-translate classes
      for (var className in _availableClasses) {
        await _getTranslatedText(context, className);
      }

      // Pre-translate subjects and chapters
      for (var className in _availableClasses) {
        final subjects = _availableContent[className]?.keys.toList() ?? [];
        for (var subject in subjects) {
          await _getTranslatedText(context, subject);
          
          final chapters = _availableContent[className]?[subject]?.keys.toList() ?? [];
          for (var chapter in chapters) {
            await _getTranslatedText(context, chapter);
          }
        }
      }
    } catch (e) {
      print('Pre-translation error: $e');
    }
  }

  void _updateSubjects() {
    if (_selectedClass != null) {
      setState(() {
        _availableSubjects = _availableContent[_selectedClass]?.keys.toList() ?? [];
        _selectedSubject = null;
        _selectedChapter = null;
        _availableChapters = [];
      });
    }
  }

  void _updateChapters() {
    if (_selectedClass != null && _selectedSubject != null) {
      setState(() {
        _availableChapters = _availableContent[_selectedClass]?[_selectedSubject]?.keys.toList() ?? [];
        _selectedChapter = null;
      });
    }
  }

  Future<void> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _uploadNotes() async {
    if (_formKey.currentState!.validate() && _selectedFile != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get the stored token
        final storage = const FlutterSecureStorage();
        final token = await storage.read(key: 'token');

        // Create form data
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            _selectedFile!.path!,
            filename: _selectedFile!.name,
          ),
          'data': jsonEncode({
            'class': _selectedClass,
            'subj': _selectedSubject,
            'chap': _selectedChapter,
            
          }),
        });

        // // Add logging before sending
        // print('Sending form data:');
        // print('Class: $_selectedClass');
        // print('Subject: $_selectedSubject');
        // print('Chapter: $_selectedChapter');
        // print('File name: ${_selectedFile?.name}');

        // Make the HTTP request with authorization header
        final dio = Dio();
        final response = await dio.post(
          'http://192.168.255.209:5000/teacher/numericprob',
          data: formData,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );

        // Log the response
        print('Response status: ${response.statusCode}');
        print('Response data: ${response.data}');

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _getTranslation('uploadNotes.uploadSuccess'),
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF4A90E2),
            ),
          );
        } else {
          throw Exception('Upload failed');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getTranslation('uploadNotes.uploadError'),
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getTranslation(String key) {
    return _translationService.getTranslation(
      key,
      _languageProvider.currentLanguage ?? 'en',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Color(0xFFE8F3F9),
        elevation: 0,
        title: Text(
          _getTranslation('uploadNotes.title'),
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF2C3E50)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Info Card
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8F3F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.3)),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF4A90E2)),
                          SizedBox(width: 8),
                          Text(
                            _getTranslation('uploadNotes.infoTitle'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      FutureBuilder<List<String>>(
                        future: Future.wait([
                          _getTranslatedText(context, 'Upload your'),
                          _getTranslatedText(context, 'numeric problem-solving notes'),
                          _getTranslatedText(context, 'to help our AI system provide detailed,'),
                          _getTranslatedText(context, 'step-by-step solutions'),
                          _getTranslatedText(context, 'using your classroom methods.'),
                        ]),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          return RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF2C3E50),
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(text: '${snapshot.data![0]} '),
                                TextSpan(
                                  text: '${snapshot.data![1]} ',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                TextSpan(text: '${snapshot.data![2]} '),
                                TextSpan(
                                  text: '${snapshot.data![3]} ',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                TextSpan(text: snapshot.data![4]),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Existing Form Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDynamicDropdowns(),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _pickPDF,
                          icon: const Icon(Icons.upload_file, color: Colors.white),
                          label: Text(
                            _selectedFile?.name ?? _getTranslation('uploadNotes.selectPdfFile'),
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4A90E2),
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 1,
                          ),
                        ),
                        if (_selectedFile != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _getTranslation('uploadNotes.selectedFile')
                                    .replaceAll('{filename}', _selectedFile!.name),
                            style: TextStyle(
                              color: Color(0xFF4A90E2),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _uploadNotes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4A90E2),
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 1,
                          ),
                          child: Text(
                            _getTranslation('uploadNotes.uploadButton'),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF4A90E2),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _getTranslation('uploadNotes.processing'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDynamicDropdowns() {
    return Column(
      children: [
        _buildDropdown(
          'uploadNotes.class',
          _selectedClass,
          _availableClasses,
          (value) {
            setState(() => _selectedClass = value);
            _updateSubjects();
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          'uploadNotes.subject',
          _selectedSubject,
          _availableSubjects,
          (value) {
            setState(() => _selectedSubject = value);
            _updateChapters();
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          'uploadNotes.chapter',
          _selectedChapter,
          _availableChapters,
          (value) => setState(() => _selectedChapter = value),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String labelKey,
    String? value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    final label = _getTranslation(labelKey);
    
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF2C3E50)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4A90E2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4A90E2).withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4A90E2)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: FutureBuilder<String>(
            future: _getTranslatedText(context, item),
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? item,
                style: TextStyle(color: Color(0xFF2C3E50)),
              );
            },
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null 
          ? _getTranslation('uploadNotes.pleaseSelect').replaceAll('{field}', label) 
          : null,
      dropdownColor: Colors.white,
      style: TextStyle(color: Color(0xFF2C3E50)),
    );
  }
}

Widget _buildInfoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Color(0xFF4A90E2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF2C3E50),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

