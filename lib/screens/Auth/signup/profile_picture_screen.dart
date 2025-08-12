import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:street_buddy/provider/Auth/sign_up_provider.dart';
import 'package:street_buddy/utils/styles.dart';

class ProfilePictureScreen extends StatelessWidget {
  const ProfilePictureScreen({super.key});

  void _showImagePickerBottomSheet(
      BuildContext context, SignUpProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add picture',
                    style: AppTypography.headline,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                await provider.requestPermissions(context);
                if (context.mounted) {
                  provider.handleImageSelection(context, ImageSource.gallery);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () async {
                await provider.requestPermissions(context);
                if (context.mounted) {
                  provider.handleImageSelection(context, ImageSource.camera);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SignUpProvider>(
      builder: (context, provider, child) {
        final String? profilePictureUrl = provider.profilePictureUrl;

        return Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => context.pop(),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                const Text(
                  'Add a profile picture',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add a profile picture so your friends know it\'s you. Everyone will be able to see your picture.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),

                // Profile picture section
                Center(
                  child: GestureDetector(
                    onTap: () => _showImagePickerBottomSheet(context, provider),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[100],
                        border: Border.all(
                          color: const Color(0xFFED7014),
                          width: 3,
                        ),
                      ),
                      child: profilePictureUrl != null
                          ? ClipOval(
                              child: Image.file(
                                File(profilePictureUrl),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Add picture/Confirm button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () {
                            if (profilePictureUrl == null) {
                              // Show image picker if no image selected
                              _showImagePickerBottomSheet(context, provider);
                            } else {
                              // Confirm and complete registration if image is selected
                              provider.completeUserRegistration(
                                  context, profilePictureUrl);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFED7014),
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            profilePictureUrl == null
                                ? 'Add picture'
                                : 'Confirm',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                // Bottom action buttons
                if (profilePictureUrl == null)
                  // Skip button when no picture is selected
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Center(
                      child: TextButton(
                        onPressed: provider.isLoading
                            ? null
                            : () => provider.completeUserRegistration(
                                context, null),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFED7014),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  // Change picture button when picture is selected
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: TextButton(
                        onPressed: provider.isLoading
                            ? null
                            : () =>
                                _showImagePickerBottomSheet(context, provider),
                        child: const Text(
                          'Change picture',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFED7014),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildO(BuildContext context) {
    return Consumer<SignUpProvider>(
      builder: (context, provider, child) {
        final String? profilePictureUrl = provider.profilePictureUrl;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (context.canPop())
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => context.pop(),
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Add a profile picture',
                          style: AppTypography.headline,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Add a profile picture so your friends know it\'s you. Everyone will be able to see your picture.',
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Center(
                          child: GestureDetector(
                            onTap: () =>
                                _showImagePickerBottomSheet(context, provider),
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[300],
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              child: profilePictureUrl != null
                                  ? ClipOval(
                                      child: Image.file(
                                        File(profilePictureUrl),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: provider.isLoading
                              ? null
                              : () => _showImagePickerBottomSheet(
                                  context, provider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Add picture',
                            style: AppTypography.button.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Center(
                          child: TextButton(
                            onPressed: provider.isLoading
                                ? null
                                : () => provider.completeUserRegistration(
                                    context, null),
                            child: const Text(
                              'Skip',
                              style: AppTypography.link,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (provider.isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
