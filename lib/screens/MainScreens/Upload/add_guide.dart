import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/provider/Auth/auth_provider.dart';
import 'package:street_buddy/provider/MainScreen/guide_provider.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/provider/MainScreen/upload_provider.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/services/auth_sync_service.dart';
import 'package:street_buddy/utils/indianStatesCities.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/crop_image_screen.dart';
import 'package:street_buddy/widgets/file_video_player.dart';

class AddGuideScreen extends StatefulWidget {
  const AddGuideScreen({super.key});

  @override
  State<AddGuideScreen> createState() => _AddGuideScreenState();
}

class _AddGuideScreenState extends State<AddGuideScreen> {
  final List<Widget> _mediaList = [];
  final List<File> path = [];
  List<File> selectedFiles = [];
  File? _file;
  int currentPage = 0;
  int? lastPage;

  // Add pagination variables
  static const int itemsPerPage = 30;
  bool _hasMoreItems = true;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  _fetchNewMedia() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      List<AssetPathEntity> albums =
          await PhotoManager.getAssetPathList(type: RequestType.common);

      // Get paginated assets
      List<AssetEntity> media = await albums[0].getAssetListPaged(
        page: currentPage,
        size: itemsPerPage,
      );

      if (media.isEmpty) {
        setState(() {
          _hasMoreItems = false;
          _isLoading = false;
        });
        return;
      }

      // Process media files
      for (var asset in media) {
        final file = await asset.file;
        if (file != null) {
          path.add(File(file.path));
          if (_file == null) {
            _file = path[0];
          }
        }
      }

