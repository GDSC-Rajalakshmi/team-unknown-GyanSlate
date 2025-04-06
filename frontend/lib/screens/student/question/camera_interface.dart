import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../widgets/translated_text.dart';
import 'question_box_painter.dart';
import 'package:translator/translator.dart';
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';

class CameraInterface extends StatefulWidget {
  final bool isCameraInitialized;
  final CameraController? cameraController;
  final bool isGalleryExpanded;
  final bool showingImagePreview;
  final String? selectedImagePath;
  final AssetEntity? selectedAsset;
  final List<String> capturedImages;
  final List<AssetEntity> galleryAssets;
  final bool isAnalyzingImage;
  final List<Map<String, dynamic>> detectedQuestions;
  final double dragStartY;
  final double dragDistance;
  final double dragThreshold;
  
  final Function() onClose;
  final Function() captureImage;
  final Function(String?, AssetEntity?) onSelectGalleryImage;
  final Function(Map<String, dynamic>) onSelectQuestion;
  final Function(double) onDragStart;
  final Function(double) onDragUpdate;
  final Function(double) onDragEnd;

  const CameraInterface({
    Key? key,
    required this.isCameraInitialized,
    required this.cameraController,
    required this.isGalleryExpanded,
    required this.showingImagePreview,
    required this.selectedImagePath,
    required this.selectedAsset,
    required this.capturedImages,
    required this.galleryAssets,
    required this.isAnalyzingImage,
    required this.detectedQuestions,
    required this.dragStartY,
    required this.dragDistance,
    required this.dragThreshold,
    required this.onClose,
    required this.captureImage,
    required this.onSelectGalleryImage,
    required this.onSelectQuestion,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  }) : super(key: key);

  @override
  State<CameraInterface> createState() => _CameraInterfaceState();
}

class _CameraInterfaceState extends State<CameraInterface> {
  late GoogleTranslator translator;

