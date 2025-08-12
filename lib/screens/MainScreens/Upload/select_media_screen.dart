import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/MainScreen/upload_provider.dart';
import 'package:street_buddy/utils/styles.dart';

class SelectMediaScreen extends StatefulWidget {
  final int? guideNumber;
  const SelectMediaScreen({super.key, this.guideNumber});

  @override
  State<SelectMediaScreen> createState() => _SelectMediaScreenState();
}

class _SelectMediaScreenState extends State<SelectMediaScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // Create a Media object and set it in the provider
        final media = Media(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          widget: Image.file(imageFile, fit: BoxFit.cover),
          file: imageFile,
        );

        Provider.of<UploadProvider>(context, listen: false)
            .setSelectedMedias([media]);

        // Navigate to the beautiful post creation screen (skip edit screen)
        if (mounted) {
          context.pushReplacement('/upload/post');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        final File videoFile = File(video.path);

        // Create a Media object and set it in the provider
        final media = Media(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          widget: Container(
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.play_arrow, color: Colors.white, size: 50),
            ),
          ),
          file: videoFile,
        );

        Provider.of<UploadProvider>(context, listen: false)
            .setSelectedMedias([media]);

        // Navigate to the beautiful post creation screen (skip edit screen)
        if (mounted) {
          context.pushReplacement('/upload/post');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // Create a Media object and set it in the provider
        final media = Media(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          widget: Image.file(imageFile, fit: BoxFit.cover),
          file: imageFile,
        );

        Provider.of<UploadProvider>(context, listen: false)
            .setSelectedMedias([media]);

        // Navigate to the beautiful post creation screen (skip edit screen)
        if (mounted) {
          context.pushReplacement('/upload/post');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  Future<void> _recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
      );

      if (video != null) {
        final File videoFile = File(video.path);

        // Create a Media object and set it in the provider
        final media = Media(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          widget: Container(
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.play_arrow, color: Colors.white, size: 50),
            ),
          ),
          file: videoFile,
        );

        Provider.of<UploadProvider>(context, listen: false)
            .setSelectedMedias([media]);

        // Navigate to the beautiful post creation screen (skip edit screen)
        if (mounted) {
          context.pushReplacement('/upload/post');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording video: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Media',
          style: TextStyle(
            fontSize: 18,
            fontWeight: fontregular,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(CupertinoIcons.xmark),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Media Source',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Gallery Options
              const Text(
                'From Gallery',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildOptionCard(
                      icon: Icons.photo,
                      title: 'Photo',
                      subtitle: 'Select from gallery',
                      onTap: _pickImage,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildOptionCard(
                      icon: Icons.videocam,
                      title: 'Video',
                      subtitle: 'Select from gallery',
                      onTap: _pickVideo,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Camera Options
              const Text(
                'Take New',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildOptionCard(
                      icon: Icons.camera_alt,
                      title: 'Take Photo',
                      subtitle: 'Use camera',
                      onTap: _takePhoto,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildOptionCard(
                      icon: Icons.video_camera_back,
                      title: 'Record Video',
                      subtitle: 'Use camera',
                      onTap: _recordVideo,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
