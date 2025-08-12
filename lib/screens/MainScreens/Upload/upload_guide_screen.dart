import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/guide.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/provider/MainScreen/guide_provider.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/provider/MainScreen/upload_provider.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/utils/indianStatesCities.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:uuid/uuid.dart';

// Class to represent each place in a guide
class PlaceEntry {
  final String id = const Uuid().v4();
  String placeName = '';
  String placeType = '';
  String experience = '';
  List<File> mediaFiles = [];
  double? latitude;
  double? longitude;
  File? thumbnailFile;

  bool get isValid =>
      placeName.isNotEmpty &&
      placeType.isNotEmpty &&
      experience.isNotEmpty &&
      mediaFiles.isNotEmpty;

  bool get hasThumbnail => thumbnailFile != null || mediaFiles.isNotEmpty;

  File get thumbnail => thumbnailFile ?? mediaFiles.first;
}

class UploadGuideScreen extends StatefulWidget {
  const UploadGuideScreen({super.key});

  @override
  State<UploadGuideScreen> createState() => _UploadGuideScreenState();
}

class _UploadGuideScreenState extends State<UploadGuideScreen> {
  final _guideNameController = TextEditingController();
  final _guideDescriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final List<String> _tags = []; // Location search functionality
  final _locationSearchController = TextEditingController();
  Timer? _debounce; // Kept for legacy references, will be removed later
  // Tips management
  final List<String> _tips = [];
  final _tipController = TextEditingController();

  // Places inside guide management
  final List<PlaceEntry> _places = [];
  File? _mainThumbnail;
  int _selectedPlaceIndex = -1; // -1 means no place is selected for editing

