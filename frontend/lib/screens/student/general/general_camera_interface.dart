import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:photo_manager/photo_manager.dart';
import 'general_box_painter.dart';

class CameraInterface extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            // Camera preview area
            Expanded(
              flex: isGalleryExpanded ? 1 : 3,
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
                        onPressed: onClose,
                      ),
                    ),
                  ),
                  
                  // Camera capture button
                  if (!showingImagePreview && !isGalleryExpanded)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: isCameraInitialized ? captureImage : null,
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
                  
                  // Analyzing overlay - hide this since we're not analyzing images
                  if (isAnalyzingImage)
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
                                children: const [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'Processing image...',
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Add a "Use this image" button when showing image preview
                  if (showingImagePreview && (selectedImagePath != null || selectedAsset != null))
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Use the selected image
                            if (selectedImagePath != null) {
                              onSelectGalleryImage(selectedImagePath, null);
                            } else if (selectedAsset != null) {
                              onSelectGalleryImage(null, selectedAsset);
                            }
                            onClose(); // Close the camera interface
                          },
                          icon: Icon(Icons.check),
                          label: Text('Use this image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Gallery section with drag functionality
            GestureDetector(
              onVerticalDragStart: (details) => onDragStart(details.globalPosition.dy),
              onVerticalDragUpdate: (details) => onDragUpdate(details.globalPosition.dy),
              onVerticalDragEnd: (details) => onDragEnd(details.primaryVelocity ?? 0),
              child: Container(
                color: Colors.black,
                height: isGalleryExpanded ? 300 : 150,
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
    if (showingImagePreview) {
      if (selectedImagePath != null) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(selectedImagePath!),
              fit: BoxFit.contain,
            ),
            // Remove the CustomPaint for question boxes
          ],
        );
      } else if (selectedAsset != null) {
        return FutureBuilder<Uint8List?>(
          future: selectedAsset!.originBytes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                child: Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  snapshot.data!,
                  fit: BoxFit.contain,
                ),
                // Remove the CustomPaint for question boxes
              ],
            );
          },
        );
      } else {
        return Container(color: Colors.black);
      }
    } else if (isCameraInitialized && cameraController != null) {
      return AspectRatio(
        aspectRatio: 1 / cameraController!.value.aspectRatio,
        child: CameraPreview(cameraController!),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  Widget _buildGallerySection() {
    return SingleChildScrollView(
      physics: isGalleryExpanded 
          ? const AlwaysScrollableScrollPhysics() 
          : const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (capturedImages.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
              child: Row(
                children: const [
                  Icon(Icons.photo_camera, size: 16, color: Colors.white70),
                  SizedBox(width: 8),
                  Text(
                    'Recently Captured',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: capturedImages.length,
                itemBuilder: (context, index) {
                  final imagePath = capturedImages[index];
                  final isSelected = imagePath == selectedImagePath;
                  
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          onSelectGalleryImage(null, null);
                        } else {
                          onSelectGalleryImage(imagePath, null);
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
              children: const [
                Icon(Icons.photo_library, size: 16, color: Colors.white70),
                SizedBox(width: 8),
                Text(
                  'From Gallery',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          galleryAssets.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: const [
                        Icon(Icons.photo_library_outlined, color: Colors.white30, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'No images found',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  height: isGalleryExpanded ? 200 : 80,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isGalleryExpanded ? 3 : 1,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      mainAxisExtent: 80,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: isGalleryExpanded ? Axis.vertical : Axis.horizontal,
                    itemCount: galleryAssets.length,
                    itemBuilder: (context, index) {
                      final asset = galleryAssets[index];
                      final isSelected = selectedAsset?.id == asset.id;
                      
                      return GestureDetector(
                        onTap: () {
                          if (isSelected) {
                            onSelectGalleryImage(null, null);
                          } else {
                            onSelectGalleryImage(null, asset);
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
}