import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:street_buddy/models/vendor.dart';
import 'package:street_buddy/globals.dart';

class BusinessInfoProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController facebookController = TextEditingController();
  final TextEditingController twitterController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  BusinessInfoProvider();

  // State variables
  String? _selectedState;
  String? _selectedCity;
  String? _selectedCategory;
  List<File> _selectedImages = [];
  bool _isLoading = false;
  String? _error;

  // Business hours
  Map<String, Map<String, String>> _businessHours = {
    'Monday': {'from': '09:00', 'to': '18:00'},
    'Tuesday': {'from': '09:00', 'to': '18:00'},
    'Wednesday': {'from': '09:00', 'to': '18:00'},
    'Thursday': {'from': '09:00', 'to': '18:00'},
    'Friday': {'from': '09:00', 'to': '18:00'},
    'Saturday': {'from': '09:00', 'to': '18:00'},
    'Sunday': {'from': '09:00', 'to': '18:00'},
  };

  // Getters
  String? get selectedState => _selectedState;
  String? get selectedCity => _selectedCity;
  String? get selectedCategory => _selectedCategory;
  List<File> get selectedImages => _selectedImages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, Map<String, String>> get businessHours => _businessHours;

  // Lists for dropdowns
  final List<String> states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Puducherry',
    'Chandigarh',
    'Andaman and Nicobar Islands',
    'Dadra and Nagar Haveli',
    'Daman and Diu',
    'Lakshadweep'
  ];

  final List<String> categories = [
    'Restaurant',
    'Cafe',
    'Shopping',
    'Entertainment',
    'Healthcare',
    'Education',
    'Beauty & Spa',
    'Automotive',
    'Real Estate',
    'Travel',
    'Fitness',
    'Professional Services',
    'Home Services',
    'Other'
  ];

  final Map<String, List<String>> cities = {
    'Delhi': ['New Delhi', 'Old Delhi', 'Dwarka', 'Rohini', 'Karol Bagh'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Aurangabad'],
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore', 'Belgaum'],
    'Tamil Nadu': [
      'Chennai',
      'Coimbatore',
      'Madurai',
      'Tiruchirappalli',
      'Salem'
    ],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar'],
    'Rajasthan': ['Jaipur', 'Udaipur', 'Jodhpur', 'Kota', 'Bikaner'],
    'West Bengal': ['Kolkata', 'Howrah', 'Durgapur', 'Asansol', 'Siliguri'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Ghaziabad', 'Agra', 'Varanasi'],
    'Punjab': ['Chandigarh', 'Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala'],
    'Haryana': ['Gurgaon', 'Faridabad', 'Panipat', 'Ambala', 'Hisar'],
    'Himachal Pradesh': ['Shimla', 'Manali', 'Dharamshala', 'Kullu', 'Solan'],
    'Uttarakhand': [
      'Dehradun',
      'Haridwar',
      'Rishikesh',
      'Nainital',
      'Mussoorie'
    ],
    'Goa': ['Panaji', 'Margao', 'Vasco da Gama', 'Mapusa', 'Ponda'],
  };

  void setSelectedState(String? state) {
    _selectedState = state;
    _selectedCity = null; // Reset city when state changes
    notifyListeners();
  }

  void setSelectedCity(String? city) {
    _selectedCity = city;
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  List<String> getCitiesForState(String? state) {
    if (state == null) return [];
    return cities[state] ?? [];
  }

  Future<void> pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        _selectedImages = images.map((image) => File(image.path)).toList();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to pick images: $e';
      notifyListeners();
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  void updateBusinessHours(String day, String type, String time) {
    _businessHours[day]![type] = time;
    notifyListeners();
  }

  Future<void> submitBusinessInfo() async {
    debugPrint('🚀 Submit business info started');

    if (!_validateForm()) {
      debugPrint('❌ Form validation failed: $_error');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    debugPrint('⏳ Setting loading state and uploading...');

    try {
      final currentUser = globalUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      debugPrint('✅ User authenticated: ${currentUser.uid}');

      // Upload images first
      List<String> photoUrls = [];
      if (_selectedImages.isNotEmpty) {
        debugPrint('📸 Uploading ${_selectedImages.length} images...');
        photoUrls = await _uploadImages();
        debugPrint('✅ Images uploaded successfully: $photoUrls');
      } else {
        debugPrint('ℹ️ No images selected to upload');
      }

      // Create opening hours list
      List<OpeningHours> openingHours = _businessHours.entries.map((entry) {
        return OpeningHours(
          day: entry.key,
          opensat: entry.value['from'],
          closesat: entry.value['to'],
        );
      }).toList();
      debugPrint('🕐 Business hours prepared: ${openingHours.length} entries');

      // Create vendor model
      final vendor = VendorModel(
        name: businessNameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        email: emailController.text.trim(),
        address: addressController.text.trim(),
        city: _selectedCity,
        state: _selectedState,
        category: _selectedCategory,
        photoUrl: photoUrls,
        userId: currentUser.uid,
        businessDescription: descriptionController.text.trim(),
        website: websiteController.text.trim().isEmpty
            ? null
            : websiteController.text.trim(),
        instagram: instagramController.text.trim().isEmpty
            ? null
            : instagramController.text.trim(),
        facebook: facebookController.text.trim().isEmpty
            ? null
            : facebookController.text.trim(),
        twitter: twitterController.text.trim().isEmpty
            ? null
            : twitterController.text.trim(),
        openingHours: openingHours,
        isApproved: false, // New vendors require admin approval
      );
      debugPrint('📋 Vendor model created for: ${vendor.name}');

      // Save to Supabase
      debugPrint('💾 Saving to Supabase vendors table...');
      await _supabase.from('vendors').insert(vendor.toJson());
      debugPrint('✅ Successfully saved to Supabase!');

      _isLoading = false;
      notifyListeners();
      debugPrint('🎉 Business info submission completed successfully!');

      // Success - this should be handled by the UI
    } catch (e) {
      debugPrint('❌ Error during business info submission: $e');
      _error = 'Failed to submit business information: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _validateForm() {
    if (businessNameController.text.trim().isEmpty) {
      _error = 'Business name is required';
      notifyListeners();
      return false;
    }

    if (_selectedCategory == null) {
      _error = 'Please select a business category';
      notifyListeners();
      return false;
    }

    if (_selectedState == null) {
      _error = 'Please select a state';
      notifyListeners();
      return false;
    }

    if (_selectedCity == null) {
      _error = 'Please select a city';
      notifyListeners();
      return false;
    }

    if (addressController.text.trim().isEmpty) {
      _error = 'Address is required';
      notifyListeners();
      return false;
    }

    if (descriptionController.text.trim().isEmpty) {
      _error = 'Business description is required';
      notifyListeners();
      return false;
    }

    if (phoneController.text.trim().isEmpty) {
      _error = 'Phone number is required';
      notifyListeners();
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      _error = 'Email is required';
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<List<String>> _uploadImages() async {
    List<String> urls = [];
    debugPrint('📸 Starting image upload process...');

    try {
      for (int i = 0; i < _selectedImages.length; i++) {
        final file = _selectedImages[i];
        debugPrint(
            '📤 Uploading image ${i + 1}/${_selectedImages.length}: ${file.path}');

        // Verify file exists before upload
        if (!file.existsSync()) {
          debugPrint('⚠️ File does not exist: ${file.path}');
          continue;
        }

        final fileName =
            'business_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final imagePath = 'business-photos/$fileName';

        debugPrint('🔄 Uploading to Firebase Storage path: $imagePath');

        // Upload to Firebase Storage
        final ref = _storage.ref().child(imagePath);
        final uploadTask = ref.putFile(file);

        final snapshot = await uploadTask.whenComplete(() {
          debugPrint('✅ Upload completed for image $i');
        });

        final url = await snapshot.ref.getDownloadURL();
        urls.add(url);
        debugPrint('🔗 Image $i URL obtained: $url');
      }

      debugPrint(
          '✅ All images uploaded successfully. Total URLs: ${urls.length}');
      return urls;
    } catch (e) {
      debugPrint('❌ Error uploading images: $e');
      throw Exception('Failed to upload images: $e');
    }
  }

  void clearForm() {
    businessNameController.clear();
    descriptionController.clear();
    phoneController.clear();
    emailController.clear();
    websiteController.clear();
    instagramController.clear();
    facebookController.clear();
    twitterController.clear();
    addressController.clear();

    _selectedState = null;
    _selectedCity = null;
    _selectedCategory = null;
    _selectedImages.clear();
    _error = null;

    // Reset business hours to default
    _businessHours = {
      'Monday': {'from': '09:00', 'to': '18:00'},
      'Tuesday': {'from': '09:00', 'to': '18:00'},
      'Wednesday': {'from': '09:00', 'to': '18:00'},
      'Thursday': {'from': '09:00', 'to': '18:00'},
      'Friday': {'from': '09:00', 'to': '18:00'},
      'Saturday': {'from': '09:00', 'to': '18:00'},
      'Sunday': {'from': '09:00', 'to': '18:00'},
    };

    notifyListeners();
  }

  @override
  void dispose() {
    businessNameController.dispose();
    descriptionController.dispose();
    phoneController.dispose();
    emailController.dispose();
    websiteController.dispose();
    instagramController.dispose();
    facebookController.dispose();
    twitterController.dispose();
    addressController.dispose();
    super.dispose();
  }
}
