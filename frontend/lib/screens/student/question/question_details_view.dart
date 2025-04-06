import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'explanation_player_screen.dart';
import 'dart:convert';
import '../../../widgets/translated_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';

class QuestionDetailsView extends StatefulWidget {
  final String? selectedImagePath;
  final AssetEntity? selectedAsset;
  final Map<String, dynamic> selectedQuestionDetails;
  final bool isLoadingQuestionDetails;

  const QuestionDetailsView({
    Key? key,
    required this.selectedImagePath,
    required this.selectedAsset,
    required this.selectedQuestionDetails,
    required this.isLoadingQuestionDetails,
  }) : super(key: key);

  @override
  _QuestionDetailsViewState createState() => _QuestionDetailsViewState();
}

class _QuestionDetailsViewState extends State<QuestionDetailsView> {
  int _currentImageIndex = 0;
  List<Map<String, dynamic>> _allImages = [];
  FlutterTts flutterTts = FlutterTts();
  bool isSolutionSpeaking = false;
  bool isTopicSpeaking = false;
  final translator = GoogleTranslator();

  @override
  void initState() {
    super.initState();
    _processImages();
    _initTts();
  }

  @override
  void didUpdateWidget(QuestionDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedQuestionDetails != widget.selectedQuestionDetails) {
      _processImages();
    }
  }

  void _processImages() {
    _allImages = [];
    
    try {
      // First process images from the 'images' field if it exists
      if (widget.selectedQuestionDetails.containsKey('images') && 
          widget.selectedQuestionDetails['images'] is List) {
        
        List<dynamic> imagesData = widget.selectedQuestionDetails['images'];
        
        for (var imageItem in imagesData) {
          if (imageItem is Map<String, dynamic>) {
            imageItem.forEach((subtopic, imageData) {
              _allImages.add({
                'subtopic': subtopic,
                'image': imageData,
              });
            });
          }
        }
      }
      
      // Now also process images from the 'subtopic' field
      if (widget.selectedQuestionDetails.containsKey('subtopic') && 
          widget.selectedQuestionDetails['subtopic'] is Map<String, dynamic>) {
        
        Map<String, dynamic> subtopics = widget.selectedQuestionDetails['subtopic'];
        
        subtopics.forEach((topicName, topicData) {
          if (topicData is Map<String, dynamic> && topicData.containsKey('img')) {
            _allImages.add({
              'subtopic': topicName,
              'image': topicData['img'],
            });
          }
        });
      }
    } catch (e) {
      print('Error processing images: $e');
    }
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage(
      Provider.of<LanguageProvider>(context, listen: false).currentLanguage
    );
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);

    flutterTts.setCompletionHandler(() {
      setState(() {
        isSolutionSpeaking = false;
        isTopicSpeaking = false;
      });
    });
  }

  Future<void> _speakSolution(String text, bool isSolution) async {
    if (isSolution && isSolutionSpeaking || !isSolution && isTopicSpeaking) {
      await flutterTts.stop();
      setState(() {
        if (isSolution) {
          isSolutionSpeaking = false;
        } else {
          isTopicSpeaking = false;
        }
      });
      return;
    }

    // Stop other section if it's speaking
    if (isSolution && isTopicSpeaking || !isSolution && isSolutionSpeaking) {
      await flutterTts.stop();
      setState(() {
        isSolutionSpeaking = false;
        isTopicSpeaking = false;
      });
    }

    String currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    
    try {
      if (currentLang != 'en') {
        final translation = await translator.translate(
          text,
          to: currentLang,
        );
        text = translation.text;
      }

      await flutterTts.setLanguage(currentLang);
      await flutterTts.setPitch(1.0);
      // Set different speech rates for solution and topic
      await flutterTts.setSpeechRate(isSolution ? 0.5 : 0.4);  // Slower rate for topic
      
      setState(() {
        if (isSolution) {
          isSolutionSpeaking = true;
        } else {
          isTopicSpeaking = true;
        }
      });
      
      await flutterTts.speak(text);
    } catch (e) {
      print('TTS Error: $e');
      setState(() {
        if (isSolution) {
          isSolutionSpeaking = false;
        } else {
          isTopicSpeaking = false;
        }
      });
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.isLoadingQuestionDetails
                ? Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Question
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.question_answer, 
                                  size: 20, 
                                  color: Colors.blue
                                ),
                                SizedBox(width: 8),
                                TranslatedText(
                                  'general.doubt.question_details.sections.question.title',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              widget.selectedQuestionDetails['question'] != null
                                  ? widget.selectedQuestionDetails['question']['text'] ?? 
                                    'general.doubt.question_details.sections.question.no_text'
                                  : 'general.doubt.question_details.sections.question.no_text',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                      SizedBox(height: 24),

                      // Section 2: Images
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.image, 
                                  size: 20, 
                                  color: Colors.blue
                                ),
                                SizedBox(width: 8),
                                TranslatedText(
                                  'general.doubt.question_details.sections.images.title',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            _allImages.isNotEmpty
                                ? _buildImageSlider()
                                : _buildSelectedImageWidget(),
                          ],
                        ),
                      ),

                      Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                      SizedBox(height: 24),

                      // Section 3: Topic
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.topic, 
                                  size: 20, 
                                  color: Colors.blue
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: TranslatedText(
                                    'general.doubt.question_details.sections.topic.title',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF4A90E2).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Color(0xFF4A90E2).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          isTopicSpeaking ? 'Stop' : 'Listen',
                                          style: TextStyle(
                                            color: Color(0xFF4A90E2),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isTopicSpeaking ? Icons.stop_circle : Icons.play_circle_fill,
                                          color: Color(0xFF4A90E2),
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          String textToSpeak = '';
                                          if (widget.selectedQuestionDetails.containsKey('subtopic') && 
                                              widget.selectedQuestionDetails['subtopic'] != null) {
                                            
                                            Map<String, dynamic> subtopics = widget.selectedQuestionDetails['subtopic'];
                                            subtopics.forEach((topicName, topicData) {
                                              if (topicData is Map && topicData.containsKey('explanation')) {
                                                textToSpeak += '$topicName: ${topicData['explanation']}\n\n';
                                              }
                                            });
                                          }
                                          textToSpeak = textToSpeak.isEmpty ? 'No topic explanation available' : textToSpeak;
                                          _speakSolution(textToSpeak, false);
                                        },
                                        style: IconButton.styleFrom(
                                          padding: EdgeInsets.all(4),
                                          minimumSize: Size(32, 32),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            // Display subtopic explanations from API
                            if (widget.selectedQuestionDetails.containsKey('subtopic') && 
                                widget.selectedQuestionDetails['subtopic'] != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (String topicName in (widget.selectedQuestionDetails['subtopic'] as Map).keys)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            topicName.trim(),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            widget.selectedQuestionDetails['subtopic'][topicName]['explanation'] ?? 'No explanation available',
                                            style: TextStyle(fontSize: 15),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              )
                            else
                              Text(
                                'No topic explanation available',
                                style: TextStyle(fontSize: 15),
                              ),
                          ],
                        ),
                      ),

                      Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                      SizedBox(height: 24),

                      // Section 4: Solution
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline, 
                                  size: 20, 
                                  color: Colors.green
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: TranslatedText(
                                    'general.doubt.question_details.sections.solution.title',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF4A90E2).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Color(0xFF4A90E2).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          isSolutionSpeaking ? 'Stop' : 'Listen',
                                          style: TextStyle(
                                            color: Color(0xFF4A90E2),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isSolutionSpeaking ? Icons.stop_circle : Icons.play_circle_fill,
                                          color: Color(0xFF4A90E2),
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          String textToSpeak = widget.selectedQuestionDetails['solution'] ?? 
                                              'No solution available';
                                          _speakSolution(textToSpeak, true);
                                        },
                                        style: IconButton.styleFrom(
                                          padding: EdgeInsets.all(4),
                                          minimumSize: Size(32, 32),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              widget.selectedQuestionDetails['solution'] ?? 
                              'general.doubt.question_details.sections.solution.no_solution',
                              style: TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),

                      Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                      SizedBox(height: 24),

                      // Section 5: Step-by-step explanation
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.format_list_numbered, 
                                  size: 20, 
                                  color: Colors.orange
                                ),
                                SizedBox(width: 8),
                                TranslatedText(
                                  'general.doubt.question_details.sections.step_by_step.title',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              widget.selectedQuestionDetails['solution_explanation'] ?? 'general.doubt.question_details.sections.step_by_step.no_explanation',
                              style: TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Explain and Play button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExplanationPlayerScreen(
                                  question: widget.selectedQuestionDetails['question'] ?? 
                                    {'text': 'general.doubt.question_details.sections.question.no_text'},
                                  details: widget.selectedQuestionDetails,
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.play_circle_outline),
                          label: TranslatedText('general.doubt.question_details.explain_play.button'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            textStyle: TextStyle(fontSize: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlider() {
    if (_allImages.isEmpty) {
      return Center(child: TranslatedText('general.doubt.question_details.sections.images.no_images'));
    }

    // Prepare the image widgets
    List<Widget> imageWidgets = _allImages.map((imageData) {
      return GestureDetector(
        onTap: () => _showFullScreenImage(imageData),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _buildImageFromData(imageData['image']),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Text(
                  imageData['subtopic'],
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();

    return Column(
      children: [
        ImageSlideshow(
          width: double.infinity,
          height: 300,
          initialPage: 0,
          indicatorColor: Colors.blue,
          indicatorBackgroundColor: Colors.grey,
          onPageChanged: (value) {
            setState(() {
              _currentImageIndex = value;
            });
          },
          autoPlayInterval: 0, // No auto-play
          isLoop: false,
          children: imageWidgets,
        ),
        SizedBox(height: 10),
        // Image counter
        Text(
          "${_currentImageIndex + 1}/${_allImages.length}",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Add this method to show full screen image popup
  void _showFullScreenImage(Map<String, dynamic> imageData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(10),
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                // Image with pinch to zoom
                InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4,
                  child: Center(
                    child: _buildImageFromData(imageData['image']),
                  ),
                ),
                // Close button
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                // Subtitle at the bottom
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    color: Colors.black.withOpacity(0.5),
                    child: Text(
                      imageData['subtopic'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageFromData(dynamic imageData) {
    if (imageData is String && imageData.startsWith('data:image')) {
      return _buildBase64Image(imageData);
    } else if (imageData is String && (imageData.startsWith('http://') || imageData.startsWith('https://'))) {
      return Image.network(
        imageData,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TranslatedText(
                'general.doubt.question_details.errors.failed_load',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        },
      );
    } else if (imageData is Map && imageData['type'] == 'Buffer' && imageData['data'] is List) {
      return _buildBufferImage(imageData['data']);
    } else if (imageData is Uint8List) {
      return Image.memory(
        imageData,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading Uint8List image: $error');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TranslatedText(
                'general.doubt.question_details.errors.failed_load',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        },
      );
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TranslatedText(
            'general.doubt.question_details.errors.unsupported_format',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  Widget _buildSelectedImageWidget() {
    if (widget.selectedImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(widget.selectedImagePath!),
          fit: BoxFit.contain,
        ),
      );
    } else if (widget.selectedAsset != null) {
      return FutureBuilder<Uint8List?>(
        future: widget.selectedAsset!.originBytes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: TranslatedText(
                'general.doubt.question_details.errors.failed_load',
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              snapshot.data!,
              fit: BoxFit.contain,
            ),
          );
        },
      );
    } else {
      return Center(
        child: Icon(
          Icons.image_not_supported,
          size: 50,
          color: Colors.grey,
        ),
      );
    }
  }

  Widget _buildBase64Image(String base64String) {
    // Remove data:image/jpeg;base64, prefix if present
    if (base64String.contains(',')) {
      base64String = base64String.split(',')[1];
    }
    
    try {
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading base64 image: $error');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TranslatedText(
                'general.doubt.question_details.errors.failed_load',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('Exception decoding base64 image: $e');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TranslatedText(
            'general.doubt.question_details.errors.invalid_data',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  Widget _buildBufferImage(List<dynamic> bufferData) {
    try {
      // Convert the list of integers to Uint8List
      final Uint8List bytes = Uint8List.fromList(
        bufferData.map<int>((item) => item as int).toList()
      );
      
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading buffer image: $error');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TranslatedText(
                'general.doubt.question_details.errors.failed_load',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('Exception decoding buffer image: $e');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TranslatedText(
            'general.doubt.question_details.errors.invalid_data',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }
} 