// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/provider/MainScreen/upload_provider.dart';
import 'package:street_buddy/widgets/crop_image_screen.dart';
import 'package:street_buddy/widgets/file_video_player.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final List<Widget> _mediaList = [];
  final List<File> path = [];
  final ScrollController _scrollController = ScrollController();
  File? _file;
  int currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _fetchNewMedia();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        _fetchNewMedia();
      }
    }
  }

  Future<void> _fetchNewMedia() async {
    if (_isLoading) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth) return;

      List<AssetPathEntity> album =
          await PhotoManager.getAssetPathList(type: RequestType.common);

      if (album.isEmpty) return;

      List<AssetEntity> media =
          await album[0].getAssetListPaged(page: currentPage, size: _pageSize);

      for (var asset in media) {
        final file = await asset.file;
        if (file != null) {
          path.add(File(file.path));
          _file ??= path[0];
        }
      }

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

      if (!mounted) return;
      setState(() {
        _mediaList.addAll(temp);
        currentPage++;
        _hasMore = media.length == _pageSize;
      });
    } finally {
      if (!mounted) return;
      setState(() {
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
          resultimagefile = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CropImageScreen(image: img),
              ));
        } else {
          resultimagefile = File(media.path);
        }

        Provider.of<UploadProvider>(context, listen: false).setMedia(
            resultimagefile, isVideo ? PostType.video : PostType.image);

        context.push('/upload/info');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking media: $e')),
      );
    }
  }

  Future<void> _pushFile(
      BuildContext context, File resultimagefile, bool isVideo) async {
    try {
      if (!isVideo) {
        File? img = resultimagefile;
        resultimagefile = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CropImageScreen(image: img),
            ));
      }

      Provider.of<UploadProvider>(context, listen: false)
          .setMedia(resultimagefile, isVideo ? PostType.video : PostType.image);

      context.push('/upload/info');
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error picking media: $e')),
      // );
    }
  }

  int indexx = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'New Post',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: false,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: GestureDetector(
                onTap: () {
                  _pushFile(
                      context, _file!, _file!.path.split('.').last == 'mp4');
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
          controller: _scrollController,
          child: Column(
            children: [
              SizedBox(
                height: 375,
                child: _file != null
                    ? _file!.path.split('.').last == 'mp4'
                        ? FileVideoPlayer(videoFile: _file!)
                        : Image.file(_file!)
                    : const SizedBox(),
              ),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    const Text(
                      'Recent',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
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
                itemCount: _mediaList.length + (_hasMore ? 1 : 0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 2,
                ),
                itemBuilder: (context, index) {
                  if (index == _mediaList.length) {
                    return const SizedBox();
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        indexx = index;
                        _file = path[index];
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
