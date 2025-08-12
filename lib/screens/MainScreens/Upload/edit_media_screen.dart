import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:crop_image/crop_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/MainScreen/guide_provider.dart';
import 'package:street_buddy/provider/MainScreen/upload_provider.dart';
import 'package:street_buddy/utils/styles.dart';

class EditMediaScreen extends StatefulWidget {
  final int index;
  final int? guideNumber;
  const EditMediaScreen({super.key, required this.index, this.guideNumber});

  @override
  State<EditMediaScreen> createState() => _EditMediaScreenState();
}

class _EditMediaScreenState extends State<EditMediaScreen> {
  final controller = CropController(aspectRatio: 1);
  File? selectedFile;
  bool isEdited = false;

  @override
  void initState() {
    super.initState();
    debugPrint('✅ EditMediaScreen opened');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UploadProvider>(builder: (context, provider, _) {
      selectedFile = selectedFile ?? provider.selectedMedias[widget.index].file;

      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Edit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: fontsemibold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              // Provider.of<UploadProvider>(context, listen: false).reset();
              context.pop();
            },
            icon: const Icon(CupertinoIcons.xmark),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: Image.asset(
                'assets/icon/pen.png',
                width: 26,
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: Column(
          children: [
            SizedBox(
              height: 60,
              width: double.infinity,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.color_lens_outlined),
                    iconSize: 25,
                  ),
                ],
              ),
            ),
            Expanded(
              child: CropImage(
                controller: controller,
                onCrop: (value) {
                  isEdited = true;
                },
                image: Image.file(selectedFile!),
                paddingSize: 25.0,
                alwaysMove: true,
              ),
            ),
            SizedBox(
              height: 90,
              width: double.infinity,
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 20, right: 5, top: 10),
                itemBuilder: (context, index) {
                  final media = provider.selectedMedias[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: Badge(
                      backgroundColor: Colors.transparent,
                      label: GestureDetector(
                        onTap: () => setState(() => provider.selectedMedias
                            .removeWhere((element) =>
                                element.assetEntity.id ==
                                media.assetEntity.id)),
                        child: Container(
                          height: 20,
                          width: 20,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xffE5D9D9),
                                width: 1,
                              )),
                          child: const Icon(
                            Icons.close,
                            size: 15,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      child: GestureDetector(
                        onTap: index == widget.index
                            ? null
                            : () => _viewNext(index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 64,
                            width: 64,
                            child: media.widget,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                itemCount: provider.selectedMedias.length,
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildButtons(),
      );
    });
  }

  Widget _buildButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () {
              debugPrint('🔄 Restore button pressed');
              controller.rotation = CropRotation.up;
              controller.crop = const Rect.fromLTRB(0, 0, 1, 1);
              controller.aspectRatio = 1;
              isEdited = false;
            },
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen_rounded),
            onPressed: () {
              debugPrint('📐 Aspect ratio button pressed');
              _aspectRatios();
            },
          ),
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_ccw_outlined),
            onPressed: () {
              debugPrint('⏪ Rotate left button pressed');
              _rotateLeft();
            },
          ),
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
            onPressed: () {
              debugPrint('⏩ Rotate right button pressed');
              _rotateRight();
            },
          ),
          TextButton(
            onPressed: () async {
              debugPrint('✅ Done button pressed');
              await _save();
              if (Provider.of<UploadProvider>(context, listen: false)
                      .createPostType ==
                  CreatePostType.post) {
                debugPrint('➡️ Navigating to /upload/post');
                context.pushReplacement('/upload/post');
              } else {
                var a = Provider.of<UploadProvider>(context, listen: false)
                    .selectedMedias;
                Provider.of<GuideProvider>(context, listen: false).setImages(
                    a.map((e) => e.file).toList(), widget.guideNumber ?? 0);
                debugPrint('➡️ Navigating to /upload/guide');
                context.pushReplacement(widget.guideNumber == null
                    ? '/upload/guide'
                    : '/upload/guide/${widget.guideNumber}');
              }
            },
            child: const Icon(Icons.done, color: AppColors.primary),
          ),
        ],
      );

  Future<void> _aspectRatios() async {
    final value = await showCupertinoModalPopup<double>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Select aspect ratio'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                debugPrint('Aspect ratio set to square (1.0)');
                Navigator.pop(context, 1.0);
              },
              child: const Text('square'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                debugPrint('Aspect ratio set to landscape (1.25)');
                Navigator.pop(context, 1.25);
              },
              child: const Text('landscape'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                debugPrint('Aspect ratio set to portrait (0.8)');
                Navigator.pop(context, 0.8);
              },
              child: const Text('portrait'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              debugPrint('Aspect ratio selection cancelled');
              Navigator.pop(context);
            },
            isDestructiveAction: true,
            child: const Text('Cancel'),
          ),
        );
      },
    );
    if (value != null) {
      controller.aspectRatio = value == -1 ? null : value;
      controller.crop = const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9);
    }
  }

  Future<void> _rotateLeft() async {
    controller.rotateLeft();
    isEdited = true;
  }

  Future<void> _rotateRight() async {
    controller.rotateRight();
    isEdited = true;
  }

  void _viewNext(int index) {
    if (isEdited) {
      debugPrint(
          '📝 Prompting to save changes before switching to index $index');
      showDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Save changes?'),
          content: const Text('Do you want to save the changes?'),
          actions: [
            TextButton(
              onPressed: () async {
                debugPrint('💾 Saving changes and switching to index $index');
                await _save();
                context.pushReplacement(widget.guideNumber == null
                    ? '/upload/edit/$index'
                    : '/upload/edit/$index/${widget.guideNumber}');
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                debugPrint(
                    '❌ Discarding changes and switching to index $index');
                context.pushReplacement('/upload/edit/$index');
              },
              child: const Text('No'),
            ),
          ],
        ),
      );
    } else {
      debugPrint('➡️ Switching to edit index $index');
      context.pushReplacement('/upload/edit/$index');
    }
  }

  Future<void> _save() async {
    debugPrint('💾 Saving cropped/edited image');
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: SizedBox(
          width: 100,
          height: 1,
          child: LinearProgressIndicator(),
        ),
      ),
    );
    ui.Image bitmap = await controller.croppedBitmap();
    var data = await bitmap.toByteData(format: ui.ImageByteFormat.png);
    var bytes = data!.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/IMG${Random().nextInt(100)}';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    Provider.of<UploadProvider>(context, listen: false)
        .setSingleSelectedMedias(file, widget.index);
    Navigator.pop(context);
  }
}
