import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/provider/Auth/auth_provider.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/provider/MainScreen/edit_profile_provider.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/buttons/custom_leading_button.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  InputDecoration _getInputDecoration(String label, String helper,
      {String? errorText, bool? showLoading}) {
    return InputDecoration(
      helperText: helper.isEmpty ? null : helper,
      errorText: errorText,
      helperStyle: AppTypography.caption,
      labelStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.textFill,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
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
      await provider.updateProfile(
        authProvider.userModel!.uid,
        username: editProvider.usernameController.text,
        name: editProvider.nameController.text,
        gender: editProvider.selectedGender,
        bio: editProvider.bioController.text,
        phoneNumber: editProvider.phoneController.text,
        birthdate: editProvider.selectedBirthdate,
        profileImage: editProvider.selectedImage,
        coverImage: editProvider.selectedCoverImage,
      );
      Navigator.pop(context);
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
              leading: const CustomLeadingButton(),
              title: const Text('Edit Profile', style: TextStyle(fontSize: 20)),
              centerTitle: true,
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 17,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
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
                        GestureDetector(
                          onTap: () => _showImageSourceSheet(
                              context, editProvider,
                              isCover: true),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.md),
                                child: SizedBox(
                                    height: 200,
                                    width: double.infinity,
                                    child: Image(
                                      fit: BoxFit.cover,
                                      image: editProvider.selectedCoverImage ==
                                                  null &&
                                              userData?.coverImageUrl == null
                                          ? const NetworkImage(
                                              Constant.DEFAULT_PLACE_IMAGE)
                                          : editProvider.selectedCoverImage !=
                                                  null
                                              ? FileImage(editProvider
                                                      .selectedCoverImage!)
                                                  as ImageProvider
                                              : NetworkImage(userData
                                                      ?.coverImageUrl ??
                                                  Constant.DEFAULT_PLACE_IMAGE),
                                    )),
                              ),
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: AppColors.buttonText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Baseline(
                          baselineType: TextBaseline.alphabetic,
                          baseline: 50,
                          child: Center(
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
                                      radius: 59,
                                      backgroundColor:
                                          AppColors.surfaceBackground,
                                      backgroundImage: editProvider
                                                  .selectedImage !=
                                              null
                                          ? FileImage(
                                                  editProvider.selectedImage!)
                                              as ImageProvider
                                          : userData?.profileImageUrl != null
                                              ? NetworkImage(
                                                  userData!.profileImageUrl!)
                                              : null,
                                      child: editProvider.selectedImage ==
                                                  null &&
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
                                      padding: const EdgeInsets.all(
                                          AppSpacing.xs + 2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
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
                        ),
                        Center(
                          child: TextButton(
                            onPressed: () =>
                                _showImageSourceSheet(context, editProvider),
                            child: const Text(
                              'Change Photo',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        labelWidget('Username'),
                        TextField(
                          controller: editProvider.usernameController,
                          decoration: _getInputDecoration(
                            'Username',
                            '',
                            errorText: editProvider.usernameError,
                            showLoading: editProvider.isCheckingUsername,
                          ),
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        labelWidget('Display Name'),
                        TextField(
                          controller: editProvider.nameController,
                          decoration: _getInputDecoration(
                            'Name',
                            '',
                          ),
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        labelWidget('gender'),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                            color: AppColors.textFill,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Gender>(
                              isExpanded: true,
                              value: editProvider.selectedGender,
                              hint: Text('Select Gender',
                                  style: AppTypography.body.copyWith(
                                      color: AppColors.textSecondary)),
                              items: Gender.values.map((Gender gender) {
                                String displayText;
                                switch (gender) {
                                  case Gender.male:
                                    displayText = 'Male';
                                    break;
                                  case Gender.female:
                                    displayText = 'Female';
                                    break;
                                  case Gender.preferNotToSay:
                                    displayText = 'Prefer not to say';
                                    break;
                                }
                                return DropdownMenuItem<Gender>(
                                  value: gender,
                                  child: Text(displayText,
                                      style: AppTypography.body),
                                );
                              }).toList(),
                              onChanged: (Gender? value) {
                                if (value != null) {
                                  editProvider.setGender(value);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        labelWidget('Bio'),
                        TextField(
                          controller: editProvider.bioController,
                          decoration: _getInputDecoration(
                            'Bio',
                            'Tell others about yourself',
                          ),
                          style: AppTypography.body,
                          maxLines: 5,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        labelWidget('Phone Number'),
                        TextField(
                          controller: editProvider.phoneController,
                          decoration: _getInputDecoration(
                            'Phone Number',
                            'Add your contact number (max 10 digits)',
                          ),
                          style: AppTypography.body,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        labelWidget('Birthdate'),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                            color: AppColors.textFill,
                          ),
                          child: InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: editProvider.selectedBirthdate ??
                                    DateTime.now(),
                                firstDate: DateTime(1950),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: AppColors.primary,
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                editProvider.setBirthdate(picked);
                              }
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              title: Text(
                                editProvider.selectedBirthdate != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(editProvider.selectedBirthdate!)
                                    : 'Tap to select birthdate',
                                style: AppTypography.caption,
                              ),
                              trailing: Image.asset(
                                'assets/icon/calender.png',
                                width: 20,
                                height: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          height: 44,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: profileProvider.isUpdating
                                ? null
                                : () => _handleSave(context, editProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.md),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              profileProvider.isUpdating
                                  ? 'Saving...'
                                  : 'Save Changes',
                              style: AppTypography.button.copyWith(
                                color: AppColors.buttonText,
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

  labelWidget(String label) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
        ),
      ),
    );
  }
}
