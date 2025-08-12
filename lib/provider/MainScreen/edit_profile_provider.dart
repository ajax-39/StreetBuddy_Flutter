import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';

class EditProfileProvider with ChangeNotifier {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  Gender _selectedGender = Gender.preferNotToSay;
  DateTime? _selectedBirthdate;
  File? _selectedImage;
  File? _selectedCoverImage;
  final _imagePicker = ImagePicker();
  bool _isLoading = true;
  bool _isCheckingUsername = false;
  String? _usernameError;
  Timer? _debounceTimer;
  String? _originalUsername;
  bool _isInitialized = false;
  bool _isCoverUploading = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get isCheckingUsername => _isCheckingUsername;
  String? get usernameError => _usernameError;
  Gender get selectedGender => _selectedGender;
  DateTime? get selectedBirthdate => _selectedBirthdate;
  File? get selectedImage => _selectedImage;
  File? get selectedCoverImage => _selectedCoverImage;
  bool get isInitialized => _isInitialized;
  bool get isCoverUploading => _isCoverUploading;

  EditProfileProvider() {
    _setupUsernameListener();
  }

  void setUsernameError(String? error) {
    _usernameError = error;
    notifyListeners();
  }

  void _setupUsernameListener() {
    usernameController.addListener(() {
      if (_debounceTimer?.isActive ?? false) {
        _debounceTimer!.cancel();
      }

      if (usernameController.text.isEmpty) {
        _usernameError = 'Username cannot be empty';
        notifyListeners();
        return;
      }

      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        checkUsernameAvailability(usernameController.text);
      });
    });
  }

  Future<void> initializeUserData(
      ProfileProvider profileProvider, String uid) async {
    if (_isInitialized) return;

    try {
      await profileProvider.fetchUserData(uid);
      final userData = profileProvider.userData;

      if (userData != null) {
        usernameController.text = userData.username;
        _originalUsername = userData.username;
        nameController.text = userData.name;
        bioController.text = userData.bio ?? '';
        phoneController.text = userData.phoneNumber ?? '';
        _selectedGender = userData.gender;
        _selectedBirthdate = userData.birthdate;
      }
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setGender(Gender gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  void setBirthdate(DateTime? date) {
    _selectedBirthdate = date;
    notifyListeners();
  }

  Future<void> checkUsernameAvailability(String username) async {
    if (username == _originalUsername) {
      _usernameError = null;
      notifyListeners();
      return;
    }

    _isCheckingUsername = true;
    notifyListeners();

    try {
      final isAvailable =
          await ProfileProvider().checkUsernameAvailability(username);
      _usernameError = isAvailable ? null : 'Username is already taken';
    } catch (e) {
      _usernameError = 'Error checking username availability';
    } finally {
      _isCheckingUsername = false;
      notifyListeners();
    }
  }

  Future<void> uploadCoverImage(String uid, BuildContext context) async {
    if (_selectedCoverImage == null) return;
    _isCoverUploading = true;
    notifyListeners();
    try {
      await ProfileProvider().updateProfile(
        uid,
        coverImage: _selectedCoverImage,
      );
      // Optionally, you can show a snackbar or refresh profile data here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cover image updated!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update cover image: $e')),
      );
    } finally {
      _isCoverUploading = false;
      notifyListeners();
    }
  }

  Future<void> pickImage(ImageSource source, BuildContext context,
      {bool isCover = false, String? uid}) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        File img = File(image.path);

        if (context.mounted) {
          final resultImage =
              await context.push<File>('/crop-image', extra: img);

          if (resultImage != null) {
            if (isCover) {
              _selectedCoverImage = resultImage;
              notifyListeners();
              if (uid != null) {
                await uploadCoverImage(uid, context);
              }
            } else {
              _selectedImage = resultImage;
              notifyListeners();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    nameController.dispose();
    bioController.dispose();
    phoneController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