      // Create thumbnail widgets
      List<Widget> temp = [];
      for (var asset in media) {
        temp.add(
          FutureBuilder(
            future: asset.thumbnailDataWithSize(const ThumbnailSize(500, 500)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                );
              }
              return Container();
            },
          ),
        );
      }

      setState(() {
        _mediaList.addAll(temp);
        currentPage++;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickMedia(
      BuildContext context, ImageSource source, bool isVideo) async {
    final picker = ImagePicker();
    try {
      final XFile? media = isVideo
          ? await picker.pickVideo(source: source)
          : await picker.pickImage(source: source);

      if (media != null) {
        File resultimagefile;

        if (!isVideo) {
          File? img = File(media.path);
          // img = await _cropImage(imageFile: img);
          resultimagefile = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CropImageScreen(image: img),
              ));
        } else {
          resultimagefile = File(media.path);
        }
        Provider.of<GuideProvider>(context, listen: false)
            .setImages([resultimagefile], 0);
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FillHolder(),
            ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking media: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchNewMedia();

    // Add scroll listener
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        if (!_isLoading && _hasMoreItems) {
          _fetchNewMedia();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int indexx = 0;
  bool multimode = false;
  List<Widget> selectedmedialist = [];

  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        // backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'New City Guide',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: false,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: GestureDetector(
                onTap: () {
                  if (!multimode) {
                    selectedFiles.clear();
                    selectedFiles.add(_file!);
                  }
                  if (selectedFiles.isNotEmpty) {
                    Provider.of<GuideProvider>(context, listen: false)
                        .setImages(selectedFiles, 0);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FillHolder(),
                        ));
                  }
                },
                child: const Text(
                  'Next',
                  style: TextStyle(fontSize: 15, color: Colors.blue),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController, // Add scroll controller
          child: Column(
            children: [
              SizedBox(
                height: 375,
                child: GridView.builder(
                  itemCount: _mediaList.isEmpty ? _mediaList.length : 1,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 1,
                    crossAxisSpacing: 1,
                  ),
                  itemBuilder: (context, index) {
                    return _file!.path.split('.').last == 'mp4'
                        ? FileVideoPlayer(videoFile: _file!)
                        : Image.file(_file!);
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 40,
                // color: Colors.white,
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    const Text(
                      'Recent',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    // IconButton(
                    //     onPressed: () {
                    //       setState(() {
                    //         multimode = !multimode;
                    //         selectedFiles.clear();
                    //         selectedmedialist.clear();
                    //       });
                    //     },
                    //     icon: Icon(multimode
                    //         ? Icons.photo_library
                    //         : Icons.photo_library_outlined)),
                    IconButton(
                        onPressed: () {
                          _pickMedia(context, ImageSource.camera, false);
                        },
                        icon: const Icon(Icons.camera_alt_outlined)),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _mediaList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 2,
                ),
                itemBuilder: (context, index) {
                  if (index == _mediaList.length - 1) {
                    // Show loading indicator at bottom
                    return _hasMoreItems ? const SizedBox() : const SizedBox();
                  }
                  return multimode
                      ? GestureDetector(
                          onTap: () {
                            indexx = index;
                            _file = path[index];
                            selectedmedialist.contains(_mediaList[index])
                                ? selectedmedialist.remove(_mediaList[index])
                                : selectedmedialist.add(_mediaList[index]);
                            selectedFiles.contains(_file)
                                ? selectedFiles.remove(_file)
                                : selectedFiles.add(_file!);

                            if (selectedFiles.isEmpty ||
                                selectedmedialist.isEmpty) {
                              multimode = false;
                              selectedFiles.clear();
                              selectedmedialist.clear();
                            }
                            setState(() {});
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                border: selectedmedialist
                                        .contains(_mediaList[index])
                                    ? Border.all(
                                        color: Colors.blue,
                                        width: 5,
                                      )
                                    : null),
                            child: _mediaList[index],
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            setState(() {
                              indexx = index;
                              _file = path[index];
                            });
                          },
                          onLongPress: () {
                            setState(() {
                              multimode = true;
                              indexx = index;
                              _file = path[index];
                              selectedmedialist.clear();
                              selectedmedialist.add(_mediaList[index]);
                              selectedFiles.clear();
                              selectedFiles.add(_file!);
                            });
                          },
                          child: _mediaList[index],
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FillHolder extends StatefulWidget {
  const FillHolder({super.key});

  @override
  State<FillHolder> createState() => _FillHolderState();
}

class _FillHolderState extends State<FillHolder> {
  int _currentPage = 0;
  int pageMarker = 1;

  final duration = const Duration(milliseconds: 300);
  final curve = Curves.easeIn;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.toInt();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) =>
          Provider.of<GuideProvider>(context, listen: false).reset(),
      child: Scaffold(
        persistentFooterButtons: [
          Text('${_currentPage + 1}/$pageMarker pages'),
          // const Spacer(),
          IconButton(
              onPressed: () {
                _pageController.previousPage(duration: duration, curve: curve);
              },
              icon: const Icon(Icons.arrow_back_ios)),
          IconButton(
              onPressed: () {
                _pageController.nextPage(duration: duration, curve: curve);
              },
              icon: const Icon(Icons.arrow_forward_ios)),
          Consumer<GuideProvider>(builder: (context, provider, child) {
            return Wrap(
              children: [
                IconButton(
                    onPressed:
                        _currentPage == pageMarker - 1 && _currentPage != 0
                            ? () {
                                provider.resetOnly(_currentPage);
                                pageMarker--;
                                setState(() {});
                                _pageController.previousPage(
                                    duration: duration, curve: curve);
                              }
                            : null,
                    icon: const Icon(Icons.delete_outline)),
                IconButton(
                    onPressed: _currentPage == pageMarker - 1 &&
                            provider.selectedImages.length > _currentPage &&
                            provider.selectedImages[_currentPage].isNotEmpty
                        ? () {
                            pageMarker++;
                            setState(() {});
                            _pageController.jumpToPage(pageMarker - 1);
                          }
                        : null,
                    icon: const Icon(Icons.add_box_outlined)),
              ],
            );
          }),
        ],
        appBar: AppBar(
          actions: [
            TextButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FinishGuide(),
                  )),
              child: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            itemCount: pageMarker,
            itemBuilder: (context, index) => FillGuide(page: index),
          ),
        ),
      ),
    );
  }
}

class FillGuide extends StatefulWidget {
  final int page;
  const FillGuide({super.key, required this.page});

  @override
  State<FillGuide> createState() => _FillGuideState();
}

class _FillGuideState extends State<FillGuide> {
  PageController controller = PageController();
  int index = -1;
  List<String> totalcategory = [
    'Resturant',
    'Attraction',
    'Hotel',
    'Transport',
  ];

  Future<void> _pickMedia(
      BuildContext context, ImageSource source, bool isVideo) async {
    final ImagePicker imagePicker = ImagePicker();
    List<File>? imageFileList = [];

    try {
      final List<XFile> si = await imagePicker.pickMultiImage();
      if (si.isNotEmpty) {
        si.forEach(
          (element) => imageFileList.add(File(element.path)),
        );
      }

      Provider.of<GuideProvider>(context, listen: false)
          .setImages(imageFileList, widget.page);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking media: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GuideProvider>(
      builder: (context, state, child) {
        return SingleChildScrollView(
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: PageView(
                    controller: controller,
                    children: state.selectedImages.length == widget.page ||
                            state.selectedImages[widget.page].isEmpty
                        ? [
                            IconButton(
                              onPressed: () {
                                _pickMedia(context, ImageSource.gallery, false);
                              },
                              icon: const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 50,
                              ),
                            ),
                          ]
                        : state.selectedImages[widget.page]
                            .map(
                              (e) => e.path.split('.').last == 'mp4'
                                  ? FileVideoPlayer(videoFile: e)
                                  : Image.file(e),
                            )
                            .toList()),
              ),
              Visibility(
                visible: state.selectedImages.length > widget.page &&
                    state.selectedImages[widget.page].length > 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SmoothPageIndicator(
                    controller: controller,
                    count: state.selectedImages.length == widget.page ||
                            state.selectedImages[widget.page].isEmpty
                        ? 1
                        : state.selectedImages[widget.page].length,
                    effect: const WormEffect(
                      activeDotColor: AppColors.primary,
                      dotHeight: 5,
                      dotWidth: 5,
                      spacing: 5,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  children: [
                    DropdownButton(
                      items: [
                            const DropdownMenuItem(
                              value: 'Select place',
                              child: Text('Select place'),
                            ),
                          ] +
                          totalcategory
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value == 'Select place') {
                          index = -1;
                        } else {
                          index = totalcategory.indexOf(value.toString());
                        }
                        setState(() {});
                      },
                      // dropdownColor: widget.primary[0],
                      value:
                          index == -1 ? 'Select place' : totalcategory[index],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.45,
                      child: TextField(
                        // cursorColor: widget.primary[1],
                        enabled: index != -1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                            hintText: index == -1
                                ? 'Select place first'
                                : '${totalcategory[index]} name',
                            hintStyle: const TextStyle(
                              // color: widget.primary[0],
                              fontWeight: FontWeight.normal,
                            ),
                            focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                              width: 2,
                            )),
                            disabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                              width: 0,
                            )),
                            enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                              width: 1,
                            ))),
                        onChanged: (value) {
                          state.setPlace(totalcategory[index], widget.page);
                          state.setPlaceName(value, widget.page);
                        },
                        style: const TextStyle(
                          // color: widget.primary[1],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              const Row(
                children: [
                  SizedBox(
                    width: 30,
                  ),
                  Text(
                    'Describe your visit',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              Autocomplete(
                fieldViewBuilder: (context, textEditingController, focusNode,
                        onFieldSubmitted) =>
                    Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: TextField(
                    textCapitalization: TextCapitalization.sentences,
                    // cursorColor: widget.primary[1],
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                        labelText: 'location',
                        hintText: '',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.normal,
                        ),
                        suffixIcon: IconButton(
                            onPressed: () {
                              textEditingController.clear();
                            },
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.grey,
                            )),
                        labelStyle: const TextStyle(
                            // color: widget.primary[1],
                            ),
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                          // color: widget.primary[1],
                          width: 1,
                        )),
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                          // color: widget.primary[0],
                          width: 1,
                        ))),
                    style: const TextStyle(
                        // color: primary[1],
                        ),
                  ),
                ),
                optionsBuilder: (textEditingValue) async {
                  if (textEditingValue.text.isEmpty ||
                      textEditingValue.text.length < 3) {
                    return const Iterable<String>.empty();
                  } else {
                    try {
                      var query = textEditingValue.text.toLowerCase().trim();
                      final data = await supabase
                          .from('places')
                          .select('name, vicinity, latitude, longitude')
                          .ilike('name', '%$query%') // Case-insensitive search
                          .limit(10);
                      return data.map((e) => '${e['name']} ${e['vicinity']}');
                    } catch (e) {
                      return const Iterable<String>.empty();
                    }
                  }
                },
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  // cursorColor: widget.primary[1],
                  decoration: const InputDecoration(
                      labelText: 'Experience (optional)',
                      hintText:
                          'What you liked or disliked about this place...',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.normal,
                      ),
                      labelStyle: TextStyle(
                          // color: widget.primary[1],
                          ),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                        // color: widget.primary[1],
                        width: 1,
                      )),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                        // color: widget.primary[0],
                        width: 1,
                      ))),
                  style: const TextStyle(
                      // color: primary[1],
                      ),
                  maxLength: 400,
                  maxLines: 3,
                  onChanged: (value) => state.setExperience(value, widget.page),
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 30),
              //   child: TextField(
              //     textCapitalization: TextCapitalization.sentences,
              //     // cursorColor: widget.primary[1],
              //     decoration: const InputDecoration(
              //         labelText: 'Tips (optional)',
              //         hintText: 'Drop some tips for viewers...',
              //         hintStyle: TextStyle(
              //           color: Colors.grey,
              //           fontWeight: FontWeight.normal,
              //         ),
              //         labelStyle: TextStyle(
              //             // color: widget.primary[1],
              //             ),
              //         focusedBorder: OutlineInputBorder(
              //             borderSide: BorderSide(
              //           // color: widget.primary[1],
              //           width: 1,
              //         )),
              //         enabledBorder: OutlineInputBorder(
              //             borderSide: BorderSide(
              //           // color: widget.primary[0],
              //           width: 1,
              //         ))),
              //     style: const TextStyle(
              //         // color: primary[1],
              //         ),
              //     maxLength: 200,

              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }
}

