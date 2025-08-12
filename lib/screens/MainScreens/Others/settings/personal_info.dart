import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/provider/Auth/auth_provider.dart';
import 'package:street_buddy/provider/MainScreen/edit_profile_provider.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/utils/responsive_util.dart';

class PersonalInfo extends StatelessWidget {
  const PersonalInfo({super.key});

  TextStyle getTextStyle(BuildContext context) {
    return TextStyle(
      fontFamily: 'SFUI',
      color: Colors.black,
      fontSize: ResponsiveUtil.getFontSize(
        context,
        small: 14,
        medium: 15,
        large: 16,
      ),
      fontWeight: fontregular,
    );
  }

  InputDecoration _getInputDecoration(
      BuildContext context, String label, String helper,
      {String? errorText, bool? showLoading, String? prefixText}) {
    return InputDecoration(
      contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtil.getPadding(context,
              small: 8, medium: 10, large: 12)),
      helperText: helper.isEmpty ? null : helper,
      errorText: errorText,
      helperStyle: AppTypography.caption,
      hintText: label,
      hintStyle: TextStyle(
        color: const Color(0xff1E1E1E).withOpacity(0.15),
        fontSize: ResponsiveUtil.getFontSize(context,
            small: 12, medium: 12.5, large: 13),
        fontWeight: fontregular,
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xffE5E7EB)),
      ),
      focusedBorder: const UnderlineInputBorder(),
      prefixText: prefixText,
      prefixStyle: getTextStyle(context),
      suffixIcon: showLoading == true
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : null,
    );
  }

  Future<void> _showImageSourceSheet(
      BuildContext context, EditProfileProvider provider,
      {bool isCover = false}) async {
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceBackground,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.md)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Choose ${isCover ? 'Cover' : 'Profile'} Picture',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Take Photo', style: AppTypography.body),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (isCover) {
                    provider.pickImage(ImageSource.camera, context,
                        isCover: true);
                  } else {
                    provider.pickImage(ImageSource.camera, context);
                  }
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Choose from Gallery',
                    style: AppTypography.body),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (isCover) {
                    provider.pickImage(ImageSource.gallery, context,
                        isCover: true);
                  } else {
                    provider.pickImage(ImageSource.gallery, context);
                  }
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.close, color: AppColors.textSecondary),
                title: Text(
                  'Cancel',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSave(
      BuildContext context, EditProfileProvider editProvider) async {
    if (editProvider.usernameController.text.isEmpty) {
      editProvider.setUsernameError('Username cannot be empty');
      return;
    }

    if (editProvider.usernameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fix the errors before saving',
              style: AppTypography.body.copyWith(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<ProfileProvider>();
    final authProvider = context.read<AuthenticationProvider>();

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving changes...'),
          duration: Duration(seconds: 1),
        ),
      );

      await provider.updateProfile(
        authProvider.userModel!.uid,
        username: editProvider.usernameController.text,
        name: editProvider.nameController.text,
        gender: editProvider.selectedGender,
        bio: editProvider.bioController.text,
        phoneNumber: editProvider.phoneController.text,
        profileImage: editProvider.selectedImage,
        coverImage: editProvider.selectedCoverImage,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Error updating profile',
              style: AppTypography.body.copyWith(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditProfileProvider(),
      child: Consumer3<EditProfileProvider, ProfileProvider,
          AuthenticationProvider>(
        builder: (context, editProvider, profileProvider, authProvider, _) {
          if (!editProvider.isInitialized) {
            editProvider.initializeUserData(
                profileProvider, authProvider.userModel!.uid);
          }

          final userData = profileProvider.userData;

          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              title: Text('Personal Information',
                  style: TextStyle(
                    fontSize: ResponsiveUtil.getFontSize(
                      context,
                      small: 18,
                      medium: 20,
                      large: 22,
                    ),
                    fontWeight: fontmedium,
                  )),
              centerTitle: true,
            ),
            body: editProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Cover Image Section
                        GestureDetector(
                          onTap: () => _showImageSourceSheet(
                              context, editProvider,
                              isCover: true),
                          child: Stack(
                            children: [
                              Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: editProvider.selectedCoverImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.file(
                                          editProvider.selectedCoverImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : userData?.coverImageUrl != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: Image.network(
                                              userData!.coverImageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Center(
                                                child: Icon(
                                                  Icons.image,
                                                  size: 50,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Icon(
                                              Icons.image,
                                              size: 50,
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                              ),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  padding:
                                      const EdgeInsets.all(AppSpacing.xs + 2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xff2563EB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: AppColors.buttonText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child: TextButton(
                            onPressed: () => _showImageSourceSheet(
                                context, editProvider,
                                isCover: true),
                            child: const Text(
                              'Change Cover Photo',
                              style: TextStyle(
                                color: Color(0xff2563EB),
                                fontSize: 14,
                                fontWeight: fontmedium,
                              ),
                            ),
                          ),
                        ),
                        // Profile Image Section
                        Center(
                          child: GestureDetector(
                            onTap: () =>
                                _showImageSourceSheet(context, editProvider),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.surfaceBackground,
                                      width: 3,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 46,
                                    backgroundColor:
                                        AppColors.surfaceBackground,
                                    backgroundImage: editProvider
                                                .selectedImage !=
                                            null
                                        ? FileImage(editProvider.selectedImage!)
                                            as ImageProvider
                                        : userData?.profileImageUrl != null
                                            ? NetworkImage(
                                                userData!.profileImageUrl!)
                                            : null,
                                    child: editProvider.selectedImage == null &&
                                            userData?.profileImageUrl == null
                                        ? const Icon(Icons.person,
                                            size: 50,
                                            color: AppColors.textSecondary)
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 7,
                                  right: 7,
                                  child: Container(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.xs + 2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xff2563EB),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: AppColors.buttonText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: TextButton(
                            onPressed: () =>
                                _showImageSourceSheet(context, editProvider),
                            child: const Text(
                              'Change Photo',
                              style: TextStyle(
                                color: Color(0xff2563EB),
                                fontSize: 14,
                                fontWeight: fontmedium,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          padding: EdgeInsets.all(ResponsiveUtil.getPadding(
                              context,
                              small: 14,
                              medium: 16,
                              large: 18)),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                ResponsiveUtil.getResponsiveValue(
                              context,
                              small: 14.0,
                              medium: 16.0,
                              large: 18.0,
                            )),
                            border: Border.all(
                              color: const Color(0xffF7F7F7),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              labelWidget('Username', context),
                              TextField(
                                controller: editProvider.usernameController,
                                decoration: _getInputDecoration(
                                  context,
                                  'Username',
                                  '',
                                  prefixText: '@',
                                  errorText: editProvider.usernameError,
                                  showLoading: editProvider.isCheckingUsername,
                                ),
                                style: getTextStyle(context),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              labelWidget('Full Name', context),
                              TextField(
                                controller: editProvider.nameController,
                                decoration: _getInputDecoration(
                                  context,
                                  'Name',
                                  '',
                                ),
                                style: getTextStyle(context),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              labelWidget('Bio', context),
                              TextField(
                                controller: editProvider.bioController,
                                decoration: InputDecoration(
                                  hintText: 'Enter your bio...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: AppColors.border),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.textFill,
                                ),
                                maxLines: 3,
                                style: TextStyle(
                                    fontSize: 14, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              // VIP Toggle
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.amber),
                                      SizedBox(width: 8),
                                      Text(
                                        'VIP Status',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: fontsemibold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: userData?.isVIP == true,
                                    onChanged: (val) async {
                                      final provider =
                                          context.read<ProfileProvider>();
                                      final uid = authProvider.userModel?.uid;
                                      if (uid != null) {
                                        await provider.updateVIPStatus(
                                            val, uid);
                                      }
                                    },
                                    activeColor: Colors.amber,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xffF7F7F7),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contact Information',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: fontsemibold,
                                ),
                              ),
                              // const SizedBox(height: 5),
                              ListTile(
                                contentPadding: const EdgeInsets.all(0),
                                leading: Icon(
                                  Icons.email_outlined,
                                  size: 25,
                                  color:
                                      const Color(0xff0F0F0F).withOpacity(0.6),
                                ),
                                title: const Text('Email'),
                                titleTextStyle: TextStyle(
                                  color: Colors.black.withOpacity(0.6),
                                  fontSize: 14,
                                  fontWeight: fontregular,
                                ),
                                subtitleTextStyle: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: fontregular,
                                ),
                                subtitle: Text(
                                    globalUser?.email ?? 'user@example.com'),
                                trailing: globalUser!.isEmailVerified
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: AppColors.success,
                                      )
                                    : const Icon(
                                        Icons.cancel,
                                        color: AppColors.error,
                                      ),
                              ),
                              ListTile(
                                contentPadding: const EdgeInsets.all(0),
                                leading: Image.asset(
                                  'assets/icon/mobile.png',
                                  width: 25,
                                  color:
                                      const Color(0xff0F0F0F).withOpacity(0.6),
                                ),
                                title: const Text('Phone'),
                                titleTextStyle: TextStyle(
                                  color: Colors.black.withOpacity(0.6),
                                  fontSize: 14,
                                  fontWeight: fontregular,
                                ),
                                subtitleTextStyle: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: fontregular,
                                ),
                                subtitle:
                                    Text(globalUser?.phoneNumber ?? 'None'),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xffF7F7F7),
                            ),
                          ),
                          child: StatefulBuilder(builder: (context, setState) {
                            return FutureBuilder(
                                future: supabase
                                    .from('users')
                                    .select('location_pref')
                                    .eq('uid', globalUser?.uid ?? '')
                                    .single(),
                                builder: (context, snapshot) {
                                  List data =
                                      snapshot.data?['location_pref'] ?? [];
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Location & Preferences',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      TextField(
                                        decoration: _getInputDecoration(
                                            context, 'Add Locations ...', ''),
                                        onSubmitted: (value) async {
                                          List newData = [
                                            ...data,
                                            value.trim(),
                                          ];
                                          await supabase.from('users').update({
                                            'location_pref': newData,
                                          }).eq('uid', globalUser?.uid ?? '');
                                          setState(() {});
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [     
                                          ...data.map(
                                            (e) => Chip(
                                              label: Text(e),
                                              backgroundColor:
                                                  AppColors.cardBackground,
                                              onDeleted: () async {
                                                data.remove(e);
                                                await supabase
                                                    .from('users')
                                                    .update({
                                                  'location_pref': data,
                                                }).eq('uid',
                                                        globalUser?.uid ?? '');
                                                setState(() {});
                                              },
                                            ),
                                          )
                                        ],
                                      )
                                    ],
                                  );
                                });
                          }),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xffF7F7F7),
                            ),
                          ),
                          child: StatefulBuilder(builder: (context, setState) {
                            return FutureBuilder(
                                future: supabase
                                    .from('users')
                                    .select('travel_interest')
                                    .eq('uid', globalUser?.uid ?? '')
                                    .single(),
                                builder: (context, snapshot) {
                                  List data =
                                      snapshot.data?['travel_interest'] ?? [];
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Travel Interests',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: fontsemibold,
                                        ),
                                      ),
                                      TextField(
                                        decoration: _getInputDecoration(
                                            context, 'Add Interests ..', ''),
                                        onSubmitted: (value) async {
                                          List newData = [
                                            ...data,
                                            value.trim(),
                                          ];
                                          await supabase.from('users').update({
                                            'travel_interest': newData,
                                          }).eq('uid', globalUser?.uid ?? '');
                                          setState(() {});
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          ...data.map(
                                            (e) => Padding(
                                              padding: const EdgeInsets.only(),
                                              child: MarkChip(
                                                label: e,
                                                onTap: () async {
                                                  data.remove(e);
                                                  await supabase
                                                      .from('users')
                                                      .update({
                                                    'travel_interest': data,
                                                  }).eq(
                                                          'uid',
                                                          globalUser?.uid ??
                                                              '');
                                                  setState(() {});
                                                },
                                              ),
                                            ),
                                          )
                                        ],
                                      )
                                    ],
                                  );
                                });
                          }),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          height: ResponsiveUtil.getResponsiveValue(
                            context,
                            small: 44.0,
                            medium: 48.0,
                            large: 52.0,
                          ),
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: profileProvider.isUpdating
                                ? null
                                : () => _handleSave(context, editProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: EdgeInsets.symmetric(
                                  vertical: ResponsiveUtil.getPadding(context,
                                      small: 8, medium: 10, large: 12)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    ResponsiveUtil.getResponsiveValue(
                                  context,
                                  small: 10.0,
                                  medium: 12.0,
                                  large: 14.0,
                                )),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              profileProvider.isUpdating
                                  ? 'Saving...'
                                  : 'Save Changes',
                              style: AppTypography.button.copyWith(
                                color: AppColors.buttonText,
                                fontSize: ResponsiveUtil.getFontSize(
                                  context,
                                  small: 14,
                                  medium: 16,
                                  large: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget labelWidget(String label, BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.only(),
      child: Text(
        label,
        style: TextStyle(
            fontSize: ResponsiveUtil.getFontSize(
              ctx,
              small: 13,
              medium: 14,
              large: 15,
            ),
            fontWeight: fontmedium,
            color: const Color(0xff4B5563)),
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
      padding: EdgeInsets.symmetric(
        horizontal:
            ResponsiveUtil.getPadding(context, small: 8, medium: 10, large: 12),
        vertical:
            ResponsiveUtil.getPadding(context, small: 4, medium: 5, large: 6),
      ),
      decoration: BoxDecoration(
        color: const Color(0xffEEF2FF),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: ResponsiveUtil.getResponsiveValue(context,
            small: 2.0, medium: 3.0, large: 4.0),
        children: [
          GestureDetector(
            onTap: onTap,
            child: Icon(
              Icons.close,
              color: const Color(0xff2563EB),
              size: ResponsiveUtil.getIconSize(context,
                  small: 15, medium: 17, large: 19),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xff2563EB),
              fontSize: ResponsiveUtil.getFontSize(context,
                  small: 12, medium: 14, large: 16),
              fontWeight: fontregular,
            ),
          )
        ],
      ),
    );
  }
}
