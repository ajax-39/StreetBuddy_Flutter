import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:street_buddy/provider/Auth/auth_notifier.dart';
import 'package:street_buddy/provider/Auth/otp_provider.dart';
import 'package:street_buddy/widgets/crop_image_screen.dart';

class SignUpProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _supabase = Supabase.instance.client;
  final Random _random = Random();

  //==========================================
  // Screen 1: Email/Phone Input Screen
  //==========================================
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  String? selectedState;
  String? selectedCity;
  String? verificationId;
  bool _isPhoneSignUp = true;
  bool showOtpField = false;
  bool get isPhoneSignUp => _isPhoneSignUp;
  String? identifier;

  String?
      optionalPhoneNumber; // Field to store the optional phone number temporarily

  void setIdentifier(String? value) {
    identifier = value;
    notifyListeners();
  }

  void resetIdentifier() {
    identifier = null;
    notifyListeners();
  }

  void setSignUpMethod(bool isPhone) {
    _isPhoneSignUp = isPhone;
    notifyListeners();
  }

  Future<bool> checkPhoneExists(String phoneNumber) async {
    try {
      debugPrint('🔍 Checking if phone number exists: $phoneNumber');

      final result = await _supabase
          .from('users')
          .select()
          .eq('phone_number', phoneNumber)
          .maybeSingle();

      debugPrint(result != null
          ? '🟡 Phone number already registered'
          : '✅ Phone number available for registration');

      return result != null;
    } catch (e) {
      debugPrint('❌ Error checking phone existence: $e');
      return false;
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      debugPrint('🔍 Checking if email exists: $email');

      final result = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      debugPrint(result != null
          ? '🟡 Email already registered'
          : '✅ Email available for registration');

      return result != null;
    } catch (e) {
      debugPrint('❌ Error checking email existence: $e');
      return false;
    }
  }

  Future<String> signUpWithPhone(String phoneNumber,
      {required Function(String) onCodeSent}) async {
    try {
      String verificationId = '';

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw e;
        },
        codeSent: (String verId, int? resendToken) {
          verificationId = verId;
          onCodeSent(verId);
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
        },
      );

      return verificationId;
    } catch (e) {
      print('Error signing up with phone: $e');
      rethrow;
    }
  }

  Future<String> verifySignUpOTP(
      String verificationId, String otp, String username) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      auth.User? user = result.user;

      if (user != null) {
        final newUser = {
          'uid': user.uid,
          'username': username,
          'name': username, // Add name field with username as default
          'phone_number': user.phoneNumber,
          'created_at': DateTime.now().toIso8601String(),
          'is_vip': false,
          'is_email_verified': false,
          'city': selectedCity,
          'state': selectedState,
          'gender': 'prefer_not_to_say', // Add default gender
        };

        debugPrint(
            '🔵 Creating new user in Supabase with phone: ${user.phoneNumber}');
        debugPrint('📝 User data: ${newUser.toString()}');

        await _supabase.from('users').insert(newUser);
        debugPrint('✅ User created successfully in Supabase');
      }

      _resetState();
      return user!.uid;
    } catch (e) {
      debugPrint('❌ Error creating user in Supabase: $e');
      rethrow;
    }
  }

  //==========================================
  // Screen 2: Password Screen
  //==========================================
  final passwordController = TextEditingController();
  final confPasswordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isConfPasswordVisible = false;

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  void toggleConfPasswordVisibility() {
    isConfPasswordVisible = !isConfPasswordVisible;
    notifyListeners();
  }

  Future<String> registerWithEmail(
      String email, String password, String username) async {
    try {
      final result = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      supabase.User? user = result.user;

      final newUser = {
        'uid': user!.id,
        'username': username,
        'name': username,
        'email': email,
        'phone_number': phoneController.text,
        'profile_image_url': null,
        'created_at': DateTime.now().toIso8601String(),
        'birthdate': _selectedBirthday?.toIso8601String(),
        'is_vip': false,
        'is_email_verified': false,
        'city': selectedCity,
        'state': selectedState,
        'gender': 'prefer_not_to_say',
      };

      debugPrint('🔵 Creating new user in Supabase with email: $email');
      debugPrint('📝 User data: ${newUser.toString()}');

      await _supabase.from('users').insert(newUser);
      debugPrint('✅ User created successfully in Supabase');

      return user.id;
    } catch (e) {
      debugPrint('❌ Error creating user in Supabase: $e');
      rethrow;
    }
  }

  Future<String> registerWithPhone(
      String phone, String password, String username) async {
    try {
      final result = await _supabase.auth.signUp(
        phone: "+91$phone",
        password: password,
      );
      supabase.User? user = result.user;

      final newUser = {
        'uid': user!.id,
        'username': username,
        'name': username,
        'email': '',
        'phone_number': "+91$phone",
        'profile_image_url': null,
        'created_at': DateTime.now().toIso8601String(),
        'birthdate': _selectedBirthday?.toIso8601String(),
        'is_vip': false,
        'is_email_verified': false,
        'city': selectedCity,
        'state': selectedState,
        'gender': 'prefer_not_to_say',
      };

      debugPrint('🔵 Creating new user in Supabase with phone: $phone');
      debugPrint('📝 User data: ${newUser.toString()}');

      await _supabase.from('users').insert(newUser);
      debugPrint('✅ User created successfully in Supabase');

      return user.id;
    } catch (e) {
      debugPrint('❌ Error creating user in Supabase: $e');
      rethrow;
    }
  }

  //==========================================
  // Screen 3: Birthday Screen
  //==========================================
  DateTime? _selectedBirthday;
  final TextEditingController birthdayController = TextEditingController();

  DateTime? get selectedBirthday => _selectedBirthday;

  void setBirthday(DateTime date) {
    _selectedBirthday = date;
    birthdayController.text = DateFormat('MMMM d, yyyy').format(date);
    notifyListeners();
  }

  String get birthdayText {
    if (_selectedBirthday == null) {
      return 'Birthday (Select your birthday)';
    }

    final today = DateTime.now();
    int age = today.year - _selectedBirthday!.year;

    if (today.month < _selectedBirthday!.month ||
        (today.month == _selectedBirthday!.month &&
            today.day < _selectedBirthday!.day)) {
      age--;
    }

    return 'Birthday ($age years old)';
  }

  //==========================================
  // Screen 4: Username Screen
  //==========================================
  final usernameController = TextEditingController();
  List<String> _usernameSuggestions = [];
  bool _isCheckingUsername = false;
  bool _isUsernameExists = false;
  Timer? _debounceTimer;

  bool get isUsernameExists => _isUsernameExists;
  List<String> get usernameSuggestions => _usernameSuggestions;
  bool get isCheckingUsername => _isCheckingUsername;

  void debounceUsernameCheck(String username) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (username.isNotEmpty) {
        _isCheckingUsername = true;
        notifyListeners();

        final exists = await checkUsernameExists(username);
        if (exists) {
          generateUsernameSuggestions(username);
        } else {
          clearUsernameSuggestions();
        }

        _isUsernameExists = exists;
        _isCheckingUsername = false;
        notifyListeners();
      } else {
        clearUsernameSuggestions();
        _isUsernameExists = false;
        notifyListeners();
      }
    });
  }

  void setUsername(String username) {
    usernameController.text = username;
    clearUsernameSuggestions();
    _isUsernameExists = false;
    notifyListeners();
  }

  Future<bool> checkUsernameExists(String username) async {
    try {
      _isCheckingUsername = true;
      notifyListeners();

      debugPrint('🔍 Checking if username exists: $username');

      final result = await _supabase
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();

      debugPrint(result != null
          ? '🟡 Username "$username" already exists'
          : '✅ Username "$username" is available');

      _isCheckingUsername = false;
      notifyListeners();
      return result != null;
    } catch (e) {
      debugPrint('❌ Error checking username existence: $e');
      _isCheckingUsername = false;
      notifyListeners();
      return false;
    }
  }

  String _generateRandomSuffix(int length) {
    String result = '';
    for (int i = 0; i < length; i++) {
      result += _random.nextInt(10).toString();
    }
    return result;
  }

  Future<bool> _isUsernameSuggestionAvailable(String username) async {
    try {
      final result = await _supabase
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();
      return result == null;
    } catch (e) {
      print('Error checking username suggestion availability: $e');
      return true;
    }
  }

  Future<String?> _generateUniqueUsername(String baseUsername) async {
    for (int attempt = 0; attempt < 10; attempt++) {
      String suffix = _generateRandomSuffix(4);
      String suggestedUsername = '$baseUsername$suffix';

      if (await _isUsernameSuggestionAvailable(suggestedUsername)) {
        return suggestedUsername;
      }
    }
    return null;
  }

  void generateUsernameSuggestions(String baseUsername) async {
    try {
      List<String> suggestions = [];

      for (int i = 0; i < 3; i++) {
        String? suggestion = await _generateUniqueUsername(baseUsername);
        if (suggestion != null && !suggestions.contains(suggestion)) {
          suggestions.add(suggestion);
        }
      }

      while (suggestions.length < 3) {
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        String fallbackSuffix = timestamp.substring(timestamp.length - 4);
        String fallbackUsername = '$baseUsername$fallbackSuffix';

        if (!suggestions.contains(fallbackUsername) &&
            await _isUsernameSuggestionAvailable(fallbackUsername)) {
          suggestions.add(fallbackUsername);
        }
      }

      _usernameSuggestions = suggestions;
      notifyListeners();
    } catch (e) {
      print('Error generating username suggestions: $e');
      _usernameSuggestions = [
        '$baseUsername${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
      ];
      notifyListeners();
    }
  }

  void clearUsernameSuggestions() {
    _usernameSuggestions = [];
    notifyListeners();
  }

  String? _profilePictureUrl;
  String? get profilePictureUrl => _profilePictureUrl;

  void setProfilePictureUrl(String? url) {
    _profilePictureUrl = url;
    notifyListeners();
  }
  //==========================================
  // Screen 5: Username Screen
  //==========================================

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> validateImage(File image) async {
    try {
      if (!await image.exists()) {
        return false;
      }

      ///TODO : LIMIT FILE SIZE
      // final size = await image.length();
      // if (size > 5 * 1024 * 1024) {
      //   return false;
      // }

      final extension = path.extension(image.path).toLowerCase();
      return ['.jpg', '.jpeg', '.png'].contains(extension);
    } catch (e) {
      print('Error validating image: $e');
      return false;
    }
  }

  Future<String?> uploadImageToStorage(String imagePath, String userId) async {
    File imageFile = File(imagePath);

    try {
      /// TODO: RECHECK FILE SIZE
      // if (!await validateImage(imageFile)) {
      //   throw Exception('Invalid image file or size too large (max 5MB)');
      // }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imagePath);
      final filename = 'profile_$timestamp$extension';

      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(userId)
          .child('profile_pictures')
          .child(filename);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadTime': DateTime.now().toIso8601String(),
          'fileName': filename,
        },
      );

      int retryAttempts = 3;
      UploadTask? uploadTask;
      String? downloadUrl;

      while (retryAttempts > 0 && downloadUrl == null) {
        try {
          uploadTask = storageRef.putFile(imageFile, metadata);

          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            double progress = snapshot.bytesTransferred / snapshot.totalBytes;
            print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
          }, onError: (error) {
            print('Upload stream error: $error');
          });

          final snapshot = await uploadTask;
          downloadUrl = await snapshot.ref.getDownloadURL();
        } catch (e) {
          print('Upload attempt failed: $e');
          retryAttempts--;
          if (retryAttempts > 0) {
            await Future.delayed(const Duration(seconds: 2));
            print('Retrying upload... Attempts remaining: $retryAttempts');
          }
        }
      }

      if (downloadUrl == null) {
        throw Exception('Failed to upload image after multiple attempts');
      }

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfilePicture(String userId, String imageUrl) async {
    try {
      debugPrint('🔵 Updating profile picture for user: $userId');
      debugPrint('🖼️ New image URL: $imageUrl');

      await _supabase.from('users').update({
        'profile_image_url': imageUrl,
        // Remove the updated_at field as it doesn't exist in the table
      }).eq('uid', userId);

      debugPrint('✅ Profile picture updated successfully in Supabase');
    } catch (e) {
      debugPrint('❌ Error updating profile picture in Supabase: $e');
      rethrow;
    }
  }

  // Only allow email sign-up, remove phone logic
  Future<void> completeUserRegistration(
      BuildContext context, String? imagePath) async {
    if (_isLoading) return;

    _setLoading(true);

    try {
      // Always use email registration
      String? userId;
      try {
        userId = await registerWithEmail(
          emailController.text.trim(),
          passwordController.text.trim(),
          usernameController.text.trim(),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _setLoading(false);
        return;
      }

      if (userId.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration failed: No user ID returned.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _setLoading(false);
        return;
      }

      if (imagePath != null && imagePath.isNotEmpty) {
        String? downloadUrl;
        try {
          downloadUrl = await uploadImageToStorage(imagePath, userId);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Profile picture upload failed. You can add it later from your profile.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
        if (downloadUrl != null) {
          await updateUserProfilePicture(userId, downloadUrl);
        }
      }

      // After user is created, update phone number if provided
      if (optionalPhoneNumber != null && optionalPhoneNumber!.isNotEmpty) {
        debugPrint(
            '📲 [completeUserRegistration] Updating phone after user creation: $optionalPhoneNumber');
        await saveOptionalPhoneNumber(optionalPhoneNumber!);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        final authNotifier =
            Provider.of<AuthStateNotifier>(context, listen: false);
        authNotifier.markRegistrationComplete();
        context.go('/welcome');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> requestPermissions(BuildContext context) async {
    if (Platform.isIOS) {
      final photos = await Permission.photos.request();
      final camera = await Permission.camera.request();

      if (photos.isDenied || camera.isDenied) {
        _showErrorDialog(context,
            'Permission denied. Please enable camera and photo permissions in settings.');
      }
    } else {
      final storage = await Permission.storage.request();
      final camera = await Permission.camera.request();

      if (storage.isDenied || camera.isDenied) {
        _showErrorDialog(context,
            'Permission denied. Please enable storage and camera permissions in settings.');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> handleImageSelection(
    BuildContext context,
    ImageSource source,
  ) async {
    try {
      Navigator.pop(context);

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image != null) {
        File? img = File(image.path);
        // img = await _cropImage(imageFile: img);
        final File resultimagefile = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CropImageScreen(image: img),
            ));

        final resultimage = XFile(resultimagefile.path);

        if (context.mounted) {
          final String imagePath = resultimage.path;
          setProfilePictureUrl(imagePath);
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  //==========================================
  // Utility Functions
  //==========================================
  void _resetState() {
    emailController.clear();
    passwordController.clear();
    phoneController.clear();
    otpController.clear();
    verificationId = null;
    _isPhoneSignUp = true;
    showOtpField = false;
    isPasswordVisible = false;
    usernameController.clear();
    _usernameSuggestions = [];
    notifyListeners();
  }

  @override
  void dispose() {
    birthdayController.dispose();
    usernameController.dispose();
    _debounceTimer?.cancel();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  // Save optional phone number to Supabase users table
  Future<void> saveOptionalPhoneNumber(String phoneNumber) async {
    debugPrint('📞 [saveOptionalPhoneNumber] Called with phone: $phoneNumber');
    try {
      final user = _supabase.auth.currentUser;
      debugPrint('🆔 [saveOptionalPhoneNumber] Current user: \\${user?.id}');
      if (user == null) {
        debugPrint('❗ [saveOptionalPhoneNumber] No current user found.');
        return;
      }
      final response = await _supabase
          .from('users')
          .update({'phone_number': phoneNumber}).eq('uid', user.id);
      debugPrint(
          '✅ [saveOptionalPhoneNumber] Supabase update response: \\${response.toString()}');
      phoneController.text = phoneNumber;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [saveOptionalPhoneNumber] Error: $e');
    }
  }

  Future<void> saveOptionalPhoneNumberLocally(String phoneNumber) async {
    debugPrint(
        '📲 [saveOptionalPhoneNumberLocally] Storing phone: $phoneNumber');
    optionalPhoneNumber = phoneNumber;
    phoneController.text = phoneNumber;
    notifyListeners();
  }
}