  // Place fields controllers - only used when editing a specific place
  final _placeNameController = TextEditingController();
  final _placeTypeController = TextEditingController();
  final _experienceController = TextEditingController();
  // Main guide location
  String? selectedCity;
  final Map<String, List<String>> stateCityData = indianStatesCities;
  String? selectedState;
  String? customCity;
  final _customCityController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize with one empty place
    _addNewPlace();
  }

  @override
  void dispose() {
    _guideNameController.dispose();
    _guideDescriptionController.dispose();
    _tagsController.dispose();
    _placeNameController.dispose();
    _placeTypeController.dispose();
    _experienceController.dispose();
    _locationSearchController.dispose();
    _customCityController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  // We're now using the dropdown_search package's asyncItems property
  // instead of this method, so it's been removed.

  void _onTagAdded(String value) {
    if (value.isEmpty) return;
    String trimmedValue = value.trim();

    // Automatically add hashtag if not present
    if (!trimmedValue.startsWith('#')) {
      trimmedValue = '#$trimmedValue';
    }

    // Avoid duplicate tags
    if (!_tags.contains(trimmedValue)) {
      setState(() {
        _tags.add(trimmedValue);
        _tagsController.clear();
      });
    } else {
      // Clear the text field even if tag already exists
      _tagsController.clear();
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

  Widget _labelWidget(String label) {
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

  // Helper methods for managing places in the guide
  Future<void> _pickImages(PlaceEntry place) async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isEmpty) return;

    setState(() {
      place.mediaFiles.addAll(images.map((image) => File(image.path)));
      // Set first image as thumbnail if not set yet
      if (place.thumbnailFile == null && place.mediaFiles.isNotEmpty) {
        place.thumbnailFile = place.mediaFiles.first;
      }
    });
  }

  Future<void> _pickMainThumbnail() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      _mainThumbnail = File(image.path);
    });
  }

  void _addNewPlace() {
    // Save current place data before adding a new place
    if (_selectedPlaceIndex >= 0 && _selectedPlaceIndex < _places.length) {
      _savePlaceDataFromControllers(_places[_selectedPlaceIndex]);
    }

    setState(() {
      _places.add(PlaceEntry());
      _selectedPlaceIndex = _places.length - 1;

      // Clear the editing controllers for the new place
      _placeNameController.clear();
      _placeTypeController.clear();
      _experienceController.clear();
      _locationSearchController.clear();
    });
  }

  void _removePlaceAt(int index) {
    if (_places.length <= 1) return; // Keep at least one place

    // Save current place data before removing (if it's not the one being removed)
    if (_selectedPlaceIndex >= 0 &&
        _selectedPlaceIndex < _places.length &&
        _selectedPlaceIndex != index) {
      _savePlaceDataFromControllers(_places[_selectedPlaceIndex]);
    }

    setState(() {
      _places.removeAt(index);
      if (_selectedPlaceIndex >= _places.length) {
        _selectedPlaceIndex = _places.length - 1;
      } else if (_selectedPlaceIndex > index) {
        // Adjust the selected index if we removed a place before it
        _selectedPlaceIndex = _selectedPlaceIndex - 1;
      }

      // Update controllers with the currently selected place's data
      if (_selectedPlaceIndex >= 0) {
        _loadPlaceDataIntoControllers(_places[_selectedPlaceIndex]);
      }
    });
  }

  void _selectPlace(int index) {
    if (index == _selectedPlaceIndex) return;

    // Save current edits before switching
    if (_selectedPlaceIndex >= 0 && _selectedPlaceIndex < _places.length) {
      _savePlaceDataFromControllers(_places[_selectedPlaceIndex]);
    }

    setState(() {
      _selectedPlaceIndex = index;
      if (index >= 0 && index < _places.length) {
        _loadPlaceDataIntoControllers(_places[index]);
      }
    });
  }

  void _loadPlaceDataIntoControllers(PlaceEntry place) {
    _placeNameController.text = place.placeName;
    _placeTypeController.text = place.placeType;
    _experienceController.text = place.experience;

    // Clear search field when switching between places to avoid confusion
    _locationSearchController.clear();
  }

  void _savePlaceDataFromControllers(PlaceEntry place) {
    place.placeName = _placeNameController.text;
    place.placeType = _placeTypeController.text;
    place.experience = _experienceController.text;
    // Note: latitude and longitude are already set when selecting a location
  }

  // Check if the guide is valid and can be submitted
  bool _isGuideValid() {
    // Save current place data before validation
    if (_selectedPlaceIndex >= 0 && _selectedPlaceIndex < _places.length) {
      _savePlaceDataFromControllers(_places[_selectedPlaceIndex]);
    }

    bool guideTitleValid = _guideNameController.text.isNotEmpty;
    bool citySelected = selectedCity != null &&
        (selectedCity != 'Other' ||
            (customCity != null && customCity!.isNotEmpty));
    bool hasPlaces = _places.isNotEmpty;
    bool allPlacesValid = _places.every((place) {
      bool placeNameValid = place.placeName.isNotEmpty;
      bool placeTypeValid = place.placeType.isNotEmpty;
      bool experienceValid = place.experience.isNotEmpty;
      bool hasMediaFiles = place.mediaFiles.isNotEmpty;

      print(
          'Place: ${place.placeName}, Name valid: $placeNameValid, Type valid: $placeTypeValid, Experience valid: $experienceValid, Has media: $hasMediaFiles');

      return placeNameValid &&
          placeTypeValid &&
          experienceValid &&
          hasMediaFiles;
    });

    print(
        'Guide validation - Title: $guideTitleValid, City: $citySelected, Has places: $hasPlaces, All places valid: $allPlacesValid');

    return guideTitleValid && citySelected && hasPlaces && allPlacesValid;
  }

  // Upload the guide
  Future<void> _uploadGuide() async {
    if (!_isGuideValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final guideProvider = Provider.of<GuideProvider>(context, listen: false);

      // Save the current place edits
      if (_selectedPlaceIndex >= 0) {
        _savePlaceDataFromControllers(_places[_selectedPlaceIndex]);
      } // Set guide metadata
      guideProvider.setTitle(_guideNameController.text);
      guideProvider.setDescription(_guideDescriptionController.text);

      // Use custom city if "Other" is selected, otherwise use selected city
      String finalCity = selectedCity == 'Other' ? customCity! : selectedCity!;
      guideProvider.setcity(finalCity);

      guideProvider.setTags(_tags);

      // Upload the main guide thumbnail if selected
      if (_mainThumbnail != null) {
        guideProvider.thumbnail = _mainThumbnail;
      }

      // Create guide posts for each place
      List<GuideModel> guidePosts = [];
      for (var place in _places) {
        if (!place.isValid) continue;

        // Prepare image uploads for this place
        List<File> mediaFiles = place.mediaFiles;

        // Create and add the guide post
        final GuideModel guidePost = GuideModel(
          id: const Uuid().v4(),
          userId: globalUser!.uid,
          postId: '', // This will be set by the createGuide method
          username: globalUser!.username,
          userProfileImage: globalUser!.profileImageUrl ?? '',
          place: place.placeType,
          placeName: place.placeName,
          experience: place.experience,
          mediaUrls: [], // Will be populated during upload
          createdAt: DateTime.now(),
          lat: place.latitude ?? 0.0,
          long: place.longitude ?? 0.0,
        );

        guidePosts.add(guidePost);

        // Set the images for upload
        guideProvider.setImages(mediaFiles, guidePosts.length - 1);
      }

      // Set the guide posts
      guideProvider.guidePosts = guidePosts;

      // Create the guide
      await guideProvider.createGuide(user: globalUser!);

      // After the guide is created, add tips if there are any
      if (_tips.isNotEmpty) {
        final guideId = guideProvider.lastCreatedGuideId;
        for (String tipText in _tips) {
          await guideProvider.addTipToGuide(guideId, tipText);
        }
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guide created successfully!')),
      );

      if (context.mounted) {
        final exploreProvider =
            Provider.of<ExploreProvider>(context, listen: false);
        final guideProvider =
            Provider.of<GuideProvider>(context, listen: false);
        final uploadProvider =
            Provider.of<UploadProvider>(context, listen: false);
        final profileProvider =
            Provider.of<ProfileProvider>(context, listen: false);

        exploreProvider.refreshGuides();

        if (globalUser?.uid != null) {
          guideProvider.refreshSavedGuides(globalUser!.uid, '');
          uploadProvider.refreshUserGuides(globalUser!.uid);
          profileProvider.fetchUserData(globalUser!.uid);
        }
      }

      context.go('/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload guide: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Show tip dialog
  void _showTipDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Travel Tip',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: TextField(
            controller: _tipController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter a helpful tip for travelers...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: Colors.orange.shade300, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _tipController.clear();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_tipController.text.trim().isNotEmpty) {
                  setState(() {
                    _tips.add(_tipController.text.trim());
                    _tipController.clear();
                  });
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Add Tip'),
            ),
          ],
        );
      },
    ).then((_) {
      // Dialog closed
    });
  }

  void _selectLocationFromSearch(PlaceModel place) {
    if (_selectedPlaceIndex >= 0 && _selectedPlaceIndex < _places.length) {
      final currentPlace = _places[_selectedPlaceIndex];

      // Update the current place with the selected location's information
      setState(() {
        // Update place information
        _placeNameController.text = place.name;
        currentPlace.placeName = place.name;
        currentPlace.latitude = place.latitude;
        currentPlace.longitude = place.longitude;

        // If place has types and place type field is empty, suggest the first type
        if (place.types.isNotEmpty && currentPlace.placeType.isEmpty) {
          _placeTypeController.text = place.types.first;
          currentPlace.placeType = place.types.first;
        }

        // Clear search field after selection to avoid confusion
        _locationSearchController.clear();
      });

      // Show confirmation snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location selected'),
                    Text(
                      '${place.name} (${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)})',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _clearLocationSelection() {
    if (_selectedPlaceIndex >= 0 && _selectedPlaceIndex < _places.length) {
      setState(() {
        final currentPlace = _places[_selectedPlaceIndex];

        // Clear location data
        currentPlace.latitude = null;
        currentPlace.longitude = null;

        // Clear the controllers but keep other data
        _placeNameController.clear();
        _locationSearchController.clear();

        // Keep place type and experience as they might be manually entered
        currentPlace.placeName = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Save current place data whenever state is rebuilt
    if (_selectedPlaceIndex >= 0 && _selectedPlaceIndex < _places.length) {
      _savePlaceDataFromControllers(_places[_selectedPlaceIndex]);
    }

    var states = stateCityData.keys.toList();
    states.sort();
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Use Future.microtask to avoid navigation conflicts
        await Future.microtask(() async {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Are you sure you want to exit?'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('No'),
                ),
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Yes'),
                ),
              ],
            ),
          );

          if (result == true) {
            if (context.mounted) {
              context.go('/home');
            }
          }
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'New Guide',
            style: TextStyle(
              fontSize: 18,
              fontWeight: fontregular,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Guide Thumbnail Section
              _buildGuideThumbnailSection(),

              const SizedBox(height: 20),

              // Guide Information Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Guide Title
                    _labelWidget('Guide Title'),
                    SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _guideNameController,
                        decoration: _getInputDecoration(
                            'Give your guide a catchy title...'),
                      ),
                    ),

                    // Guide Description
                    _labelWidget('Guide Description'),
                    SizedBox(
                      height: 100,
                      child: TextField(
                        controller: _guideDescriptionController,
                        decoration: _getInputDecoration(
                            'Provide a detailed description of your guide...'),
                        maxLines: 4,
                      ),
                    ),

                    // Guide Location
                    _labelWidget('State'),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xffE5E5E5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: DropdownButton<String>(
                          underline: const SizedBox(),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.black,
                            size: 20,
                          ),
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          value: selectedState,
                          hint: const Text(
                            'Choose a state',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: fontregular,
                              color: Colors.black,
                            ),
                          ),
                          items: states.map((String state) {
                            return DropdownMenuItem<String>(
                              value: state,
                              child: Text(state),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedState = value;
                              selectedCity = null;
                            });
                          },
                        ),
                      ),
                    ),

                    if (selectedState != null) ...[
                      _labelWidget('City'),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xffE5E5E5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: DropdownButton<String>(
                            underline: const SizedBox(),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.black,
                              size: 20,
                            ),
                            dropdownColor: Colors.white,
                            isExpanded: true,
                            value: selectedCity,
                            hint: const Text(
                              'Choose a city',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: fontregular,
                                color: Colors.black,
                              ),
                            ),
                            items: [
                              ...stateCityData[selectedState]!
                                  .map((String city) {
                                return DropdownMenuItem<String>(
                                  value: city,
                                  child: Text(city),
                                );
                              }).toList(),
                              const DropdownMenuItem<String>(
                                value: 'Other',
                                child: Text('Other'),
                              ),
                            ],
                            onChanged: (String? value) {
                              setState(() {
                                selectedCity = value;
                                if (value != 'Other') {
                                  customCity = null;
                                  _customCityController.clear();
                                }
                              });
                            },
                          ),
                        ),
                      ),

                      // Custom city input field
                      if (selectedCity == 'Other') ...[
                        _labelWidget('Enter Your City'),
                        SizedBox(
                          height: 44,
                          child: TextField(
                            controller: _customCityController,
                            decoration:
                                _getInputDecoration('Enter city name...'),
                            onChanged: (value) {
                              setState(() {
                                customCity = value.trim();
                              });
                            },
                          ),
                        ),
                      ],
                    ],

                    // Tags
                    _labelWidget('Tags (Optional)'),

                    // Tags description
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Add relevant tags to help travelers find your guide. Examples: #FreeWiFi #PaidParking #PetFriendly #BudgetTravel #Luxury #Photography #Adventure #Food #Culture #Historical',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: TextField(
                              controller: _tagsController,
                              decoration: _getInputDecoration(
                                      'e.g., FreeWiFi, PaidParking, BudgetTravel...')
                                  .copyWith(
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () =>
                                      _onTagAdded(_tagsController.text),
                                ),
                              ),
                              onSubmitted: _onTagAdded,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags
                            .map(
                              (e) => MarkChip(
                                label: e,
                                onTap: () {
                                  setState(() {
                                    _tags.remove(e);
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Places Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Places in this Guide',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addNewPlace,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Place'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff2563EB),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Places List
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _places.length,
                        itemBuilder: (context, index) {
                          final place = _places[index];
                          final bool isSelected = index == _selectedPlaceIndex;

                          return GestureDetector(
                            onTap: () => _selectPlace(index),
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xff2563EB)
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                children: [
                                  // Place thumbnail or placeholder
                                  Center(
                                    child: place.hasThumbnail
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Image.file(
                                              place.thumbnail,
                                              width: 76,
                                              height: 76,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.image,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                  ),

                                  // Place number badge
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: const Color(0xff2563EB),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Delete button
                                  if (_places.length > 1)
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: GestureDetector(
                                        onTap: () => _removePlaceAt(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Selected Place Edit Form
                    if (_selectedPlaceIndex >= 0) _buildPlaceEditForm(),

                    const SizedBox(height: 30),

                    // Tips Section
                    const Text(
                      'Add Travel Tips',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Add Tip Button with dotted border
                    InkWell(
                      onTap: () {
                        // Show the tip dialog
                        _showTipDialog();
                      },
                      child: DottedBorder(
                        color: Colors.blue.shade300,
                        strokeWidth: 1,
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(12),
                        dashPattern: const [6, 3],
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: Colors.blue.shade400),
                              const SizedBox(width: 8),
                              Text(
                                'Add a new tip',
                                style: TextStyle(
                                  color: Colors.blue.shade400,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Tips List
                    if (_tips.isNotEmpty)
                      Column(
                        children: _tips.map((tip) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 15),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    color: Colors.blue),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(Icons.close,
                                      color: Colors.blue.shade400),
                                  onPressed: () {
                                    setState(() {
                                      _tips.remove(tip);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.lightbulb_outline,
                                color: Colors.orange, size: 40),
                            SizedBox(height: 8),
                            Text(
                              'No tips added yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add tips to help other travelers',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 30), // Submit Button
                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Save the current place data first
                          if (_selectedPlaceIndex >= 0 &&
                              _selectedPlaceIndex < _places.length) {
                            _savePlaceDataFromControllers(
                                _places[_selectedPlaceIndex]);
                          }

                          // Now check if guide is valid
                          bool isValid = _isGuideValid();
                          if (!_isSubmitting && isValid) {
                            _uploadGuide();
                          } else if (!isValid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please fill in all required fields')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          // We'll always make the button enabled for better UX and show an error message if needed
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                'Upload Guide (${_places.length} place${_places.length > 1 ? "s" : ""})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: fontmedium,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Guide thumbnail section widget
  Widget _buildGuideThumbnailSection() {
    return Stack(
      children: [
        GestureDetector(
          onTap: _pickMainThumbnail,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
            ),
            child: _mainThumbnail != null
                ? Image.file(
                    _mainThumbnail!,
                    fit: BoxFit.cover,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Guide Cover Image',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      )
                    ],
                  ),
          ),
        ),
        if (_mainThumbnail != null)
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: _pickMainThumbnail,
              child: Container(
                height: 35,
                width: 35,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.edit,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Place edit form widget
  Widget _buildPlaceEditForm() {
    if (_selectedPlaceIndex < 0 || _selectedPlaceIndex >= _places.length) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editing Place #${_selectedPlaceIndex + 1}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15), // Location Search Field with Autocomplete
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search Location *',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Autocomplete<PlaceModel>(
                onSelected: (option) {
                  try {
                    debugPrint(
                        'Selected place: ${option.name}, ${option.latitude}, ${option.longitude}');
                    _selectLocationFromSearch(option);
                  } catch (e) {
                    debugPrint('Error selecting location: $e');
                  }
                },
                fieldViewBuilder: (context, textEditingController, focusNode,
                        onFieldSubmitted) =>
                    TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration:
                      _getInputDecoration('Search or select location').copyWith(
                          prefixIconConstraints: const BoxConstraints(
                            maxHeight: 16,
                            minWidth: 36,
                          ),
                          prefixIcon: Image.asset(
                            'assets/icon/pin.png',
                            width: 16,
                            color: const Color(0xff7B7B7B),
                          )),
                ),
                displayStringForOption: (option) =>
                    "${option.name}${option.city != null ? ', ${option.city}' : ''}",
                optionsBuilder: (textEditingValue) async {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable.empty();
                  } else {
                    try {
                      debugPrint('Searching for: ${textEditingValue.text}');
                      var query = textEditingValue.text.toLowerCase().trim();

                      if (query.length < 2) {
                        debugPrint('Query too short, not searching');
                        return const Iterable.empty();
                      }

                      // Primary search: Google Places API
                      debugPrint('Using Google Places API');

                      try {
                        final response = await Dio().get(
                          'https://maps.googleapis.com/maps/api/place/textsearch/json',
                          queryParameters: {
                            'query': query,
                            'key': Constant.GOOGLE_API,
                            'type': 'establishment',
                          },
                        );

                        if (response.statusCode == 200) {
                          final results =
                              response.data['results'] as List? ?? [];
                          debugPrint(
                              'Google Places results count: ${results.length}');

                          if (results.isNotEmpty) {
                            final places = <PlaceModel>[];

                            for (final result in results) {
                              try {
                                final geometry =
                                    result['geometry']?['location'];
                                if (geometry == null) continue;

                                final types = (result['types'] as List?)
                                        ?.map((t) => t.toString())
                                        .toList() ??
                                    [];

                                final rating =
                                    result['rating']?.toDouble() ?? 0.0;
                                final userRatingsTotal =
                                    result['user_ratings_total'] ?? 0;
                                final openNow = result['opening_hours']
                                        ?['open_now'] ??
                                    false;

                                places.add(PlaceModel(
                                  id: result['place_id'] ?? '',
                                  name: result['name'] ?? 'Unknown Place',
                                  city: result['formatted_address'] ?? '',
                                  rating: rating,
                                  userRatingsTotal: userRatingsTotal,
                                  openNow: openNow,
                                  latitude: geometry['lat']?.toDouble() ?? 0,
                                  longitude: geometry['lng']?.toDouble() ?? 0,
                                  types: types,
                                ));
                              } catch (e) {
                                debugPrint(
                                    'Error processing Google Places result: $e');
                              }
                            }

                            if (places.isNotEmpty) {
                              return places;
                            }
                          }
                        } else {
                          debugPrint(
                              'Google Places API error: ${response.statusMessage}');
                        }
                      } catch (e) {
                        debugPrint('Google Places API error: $e');
                      }

                      // Secondary search: Supabase for local results
                      debugPrint('Falling back to Supabase');
                      final data = await supabase
                          .from('places')
                          .select('*')
                          .ilike('name', '%$query%') // Case-insensitive search
                          .limit(10);

                      debugPrint('Supabase results count: ${data.length}');

                      if (data.isNotEmpty) {
                        return data.map((place) {
                          debugPrint(
                              'Supabase place: ${place['name']}, ${place['latitude']}, ${place['longitude']}');
                          return PlaceModel(
                            id: place['id'],
                            name: place['name'],
                            city: place['city'],
                            latitude: place['latitude'],
                            longitude: place['longitude'],
                            rating: 0.0,
                            userRatingsTotal: 0,
                            openNow: false,
                            types: [],
                          );
                        });
                      }

                      // Tertiary search: Foursquare (commented out)
                      /*
                      debugPrint('Falling back to Foursquare API');
                      debugPrint(
                          'Using API key: ${Constant.FOURSQUARE_API_KEY}');

                      final response = await Dio().get(
                        'https://api.foursquare.com/v3/places/search',
                        queryParameters: {
                          'query': query,
                          'limit': 10,
                        },
                        options: Options(
                          headers: {
                            'Authorization': Constant.FOURSQUARE_API_KEY,
                            'accept': 'application/json',
                          },
                        ),
                      );

                      if (response.statusCode == 200) {
                        final results = response.data['results'] as List? ?? [];
                        debugPrint(
                            'Foursquare results count: ${results.length}');

                        final places = <PlaceModel>[];

                        for (final result in results) {
                          try {
                            final geocodes = result['geocodes']?['main'];
                            if (geocodes == null) continue;

                            final locationData = result['location'];
                            String? cityText;
                            final formattedAddress =
                                locationData?['formatted_address'];
                            final locality = locationData?['locality'];
                            final region = locationData?['region'];

                            if (formattedAddress != null &&
                                formattedAddress.isNotEmpty) {
                              cityText = formattedAddress;
                            } else if (locality != null) {
                              cityText =
                                  '$locality${region != null ? ", $region" : ""}';
                            }

                            final categories = (result['categories'] as List?)
                                    ?.map((c) => c['name'].toString())
                                    .toList() ??
                                [];

                            places.add(PlaceModel(
                              id: result['fsq_id'] ?? '',
                              name: result['name'] ?? 'Unknown Place',
                              city: cityText,
                              rating: 0.0,
                              userRatingsTotal: 0,
                              openNow: false,
                              latitude: geocodes['latitude'] ?? 0,
                              longitude: geocodes['longitude'] ?? 0,
                              types: categories,
                            ));
                          } catch (e) {
                            debugPrint(
                                'Error processing Foursquare result: $e');
                          }
                        }

                        return places;
                      } else {
                        debugPrint(
                            'Foursquare API error: ${response.statusMessage}');
                        return const Iterable.empty();
                      }
                      */

                      return const Iterable.empty();
                    } catch (e) {
                      debugPrint('Search error: $e');
                      return const Iterable.empty();
                    }
                  }
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              leading: Container(
                                height: 36,
                                width: 36,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                              ),
                              title: Text(option.name),
                              subtitle: Text(option.city ?? ''),
                              onTap: () {
                                onSelected(option);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(
              height: 15), // Place Name (Readonly if selected from search)
          TextField(
            controller: _placeNameController,
            decoration: _getInputDecoration('Place Name *').copyWith(
              hintText: 'Automatically filled from location search',
              suffixIcon: _selectedPlaceIndex >= 0 &&
                      _selectedPlaceIndex < _places.length &&
                      _places[_selectedPlaceIndex].latitude != null &&
                      _places[_selectedPlaceIndex].longitude != null
                  ? const Icon(Icons.location_on, color: Colors.green)
                  : const Icon(Icons.location_off, color: Colors.grey),
            ),
            readOnly: true,
          ),

          // Location information display
          if (_selectedPlaceIndex >= 0 &&
              _selectedPlaceIndex < _places.length &&
              _places[_selectedPlaceIndex].latitude != null &&
              _places[_selectedPlaceIndex].longitude != null)
            Container(
              margin: const EdgeInsets.only(top: 8.0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Location coordinates available',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.green[800],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearLocationSelection,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Latitude: ${_places[_selectedPlaceIndex].latitude!.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Longitude: ${_places[_selectedPlaceIndex].longitude!.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap × to clear and reselect location',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 15),

          // Place Type
          TextField(
            controller: _placeTypeController,
            decoration:
                _getInputDecoration('Place Type (e.g., Restaurant, Museum) *'),
          ),

          const SizedBox(height: 15),

          // Experience
          TextField(
            controller: _experienceController,
            decoration: _getInputDecoration('Your Experience *'),
            maxLines: 3,
          ),

          const SizedBox(height: 15), // Media Selection
          Text(
            'Media (${_places[_selectedPlaceIndex].mediaFiles.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          // Media Gallery
          if (_places[_selectedPlaceIndex].mediaFiles.isEmpty)
            GestureDetector(
              onTap: () => _pickImages(_places[_selectedPlaceIndex]),
              child: DottedBorder(
                borderType: BorderType.RRect,
                radius: const Radius.circular(10),
                dashPattern: const [8, 4],
                color: Colors.grey.shade500,
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 32,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Photos/Videos',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _places[_selectedPlaceIndex].mediaFiles.length +
                        1, // +1 for add button
                    itemBuilder: (context, index) {
                      if (index ==
                          _places[_selectedPlaceIndex].mediaFiles.length) {
                        // Add more button
                        return GestureDetector(
                          onTap: () =>
                              _pickImages(_places[_selectedPlaceIndex]),
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(Icons.add, size: 32),
                            ),
                          ),
                        );
                      }

                      final mediaFile =
                          _places[_selectedPlaceIndex].mediaFiles[index];
                      final isSelected =
                          _places[_selectedPlaceIndex].thumbnailFile ==
                              mediaFile;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _places[_selectedPlaceIndex].thumbnailFile =
                                mediaFile;
                          });
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 100,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                border: isSelected
                                    ? Border.all(
                                        color: const Color(0xff2563EB),
                                        width: 3)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  mediaFile,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 15,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_places[_selectedPlaceIndex]
                                            .thumbnailFile ==
                                        mediaFile) {
                                      _places[_selectedPlaceIndex]
                                          .thumbnailFile = null;
                                    }
                                    _places[_selectedPlaceIndex]
                                        .mediaFiles
                                        .removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                bottom: 5,
                                left: 5,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xff2563EB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Helper text
                if (_places[_selectedPlaceIndex].hasThumbnail)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Tap on an image to set it as the thumbnail',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
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
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: const Icon(
              Icons.close,
              color: Colors.orange,
              size: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }
}