class FinishGuide extends StatefulWidget {
  const FinishGuide({super.key});

  @override
  State<FinishGuide> createState() => FinishGuideState();
}

class FinishGuideState extends State<FinishGuide> {
  final Map<String, List<String>> stateCityData = indianStatesCities;
  String? selectedState;
  String? selectedCity;

  Future<void> _pickMedia(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? media =
          await picker.pickImage(source: source, maxWidth: 500);

      if (media != null) {
        File resultimagefile;

        resultimagefile = File(media.path);

        Provider.of<GuideProvider>(context, listen: false)
            .setThumbnail(resultimagefile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking media: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Consumer2<GuideProvider, AuthenticationProvider>(
            builder: (context, state, authstate, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        _pickMedia(context, ImageSource.gallery);
                      },
                      child: Container(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: state.thumbnail == null
                              ? const Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 50,
                                    ),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 30),
                                      child: Text(
                                        'Choose thumbnail for you Guide',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                )
                              : Image.file(
                                  state.thumbnail!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Text(
                  'Select State',
                  style: AppTypography.body2.copyWith(fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Container(
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(50)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DropdownButton<String>(
                        underline: const SizedBox(),
                        isExpanded: true,
                        value: selectedState,
                        hint: const Text('Choose a state'),
                        items: stateCityData.keys.map((state) {
                          return DropdownMenuItem(
                            value: state,
                            child: Text(state),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedState = value;
                            selectedCity =
                                null; // Reset city when state changes
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Select City',
                  style: AppTypography.body2.copyWith(fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 30),
                //   child: Container(
                //     decoration:
                //         BoxDecoration(borderRadius: BorderRadius.circular(50)),
                //     child: Padding(
                //       padding: const EdgeInsets.symmetric(horizontal: 20),
                //       child: DropdownButton<String>(
                //         underline: SizedBox(),
                //         isExpanded: true,
                //         value: selectedCity,
                //         hint: const Text('Choose a city'),
                //         items: selectedState == null
                //             ? []
                //             : stateCityData[selectedState]!.map((city) {
                //                 return DropdownMenuItem(
                //                   value: city,
                //                   child: Text(city),
                //                 );
                //               }).toList(),
                //         onChanged: (value) {
                //           setState(() {
                //             selectedCity = value;
                //           });
                //         },
                //       ),
                //     ),
                //   ),
                // ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Autocomplete(
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      } else {
                        // state.performSearch(textEditingValue.text);
                        // return state.locationResults
                        //     .map((e) => e.name)
                        //     .toList();

                        return stateCityData[selectedState]!
                            .where(
                              (element) => element.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase()),
                            )
                            .toList();
                      }
                    },
                    onSelected: (option) {
                      state.setcity(option);
                    },
                    fieldViewBuilder: (context, textEditingController,
                            focusNode, onFieldSubmitted) =>
                        TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      onEditingComplete: onFieldSubmitted,
                      // cursorColor: onprimary[1],
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.location_on_outlined),
                          labelText: 'City',
                          hintText: 'Add a City',
                          hintStyle: TextStyle(
                              // color: primary[0],
                              ),
                          labelStyle: TextStyle(
                              // color: primary[0],
                              ),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                            // color: onprimary[1],
                            width: 1,
                          )),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                            // color: onprimary[0],
                            width: 1,
                          ))),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: TextField(
                    textAlign: TextAlign.center,
                    // cursorColor: onprimary[1],
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 25,
                    decoration: const InputDecoration(
                        hintText: 'Guide Title',
                        hintStyle: TextStyle(
                            // color: onprimary[0],
                            ),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                          // color: onprimary[1],
                          width: 1,
                        )),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                          // color: onprimary[0],
                          width: 1,
                        ))),
                    onChanged: state.setTitle,
                    style: const TextStyle(
                      // color: onprimary[1],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: state.isValid && !state.isUploading
                        ? () async {
                            try {
                              // Ensure Firebase auth is synchronized before uploading
                              await AuthSyncService.syncSupabaseToFirebase();

                              state.setUploading(true);

                              await state.createGuide(
                                user: authstate.userModel!,
                              );

                              // Refresh guides data across the app
                              if (context.mounted) {
                                final exploreProvider =
                                    Provider.of<ExploreProvider>(context,
                                        listen: false);
                                final guideProvider =
                                    Provider.of<GuideProvider>(context,
                                        listen: false);
                                final uploadProvider =
                                    Provider.of<UploadProvider>(context,
                                        listen: false);
                                final profileProvider =
                                    Provider.of<ProfileProvider>(context,
                                        listen: false);

                                exploreProvider.refreshGuides();

                                // Also refresh saved guides if user is logged in
                                if (globalUser?.uid != null) {
                                  guideProvider.refreshSavedGuides(
                                      globalUser!.uid, '');
                                  // Refresh user's own guides cache
                                  uploadProvider
                                      .refreshUserGuides(globalUser!.uid);
                                  // Refresh profile data to update guide counts
                                  profileProvider
                                      .fetchUserData(globalUser!.uid);
                                }
                              }

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Guide created successfully!')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Upload failed: $e')),
                              );
                            }
                          }
                        : null,
                    child: Text(
                      state.isUploading
                          ? 'Creating your guide...'
                          : 'Create Guide',
                    ))
              ],
            ),
          );
        }),
      ),
    );
  }
}
