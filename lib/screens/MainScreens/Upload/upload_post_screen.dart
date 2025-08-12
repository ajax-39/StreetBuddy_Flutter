import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/provider/MainScreen/upload_provider.dart';
import 'package:street_buddy/utils/styles.dart';

class UploadPostScreen extends StatefulWidget {
  const UploadPostScreen({super.key});

  @override
  State<UploadPostScreen> createState() => _UploadPostScreenState();
}

class _UploadPostScreenState extends State<UploadPostScreen> {
  int _currentImageIndex = 0;
  final minAspect = 4 / 5;

  Future<void> _showMediaOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Media',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildOptionCard(
                    icon: Icons.photo,
                    title: 'Photo',
                    subtitle: 'From gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildOptionCard(
                    icon: Icons.videocam,
                    title: 'Video',
                    subtitle: 'From gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideo();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildOptionCard(
                    icon: Icons.camera_alt,
                    title: 'Camera',
                    subtitle: 'Take photo',
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildOptionCard(
                    icon: Icons.video_camera_back,
                    title: 'Record',
                    subtitle: 'Record video',
                    onTap: () {
                      Navigator.pop(context);
                      _recordVideo();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
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
        padding: const EdgeInsets.all(15),
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
              size: 30,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final media = Media(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          widget: Image.file(imageFile, fit: BoxFit.cover),
          file: imageFile,
        );

        Provider.of<UploadProvider>(context, listen: false)
            .setSelectedMedias([media]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        final File videoFile = File(video.path);
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final media = Media(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          widget: Image.file(imageFile, fit: BoxFit.cover),
          file: imageFile,
        );

        Provider.of<UploadProvider>(context, listen: false)
            .setSelectedMedias([media]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  Future<void> _recordVideo() async {
    try {
      final XFile? video = await ImagePicker().pickVideo(
        source: ImageSource.camera,
      );

      if (video != null) {
        final File videoFile = File(video.path);
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording video: $e')),
      );
    }
  }

  InputDecoration _getInputDecoration(String hint) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.black.withOpacity(0.3),
        fontSize: 14,
        fontWeight: fontregular,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xffE5E5E5)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xffE5E5E5)),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  labelWidget(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 20),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: fontmedium,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with back button and next button
          Container(
            height: 90,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                  width: 0.3,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30, left: 15),
                  child: GestureDetector(
                    onTap: () {
                      context.pop();
                    },
                    child: const Icon(
                      Icons.close,
                      size: 30,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Text(
                    "Create post",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 50), // Placeholder to maintain spacing
              ],
            ),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Media preview section
                    Container(
                      width: double.infinity,
                      height: 400,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Consumer<UploadProvider>(
                        builder: (context, uploadProvider, child) {
                          if (uploadProvider.selectedMedias.isNotEmpty) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  CarouselSlider(
                                    options: CarouselOptions(
                                      height: 400,
                                      initialPage: 0,
                                      enableInfiniteScroll: false,
                                      onPageChanged: (index, reason) {
                                        setState(() {
                                          _currentImageIndex = index;
                                        });
                                      },
                                    ),
                                    items: uploadProvider.selectedMedias
                                        .map((media) {
                                      return Builder(
                                        builder: (BuildContext context) {
                                          return Container(
                                            width: double.infinity,
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 5.0),
                                            child: media.widget,
                                          );
                                        },
                                      );
                                    }).toList(),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    right: 10,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: uploadProvider.selectedMedias
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        int index = entry.key;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _currentImageIndex = index;
                                            });
                                          },
                                          child: Container(
                                            width: 8.0,
                                            height: 8.0,
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 4.0),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _currentImageIndex == index
                                                  ? AppColors.primary
                                                  : Colors.grey[400],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 50,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No media selected',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _showMediaOptions,
                                    icon: const Icon(Icons.add_photo_alternate),
                                    label: const Text('Add Photo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Add media button when media is already selected
                    Consumer<UploadProvider>(
                      builder: (context, uploadProvider, child) {
                        if (uploadProvider.selectedMedias.isNotEmpty) {
                          return Center(
                            child: TextButton.icon(
                              onPressed: _showMediaOptions,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Change Media'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    const SizedBox(height: 20),

                    // Styled form fields (always visible)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Consumer<UploadProvider>(
                        builder: (context, uploadProvider, child) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            labelWidget('Title'),
                            SizedBox(
                              height: 44,
                              child: TextField(
                                decoration: _getInputDecoration(
                                    'Give your post a catchy title...'),
                                onChanged: uploadProvider.setTitle,
                              ),
                            ),
                            labelWidget('Description'),
                            SizedBox(
                              height: 122,
                              child: TextField(
                                decoration: _getInputDecoration(
                                        'Describe what makes this post special...')
                                    .copyWith(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 20,
                                )),
                                maxLines: 5,
                                onChanged: uploadProvider.setDescription,
                              ),
                            ),
                            labelWidget('Location (Optional)'),
                            TextField(
                              decoration: _getInputDecoration('Add location'),
                              onChanged: uploadProvider.setLocation,
                            ),
                            labelWidget('Tags'),
                            SizedBox(
                              height: 44,
                              child: TextField(
                                controller: uploadProvider.tagsController,
                                decoration: _getInputDecoration('Add tags'),
                                onChanged: uploadProvider.onTextChanged,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...uploadProvider.tags.map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(),
                                    child: MarkChip(
                                      label: e,
                                      onTap: () {
                                        uploadProvider.removeTag(e);
                                      },
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Consumer<UploadProvider>(
                      builder: (context, uploadProvider, child) => Column(
                        children: [
                          SwitchListTile(
                            value: uploadProvider.isPublic,
                            onChanged: (value) =>
                                uploadProvider.setPublic(value),
                            title: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                const Text(
                                  'Public',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: fontmedium,
                                    color: Colors.black,
                                  ),
                                ),
                                Icon(
                                  Icons.visibility_off_outlined,
                                  size: 20,
                                  color:
                                      const Color(0xff0F0F0F).withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: SizedBox(
                              height: 44,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: uploadProvider.isValid &&
                                        !uploadProvider.isUploading &&
                                        uploadProvider
                                            .selectedMedias.isNotEmpty &&
                                        globalUser != null
                                    ? () async {
                                        try {
                                          await uploadProvider.createPost(
                                            user: globalUser!,
                                          );
                                          context.go('/home');
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Post uploaded successfully!')),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text('Upload failed: $e')),
                                          );
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: uploadProvider.isValid &&
                                          uploadProvider
                                              .selectedMedias.isNotEmpty &&
                                          globalUser != null
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Post',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: fontmedium,
                                    color: uploadProvider.isValid &&
                                            uploadProvider
                                                .selectedMedias.isNotEmpty &&
                                            globalUser != null
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const AspectRatio(aspectRatio: 3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MarkChip extends StatelessWidget {
  final String label;
  final void Function()? onTap;
  const MarkChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xffEEF2FF),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        children: [
          GestureDetector(
            onTap: onTap,
            child: const Icon(
              Icons.close,
              color: Color(0xff2563EB),
              size: 17,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xff2563EB),
              fontSize: 14,
              fontWeight: fontregular,
            ),
          )
        ],
      ),
    );
  }
}
