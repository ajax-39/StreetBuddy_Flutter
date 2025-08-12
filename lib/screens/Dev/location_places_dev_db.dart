import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/models/place.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:street_buddy/utils/url_util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationPlacesDevDB extends StatefulWidget {
  const LocationPlacesDevDB({super.key});

  @override
  State<LocationPlacesDevDB> createState() => _LocationPlacesDevDBState();
}

class _LocationPlacesDevDBState extends State<LocationPlacesDevDB>
    with TickerProviderStateMixin {
  // Initialize Supabase client
  final supabase = Supabase.instance.client;

  // Add constant for default image
  static const String DEFAULT_PLACE_IMAGE = 'assets/default_city.jpg';

  // Add days of week constant
  static final List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  // Add time controller helper
  final Map<String, Map<String, TextEditingController>> _timeControllers = {};

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final _imagePicker = ImagePicker();

  final Map<String, List<String>> _typeCategories = {
    'restaurants': [
      'restaurant',
      'cafe',
      'bar',
      'bakery',
      'food',
      'meal_delivery',
      'meal_takeaway'
    ],
    'attractions': [
      'museum',
      'park',
      'zoo',
      'tourist_attraction',
      'art_gallery',
      'amusement_park',
      'aquarium'
    ],
    'transport': [
      'bus_station',
      'train_station',
      'subway_station',
      'airport',
      'taxi_stand',
      'car_rental'
    ],
    'hotels': ['lodging', 'hotel', 'motel', 'resort', 'hostel'],
  };

  // Add this property to the state class
  List<String> _uploadedImageUrls = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editLocation(LocationModel location) async {
    final controllers = {
      'id': TextEditingController(text: location.id),
      'name': TextEditingController(text: location.name),
      'description': TextEditingController(text: location.description),
      'latitude': TextEditingController(text: location.latitude.toString()),
      'longitude': TextEditingController(text: location.longitude.toString()),
      'rating': TextEditingController(text: location.rating.toString()),
    };

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controllers['id']!,
                decoration: const InputDecoration(labelText: 'ID'),
                readOnly: true,
                enabled: false,
              ),
              ...controllers.entries
                  .where((e) => e.key != 'id')
                  .map((entry) => TextField(
                        controller: entry.value,
                        decoration:
                            InputDecoration(labelText: entry.key.toUpperCase()),
                        keyboardType: entry.key.contains('latitude') ||
                                entry.key.contains('longitude') ||
                                entry.key.contains('rating')
                            ? TextInputType.number
                            : TextInputType.text,
                      )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await supabase.from('locations').update({
                  'name': controllers['name']!.text,
                  'name_lowercase': controllers['name']!.text.toLowerCase(),
                  'description': controllers['description']!.text,
                  'latitude':
                      double.tryParse(controllers['latitude']!.text) ?? 0.0,
                  'longitude':
                      double.tryParse(controllers['longitude']!.text) ?? 0.0,
                  'rating': double.tryParse(controllers['rating']!.text) ?? 0.0,
                  'updated_at': DateTime.now().toIso8601String(),
                }).eq('id', location.id);

                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              } catch (e) {
                print('Error updating location: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update location')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSelectButton(String label, List<String> days) {
    return ElevatedButton(
      child: Text(label),
      onPressed: () => _showQuickSelectTimeDialog(days),
    );
  }

  Future<void> _showQuickSelectTimeDialog(List<String> days) async {
    final openController = TextEditingController();
    final closeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Hours'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: openController,
              decoration: const InputDecoration(
                labelText: 'Open Time (HH:mm)',
                hintText: '09:00',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: closeController,
              decoration: const InputDecoration(
                labelText: 'Close Time (HH:mm)',
                hintText: '17:00',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Apply'),
            onPressed: () {
              for (var day in days) {
                _timeControllers[day]!['open']!.text = openController.text;
                _timeControllers[day]!['close']!.text = closeController.text;
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOpeningHoursFields() {
    return ExpansionTile(
      title: const Text('Opening Hours'),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Quick select buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickSelectButton(
                        'Weekdays', OpeningHoursHelper.WEEKDAYS),
                    const SizedBox(width: 8),
                    _buildQuickSelectButton(
                        'Weekend', OpeningHoursHelper.WEEKEND),
                    const SizedBox(width: 8),
                    _buildQuickSelectButton(
                        'All Days', OpeningHoursHelper.ALL_DAYS),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Bulk time application
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration:
                          const InputDecoration(labelText: 'Open Time (HH:mm)'),
                      controller: TextEditingController(),
                      onChanged: (value) => _applyBulkTime('open', value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                          labelText: 'Close Time (HH:mm)'),
                      controller: TextEditingController(),
                      onChanged: (value) => _applyBulkTime('close', value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Individual day controls
              ...OpeningHoursHelper.ALL_DAYS.map((day) {
                if (!_timeControllers.containsKey(day)) {
                  _timeControllers[day] = {
                    'open': TextEditingController(),
                    'close': TextEditingController(),
                  };
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(day),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _timeControllers[day]!['open'],
                            decoration: const InputDecoration(
                              labelText: 'Open',
                              hintText: 'HH:mm',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _timeControllers[day]!['close'],
                            decoration: const InputDecoration(
                              labelText: 'Close',
                              hintText: 'HH:mm',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editPlace(PlaceModel place) async {
    final controllers = {
      'id': TextEditingController(text: place.id),
      'name': TextEditingController(text: place.name),
      'vicinity': TextEditingController(text: place.vicinity ?? ''),
      'description': TextEditingController(text: place.description ?? ''),
      'rating': TextEditingController(text: place.rating.toString()),
      'customRating':
          TextEditingController(text: place.customRating.toString()),
      'latitude': TextEditingController(text: place.latitude.toString()),
      'longitude': TextEditingController(text: place.longitude.toString()),
      'phoneNumber': TextEditingController(text: place.phoneNumber ?? ''),
      'minPrice': TextEditingController(
          text: place.priceRange?.minPrice.toString() ?? '0'),
      'maxPrice': TextEditingController(
          text: place.priceRange?.maxPrice.toString() ?? '0'),
      'tips': TextEditingController(text: place.tips ?? ''),
      'extras': TextEditingController(text: place.extras ?? ''),
      'city': TextEditingController(text: place.city ?? ''),
      'state': TextEditingController(text: place.state ?? ''),
    };

    // Initialize time controllers with existing data
    _timeControllers.clear();
    place.openingHours.forEach((day, time) {
      final times = time.split('-');
      _timeControllers[day] = {
        'open': TextEditingController(text: times[0]),
        'close': TextEditingController(text: times[1]),
      };
    });

    bool isHiddenGem = place.isHiddenGem;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Place'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controllers['id']!,
                  decoration: const InputDecoration(labelText: 'ID'),
                  readOnly: true,
                  enabled: false,
                ),
                ...controllers.entries
                    .where((e) => e.key != 'id')
                    .map((entry) => TextField(
                          controller: entry.value,
                          decoration: InputDecoration(
                              labelText: entry.key.toUpperCase()),
                          keyboardType: entry.key.contains('latitude') ||
                                  entry.key.contains('longitude') ||
                                  entry.key.contains('rating')
                              ? TextInputType.number
                              : TextInputType.text,
                        )),
                SwitchListTile(
                  title: const Text('Hidden Gem'),
                  value: isHiddenGem,
                  onChanged: (value) {
                    setState(() {
                      isHiddenGem = value;
                    });
                  },
                ),
                _buildOpeningHoursFields(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  Map<String, String> openingHours = {};
                  _timeControllers.forEach((day, controllers) {
                    final open = controllers['open']!.text;
                    final close = controllers['close']!.text;
                    if (open.isNotEmpty && close.isNotEmpty) {
                      openingHours[day] = '$open-$close';
                    }
                  });

                  final updateData = {
                    'name': controllers['name']!.text,
                    'name_lowercase': controllers['name']!.text.toLowerCase(),
                    'vicinity': controllers['vicinity']!.text,
                    'description': controllers['description']!.text,
                    'rating':
                        double.tryParse(controllers['rating']!.text) ?? 0.0,
                    'custom_rating':
                        double.tryParse(controllers['customRating']!.text) ??
                            0.0,
                    'latitude':
                        double.tryParse(controllers['latitude']!.text) ?? 0.0,
                    'longitude':
                        double.tryParse(controllers['longitude']!.text) ?? 0.0,
                    'phone_number': controllers['phoneNumber']!.text,
                    'opening_hours': openingHours,
                    'price_range': {
                      'minPrice':
                          int.tryParse(controllers['minPrice']!.text) ?? 0,
                      'maxPrice':
                          int.tryParse(controllers['maxPrice']!.text) ?? 0,
                    },
                    'is_hidden_gem': isHiddenGem,
                    'tips': controllers['tips']!.text,
                    'extras': controllers['extras']!.text,
                    'cached_at': DateTime.now().toIso8601String(),
                    'city': controllers['city']!.text,
                    'state': controllers['state']!.text,
                  };

                  await supabase
                      .from('places')
                      .update(updateData)
                      .eq('id', place.id)
                      .select()
                      .single();

                  if (mounted) {
                    Navigator.pop(context);
                    setState(() {});
                  }
                } catch (e) {
                  print('Error updating place: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update place')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage(String collection, String customId) async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return null;

      final String fileName =
          '${customId}_${DateTime.now().millisecondsSinceEpoch}';
      final String path = '$collection/$fileName'; // Simplified path structure

      // Upload to Supabase Storage
      final file = File(image.path);
      await supabase.storage
          .from('places-images') // Always use 'places-images' bucket
          .upload(path, file);

      // Get public URL
      final String publicUrl =
          supabase.storage.from('places-images').getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      print(
          'Stack trace: ${StackTrace.current}'); // Add stack trace for debugging
      return null;
    }
  }

  Future<String?> _uploadLocationImage(File imageFile, String customId) async {
    try {
      // Create a unique file path using the location ID and timestamp
      final String fileName =
          '${customId}_${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';
      final String path = 'locations/$fileName';

      // Use the specifically created bucket for locations
      const String locationBucket = 'location-images';

      print('Attempting to upload to bucket: $locationBucket, path: $path');

      // Get current user info for debugging (if using auth)
      final Session? session = supabase.auth.currentSession;
      final bool isAuthenticated = session != null;
      print('User authenticated: $isAuthenticated');
      if (isAuthenticated) {
        print('User ID: ${session.user.id}');
      }

      // Upload the image to the location-images bucket
      await supabase.storage.from(locationBucket).upload(path, imageFile);

      // Get the public URL correctly formatted
      final String publicUrl =
          supabase.storage.from(locationBucket).getPublicUrl(path);

      // Fix for URL formatting if needed
      String fixedUrl = publicUrl;

      // Optional: Add transformation parameters for image optimization
      // For example, you might want to add width or quality parameters
      // fixedUrl = '$publicUrl?width=800&quality=80';

      print('Image uploaded successfully to $locationBucket: $fixedUrl');
      return fixedUrl;
    } catch (e) {
      print('Error uploading location image: $e');
      print('Stack trace: ${StackTrace.current}');

      // Show more detailed error for debugging
      if (e is StorageException) {
        print('Storage error code: ${e.statusCode}, message: ${e.message}');

        // Handle specific error codes
        if (e.statusCode == 403) {
          print(
              'Permission denied. Check Row Level Security (RLS) policies for the bucket.');
        }
      }

      return null;
    }
  }

// Add this method to your URL utility class
  static String fixSupabaseImageUrl(String url) {
    // If the URL is already correctly formatted, return it
    if (url.contains('/storage/v1/object/public/')) {
      return url;
    }

    // Parse the URL to extract the necessary components
    final Uri uri = Uri.parse(url);
    final baseUrl = uri.origin;

    // Extract bucket name and path from the original URL
    // This may need adjustment based on your exact URL format
    final pathParts = uri.path.split('/');
    final bucketIndex = pathParts.indexOf('public');

    if (bucketIndex >= 0 && bucketIndex < pathParts.length - 1) {
      final bucket = pathParts[bucketIndex + 1];
      final objectPath = pathParts.sublist(bucketIndex + 2).join('/');

      return '$baseUrl/storage/v1/object/public/$bucket/$objectPath';
    }

    // If we can't parse it properly, return the original URL
    return url;
  }

  // Update the _generateCustomId method
  Future<String> _generateCustomId(String collection,
      {required String prefix}) async {
    String customId = '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
    bool isDuplicate = true;

    while (isDuplicate) {
      customId = '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
      final response =
          await supabase.from(collection).select('id').eq('id', customId);

      isDuplicate = (response as List).isNotEmpty;
    }
    return customId;
  }

  Future<void> _addLocation() async {
    final customId = await _generateCustomId('locations', prefix: 'lcustom');
    _uploadedImageUrls = []; // Reset the list

    final controllers = {
      'name': TextEditingController(),
      'description': TextEditingController(),
      'latitude': TextEditingController(),
      'longitude': TextEditingController(),
      'rating': TextEditingController(),
    };

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Location'),
          content: SizedBox(
            // Add a fixed size container
            width: 400, // Set reasonable fixed width
            height: 500, // Set reasonable fixed height
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.stretch, // Better alignment
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final XFile? image = await _imagePicker.pickImage(
                            source: ImageSource.gallery);
                        if (image != null) {
                          final File imageFile = File(image.path);
                          final imageUrl =
                              await _uploadLocationImage(imageFile, customId);
                          if (imageUrl != null) {
                            setState(() {
                              _uploadedImageUrls.add(imageUrl);
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Failed to upload image. Check console for details.')),
                            );
                          }
                        }
                      } catch (e) {
                        print('Error selecting/uploading image: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    },
                    child:
                        Text('Upload Image (${_uploadedImageUrls.length}/3)'),
                  ),
                  if (_uploadedImageUrls.isNotEmpty)
                    ConstrainedBox(
                      // Use ConstrainedBox instead of SizedBox
                      constraints: BoxConstraints(
                        maxHeight: 120, // Maximum height
                        minHeight: 100, // Minimum height
                      ),
                      child: ListView.builder(
                        shrinkWrap: true, // Important property to fix the error
                        physics:
                            const ClampingScrollPhysics(), // To prevent nested scrolling issues
                        scrollDirection: Axis.horizontal,
                        itemCount: _uploadedImageUrls.length,
                        itemBuilder: (context, index) => Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                fixSupabaseImageUrl(_uploadedImageUrls[index]),
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setState(() {
                                  _uploadedImageUrls.removeAt(index);
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16), // Add spacing
                  ...controllers.entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: 8.0), // Add padding between fields
                        child: TextField(
                          controller: entry.value,
                          decoration: InputDecoration(
                              labelText: entry.key.toUpperCase()),
                          keyboardType: entry.key.contains('latitude') ||
                                  entry.key.contains('longitude') ||
                                  entry.key.contains('rating')
                              ? TextInputType.number
                              : TextInputType.text,
                        ),
                      )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _uploadedImageUrls.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Validate required fields
                  if (controllers['name']!.text.isEmpty ||
                      controllers['latitude']!.text.isEmpty ||
                      controllers['longitude']!.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Name, latitude, and longitude are required')),
                    );
                    return;
                  }

                  // Create location data object
                  final locationData = {
                    'id': customId,
                    'name': controllers['name']!.text,
                    'name_lowercase': controllers['name']!.text.toLowerCase(),
                    'image_urls': _uploadedImageUrls,
                    'description': controllers['description']!.text,
                    'latitude':
                        double.tryParse(controllers['latitude']!.text) ?? 0.0,
                    'longitude':
                        double.tryParse(controllers['longitude']!.text) ?? 0.0,
                    'rating':
                        double.tryParse(controllers['rating']!.text) ?? 0.0,
                    'cached_at': DateTime.now().toIso8601String(),
                  };

                  // Insert location into database
                  await supabase.from('locations').insert(locationData);

                  _uploadedImageUrls.clear();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Location added successfully')),
                  );
                } catch (e) {
                  print('Error adding location: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Error adding location: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPlace() async {
    try {
      String? imageUrl;
      final customId = await _generateCustomId('places', prefix: 'pcustom');
      String selectedCategory = _typeCategories.keys.first;
      String selectedType = _typeCategories[selectedCategory]!.first;
      bool isHiddenGem = false;

      final controllers = {
        'name': TextEditingController(),
        'vicinity': TextEditingController(),
        'description': TextEditingController(),
        'rating': TextEditingController(),
        'customRating': TextEditingController(),
        'latitude': TextEditingController(),
        'longitude': TextEditingController(),
        'phoneNumber': TextEditingController(),
        'minPrice': TextEditingController(),
        'maxPrice': TextEditingController(),
        'city': TextEditingController(),
        'state': TextEditingController(),
        'tips': TextEditingController(),
        'extras': TextEditingController(),
      };

      // Clear previous time controllers
      _timeControllers.clear();

      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add Place'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      imageUrl = await _uploadImage('places', customId);
                      setState(() {});
                    },
                    child: const Text('Upload Image'),
                  ),
                  if (imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.network(imageUrl!, height: 100),
                    ),
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'CATEGORY'),
                    items: _typeCategories.keys.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                        selectedType = _typeCategories[value]!.first;
                      });
                    },
                  ),
                  // Type Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'TYPE'),
                    items: _typeCategories[selectedCategory]!.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  ...controllers.entries.map((entry) => TextField(
                        controller: entry.value,
                        decoration:
                            InputDecoration(labelText: entry.key.toUpperCase()),
                        keyboardType: entry.key.contains('latitude') ||
                                entry.key.contains('longitude') ||
                                entry.key.contains('rating') ||
                                entry.key.contains('customRating')
                            ? TextInputType.number
                            : TextInputType.text,
                      )),
                  SwitchListTile(
                    title: const Text('Hidden Gem'),
                    value: isHiddenGem,
                    onChanged: (value) {
                      setState(() {
                        isHiddenGem = value;
                      });
                    },
                  ),
                  _buildOpeningHoursFields(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    Map<String, String> openingHours = {};
                    _timeControllers.forEach((day, controllers) {
                      final open = controllers['open']!.text;
                      final close = controllers['close']!.text;
                      if (open.isNotEmpty && close.isNotEmpty) {
                        openingHours[day] = '$open-$close';
                      }
                    });

                    // Validate required fields
                    if (controllers['name']!.text.isEmpty ||
                        controllers['latitude']!.text.isEmpty ||
                        controllers['longitude']!.text.isEmpty) {
                      throw Exception(
                          'Name, latitude and longitude are required');
                    }

                    final placeData = {
                      'id': customId,
                      'name': controllers['name']!.text,
                      'name_lowercase': controllers['name']!.text.toLowerCase(),
                      'vicinity': controllers['vicinity']!.text,
                      'description': controllers['description']!.text,
                      'rating':
                          double.tryParse(controllers['rating']!.text) ?? 0.0,
                      'custom_rating':
                          double.tryParse(controllers['customRating']!.text) ??
                              0.0,
                      'latitude':
                          double.tryParse(controllers['latitude']!.text) ?? 0.0,
                      'longitude':
                          double.tryParse(controllers['longitude']!.text) ??
                              0.0,
                      'media_urls': imageUrl != null ? [imageUrl] : [],
                      'types': [selectedType, selectedCategory],
                      'phone_number': controllers['phoneNumber']!.text,
                      'price_range': {
                        'minPrice':
                            int.tryParse(controllers['minPrice']!.text) ?? 0,
                        'maxPrice':
                            int.tryParse(controllers['maxPrice']!.text) ?? 0,
                      },
                      'opening_hours': openingHours,
                      'is_hidden_gem': isHiddenGem,
                      'cached_at': DateTime.now().toIso8601String(),
                      'city': controllers['city']!.text,
                      'state': controllers['state']!.text,
                      'tips': controllers['tips']!.text,
                      'extras': controllers['extras']!.text,
                    };

                    final response = await supabase
                        .from('places')
                        .insert(placeData)
                        .select();

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Place added successfully')),
                      );
                    }
                  } catch (e) {
                    print('Error adding place: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Error adding place: ${e.toString()}')),
                      );
                    }
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error in _addPlace: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
  // Add opening hours widget

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Database Manager'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              TabBar(
                dividerHeight: 1,
                dividerColor: Colors.grey[300],
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Locations'),
                  Tab(text: 'Places'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: [
          // Locations Tab
          _buildLocationsTab(),
          // Places Tab
          _buildPlacesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          if (_tabController.index == 0) {
            _addLocation();
          } else {
            _addPlace();
          }
        },
      ),
    );
  }

  // Update the DataTable column and cell in _buildLocationsTab()
  Widget _buildLocationsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('locations')
          .stream(primaryKey: ['id']).order('cached_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        var locations = snapshot.data!
            .map((data) => LocationModel.fromJson(data))
            .where((location) => location.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Image URLs')), // Updated column name
                DataColumn(label: Text('Latitude')),
                DataColumn(label: Text('Longitude')),
                DataColumn(label: Text('Rating')),
                DataColumn(label: Text('Actions')),
              ],
              rows: locations
                  .map((location) => DataRow(
                        cells: [
                          DataCell(Text(location.id)),
                          DataCell(Text(location.name)),
                          DataCell(Text(location.description)),
                          DataCell(
                            SizedBox(
                              width: 200, // Set a fixed width for the cell
                              child: Text(
                                location.imageUrls.join('\n'),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 3,
                              ),
                            ),
                          ),
                          DataCell(Text(location.latitude.toString())),
                          DataCell(Text(location.longitude.toString())),
                          DataCell(Text(location.rating.toString())),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editLocation(location),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => supabase
                                    .from('locations')
                                    .delete()
                                    .eq('id', location.id),
                              ),
                            ],
                          )),
                        ],
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlacesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('places')
          .stream(primaryKey: ['id']).order('cached_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        var places = snapshot.data!
            .map((data) {
              if (data['rating'] is int) {
                data['rating'] = (data['rating'] as int).toDouble();
              }
              if (data['custom_rating'] is int) {
                data['custom_rating'] =
                    (data['custom_rating'] as int).toDouble();
              }
              if (data['latitude'] is int) {
                data['latitude'] = (data['latitude'] as int).toDouble();
              }
              if (data['longitude'] is int) {
                data['longitude'] = (data['longitude'] as int).toDouble();
              }
              return PlaceModel.fromJson(data);
            })
            .where((place) =>
                place.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Vicinity')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('City')),
                DataColumn(label: Text('State')),
                DataColumn(label: Text('Latitude')),
                DataColumn(label: Text('Longitude')),
                DataColumn(label: Text('Rating')),
                DataColumn(label: Text('Custom Rating')),
                DataColumn(label: Text('Photo')),
                DataColumn(label: Text('Types')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Price Range')),
                DataColumn(label: Text('Tips')),
                DataColumn(label: Text('Extras')),
                DataColumn(label: Text('Opening Hours')),
                DataColumn(label: Text('Hidden Gem')),
                DataColumn(label: Text('Actions')),
              ],
              rows: places
                  .map((place) => DataRow(cells: [
                        DataCell(Text(place.id)),
                        DataCell(Text(place.name)),
                        DataCell(Text(place.vicinity ?? '')),
                        DataCell(Text(place.description ?? '')),
                        DataCell(Text(place.city ?? '')),
                        DataCell(Text(place.state ?? '')),
                        DataCell(Text(place.latitude.toString())),
                        DataCell(Text(place.longitude.toString())),
                        DataCell(Text(place.rating.toString())),
                        DataCell(Text(place.customRating.toString())),
                        DataCell(_buildPhotoCell(place)),
                        DataCell(Text(place.types.join(', '))),
                        DataCell(Text(place.phoneNumber ?? '')),
                        DataCell(Text(place.priceRange != null
                            ? '₹${place.priceRange!.minPrice}-${place.priceRange!.maxPrice}'
                            : 'N/A')),
                        DataCell(Text(place.tips ?? '')),
                        DataCell(Text(place.extras ?? '')),
                        DataCell(Text(place.openingHours.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .join('\n'))),
                        DataCell(Switch(
                          value: place.isHiddenGem,
                          onChanged: (value) async {
                            await supabase.from('places').update(
                                {'is_hidden_gem': value}).eq('id', place.id);
                          },
                        )),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editPlace(place),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                // Show confirmation dialog
                                final confirmDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Place'),
                                    content: Text(
                                        'Are you sure you want to delete "${place.name}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                            foregroundColor: Colors.red),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                // If user confirmed deletion
                                if (confirmDelete == true) {
                                  try {
                                    // Show loading indicator
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Deleting place...'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );

                                    // Execute delete operation and wait for completion
                                    await supabase
                                        .from('places')
                                        .delete()
                                        .eq('id', place.id);

                                    if (mounted) {
                                      // Show success message
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Place deleted successfully')),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      // Show error message
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Error deleting place: ${e.toString()}')),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        )),
                      ]))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoCell(PlaceModel place) {
    return Stack(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              place.photoUrl ?? DEFAULT_PLACE_IMAGE,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.upload, size: 20),
                onPressed: () async {
                  final XFile? image =
                      await _imagePicker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    final newUrl =
                        await _uploadPlaceImage(place, File(image.path));
                    if (newUrl != null) {
                      await supabase.from('places').update({
                        'media_urls': [newUrl]
                      }).eq('id', place.id);
                      setState(() {});
                    }
                  }
                },
              ),
              if (place.photoUrl != Constant.DEFAULT_PLACE_IMAGE)
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () async {
                    // Add delete functionality here
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Add new method for image handling
  Future<String> _uploadPlaceImage(PlaceModel place, File imageFile) async {
    try {
      final String cityFolder =
          place.city?.replaceAll(' ', '_').toLowerCase() ?? 'unknown_city';
      final String typeFolder =
          place.types.first.replaceAll(' ', '_').toLowerCase();
      final String placeFolder = place.name.replaceAll(' ', '_').toLowerCase();
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';

      final String path =
          'places/$cityFolder/$typeFolder/$placeFolder/$fileName';

      // Upload to Supabase Storage using the correct bucket name
      await supabase.storage
          .from('places-images') // Use the correct bucket name
          .upload(path, imageFile);

      // Get public URL from the correct bucket
      final String publicUrl =
          supabase.storage.from('places-images').getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return DEFAULT_PLACE_IMAGE; // Return default image URL on error
    }
  }

  void _applyBulkTime(String type, String value) {
    _timeControllers.forEach((day, controllers) {
      controllers[type]!.text = value;
    });
  }
}

class OpeningHoursHelper {
  static const WEEKDAYS = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday'
  ];
  static const WEEKEND = ['Saturday', 'Sunday'];
  static const ALL_DAYS = [...WEEKDAYS, ...WEEKEND];
}