  @override
  void initState() {
    super.initState();
    translator = GoogleTranslator();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            // Camera preview area
            Expanded(
              flex: widget.isGalleryExpanded ? 1 : 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Camera preview or image preview
                  Container(
                    color: Colors.black,
                    child: _buildCameraOrImagePreview(),
                  ),
                  
                  // Close button
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: widget.onClose,
                      ),
                    ),
                  ),
                  
                  // Camera capture button
                  if (!widget.showingImagePreview && !widget.isGalleryExpanded)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: widget.isCameraInitialized ? widget.captureImage : null,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Center(
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Analyzing overlay
                  if (widget.isAnalyzingImage)
                    Container(
                      color: Colors.black.withOpacity(0.7),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                  ),
                                  const SizedBox(height: 20),
                                  TranslatedText(
                                    'general.doubt.camera.analyzing.title',
                                    style: TextStyle(
                                      color: Colors.white, 
                                      fontSize: 18, 
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TranslatedText(
                                    'general.doubt.camera.analyzing.subtitle',
                                    style: TextStyle(
                                      color: Colors.white70, 
                                      fontSize: 14
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Detected questions overlay
                  _buildDetectedQuestionsOverlay(context),
                ],
              ),
            ),
            
            // Gallery section with drag functionality
            GestureDetector(
              onVerticalDragStart: (details) => widget.onDragStart(details.globalPosition.dy),
              onVerticalDragUpdate: (details) => widget.onDragUpdate(details.globalPosition.dy),
              onVerticalDragEnd: (details) => widget.onDragEnd(details.primaryVelocity ?? 0),
              child: Container(
                color: Colors.black,
                height: widget.isGalleryExpanded ? 300 : 150,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    
                    // Gallery content
                    Expanded(
                      child: _buildGallerySection(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraOrImagePreview() {
    if (widget.showingImagePreview) {
      if (widget.selectedImagePath != null) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Image.file(
                  File(widget.selectedImagePath!),
                  fit: BoxFit.contain,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                ),
                if (widget.detectedQuestions.isNotEmpty)
                  QuestionBoxPainterGestureDetector(
                    questions: widget.detectedQuestions,
                    imageSize: Size(constraints.maxWidth, constraints.maxHeight),
                    onQuestionTap: widget.onSelectQuestion,
                    child: CustomPaint(
                      painter: QuestionBoxPainter(
                        questions: widget.detectedQuestions,
                        imageSize: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                  ),
              ],
            );
          },
        );
      } else if (widget.selectedAsset != null) {
        return FutureBuilder<Uint8List?>(
          future: widget.selectedAsset!.originBytes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: TranslatedText(
                  'general.doubt.camera.errors.failed_load',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
            
            return LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Image.memory(
                      snapshot.data!,
                      fit: BoxFit.contain,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    ),
                    if (widget.detectedQuestions.isNotEmpty)
                      QuestionBoxPainterGestureDetector(
                        questions: widget.detectedQuestions,
                        imageSize: Size(constraints.maxWidth, constraints.maxHeight),
                        onQuestionTap: widget.onSelectQuestion,
                        child: CustomPaint(
                          painter: QuestionBoxPainter(
                            questions: widget.detectedQuestions,
                            imageSize: Size(constraints.maxWidth, constraints.maxHeight),
                          ),
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      } else {
        return Container(color: Colors.black);
      }
    } else if (widget.isCameraInitialized && widget.cameraController != null) {
      return AspectRatio(
        aspectRatio: 1 / widget.cameraController!.value.aspectRatio,
        child: CameraPreview(widget.cameraController!),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  Widget _buildGallerySection() {
    return SingleChildScrollView(
      physics: widget.isGalleryExpanded 
          ? const AlwaysScrollableScrollPhysics() 
          : const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.capturedImages.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.photo_camera, size: 16, color: Colors.white70),
                  const SizedBox(width: 8),
                  TranslatedText(
                    'general.doubt.camera.gallery.recently_captured',
                    style: TextStyle(
                      color: Colors.white70, 
                      fontSize: 14, 
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.capturedImages.length,
                itemBuilder: (context, index) {
                  final imagePath = widget.capturedImages[index];
                  final isSelected = imagePath == widget.selectedImagePath;
                  
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          widget.onSelectGalleryImage(null, null);
                        } else {
                          widget.onSelectGalleryImage(imagePath, null);
                        }
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                          image: DecorationImage(
                            image: FileImage(File(imagePath)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 8.0),
            child: Row(
              children: [
                const Icon(Icons.photo_library, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                TranslatedText(
                  'general.doubt.camera.gallery.from_gallery',
                  style: TextStyle(
                    color: Colors.white70, 
                    fontSize: 14, 
                    fontWeight: FontWeight.w500
                  ),
                ),
              ],
            ),
          ),
          widget.galleryAssets.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.photo_library_outlined, color: Colors.white30, size: 40),
                        const SizedBox(height: 8),
                        TranslatedText(
                          'general.doubt.camera.gallery.no_images',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  height: widget.isGalleryExpanded ? 200 : 80,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: widget.isGalleryExpanded ? 3 : 1,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      mainAxisExtent: 80,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: widget.isGalleryExpanded ? Axis.vertical : Axis.horizontal,
                    itemCount: widget.galleryAssets.length,
                    itemBuilder: (context, index) {
                      final asset = widget.galleryAssets[index];
                      final isSelected = widget.selectedAsset?.id == asset.id;
                      
                      return GestureDetector(
                        onTap: () {
                          if (isSelected) {
                            widget.onSelectGalleryImage(null, null);
                          } else {
                            widget.onSelectGalleryImage(null, asset);
                          }
                        },
                        child: FutureBuilder<Uint8List?>(
                          future: asset.thumbnailDataWithSize(
                            const ThumbnailSize(200, 200),
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                                  ),
                                ),
                              );
                            }
                            
                            if (!snapshot.hasData || snapshot.data == null) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(Icons.image_not_supported, color: Colors.white70),
                                ),
                              );
                            }
                            
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: Colors.blue, width: 2)
                                    : null,
                                image: DecorationImage(
                                  image: MemoryImage(snapshot.data!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDetectedQuestionsOverlay(BuildContext context) {
    if (!widget.detectedQuestions.isNotEmpty || widget.isAnalyzingImage) return SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TranslatedText(
                'general.doubt.camera.detected_questions.title',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: widget.detectedQuestions.length,
                itemBuilder: (context, index) {
                  final question = widget.detectedQuestions[index];
                  
                  return FutureBuilder<String>(
                    future: _getTranslatedQuestionText(context, question['text'] ?? ''),
                    builder: (context, snapshot) {
                      final displayText = snapshot.data ?? question['text'] ?? 
                        'general.doubt.camera.detected.no_text';
                      
                      return GestureDetector(
                        onTap: () => widget.onSelectQuestion(question),
                        child: Container(
                          width: 200,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  TranslatedText(
                                    'general.doubt.camera.detected_questions.question_label',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    ' ${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: snapshot.connectionState == ConnectionState.waiting
                                    ? Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        displayText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getTranslatedQuestionText(BuildContext context, String text) async {
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
} 