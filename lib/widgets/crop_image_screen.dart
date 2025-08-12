import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:color_filter_extension/color_filter_extension.dart';
import 'package:widgets_to_image/widgets_to_image.dart';

class CropImageScreen extends StatefulWidget {
  final File image;

  const CropImageScreen({super.key, required this.image});

  @override
  State<CropImageScreen> createState() => _CropImageScreenState();
}

class _CropImageScreenState extends State<CropImageScreen> {
  WidgetsToImageController widgetsToImageController =
      WidgetsToImageController();
  final controller = CropController();
  var selectedPreset = ColorFiltersPreset.none();
  final filters = presetFiltersList;
  bool isNoFilter = true;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text('Crop Image'),
          ),
          body: Column(
            children: [
              Expanded(
                child: ColorFiltered(
                  colorFilter: ColorFilterExt.preset(selectedPreset),
                  child: CropImage(
                    controller: controller,
                    image: Image.file(widget.image),
                    paddingSize: 25.0,
                    alwaysMove: true,
                  ),
                ),
              ),
              // _buildEditButton(),
              _buildFilters(),
            ],
          ),
          bottomNavigationBar: _buildButtons(),
        ),
      );

  Widget _buildButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () {
              controller.rotation = CropRotation.up;
              controller.crop = const Rect.fromLTRB(0, 0, 1, 1);
              controller.aspectRatio = null;
            },
          ),
          IconButton(
            icon: const Icon(Icons.aspect_ratio),
            onPressed: _aspectRatios,
          ),
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_ccw_outlined),
            onPressed: _rotateLeft,
          ),
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
            onPressed: _rotateRight,
          ),
          TextButton(
            onPressed: _finished,
            child: const Icon(Icons.done),
          ),
        ],
      );

  Future<void> _aspectRatios() async {
    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select aspect ratio'),
          children: [
            // special case: no aspect ratio
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, -1.0),
              child: const Text('free'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 1.0),
              child: const Text('square'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 2.0),
              child: const Text('2:1'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 1 / 2),
              child: const Text('1:2'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 4.0 / 3.0),
              child: const Text('4:3'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 16.0 / 9.0),
              child: const Text('16:9'),
            ),
          ],
        );
      },
    );
    if (value != null) {
      controller.aspectRatio = value == -1 ? null : value;
      controller.crop = const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9);
    }
  }

  Future<void> _rotateLeft() async => controller.rotateLeft();

  Future<void> _rotateRight() async => controller.rotateRight();

  Future<void> _finished() async {
    ui.Image bitmap = await controller.croppedBitmap();

    var data = await bitmap.toByteData(format: ui.ImageByteFormat.png);
    var bytes = data!.buffer.asUint8List();
    if (isNoFilter) {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/profilepic${Random().nextInt(32)}';

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        Navigator.pop(context, file);
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Displays the cropped and filtered image in the CropImageScreen widget.

              // The WidgetsToImage widget captures the child widget, which is a ColorFiltered widget with the selected color filter preset applied. The ConstrainedBox ensures the image is displayed within the maximum height and width constraints.

              // The bytes parameter is the image data that is displayed using the Image.memory widget.
              WidgetsToImage(
                controller: widgetsToImageController,
                child: ColorFiltered(
                    colorFilter: ColorFilterExt.preset(selectedPreset),
                    child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                          maxWidth: MediaQuery.sizeOf(context).shortestSide,
                        ),
                        child: Image.memory(bytes))),
              ),
              ElevatedButton.icon(
                onPressed: () async {
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
                  var bytes = await widgetsToImageController.capture();

                  final tempDir = await getTemporaryDirectory();
                  final filePath =
                      '${tempDir.path}/profilepic${Random().nextInt(32)}';

                  final file = File(filePath);
                  await file.writeAsBytes(bytes!);

                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context, file);
                  }
                },
                style: ElevatedButton.styleFrom(
                    // backgroundColor: Colors.grey.shade900,
                    ),
                icon: const Icon(Icons.done),
                label: const Text('Use filter'),
              )
            ],
          ),
        ),
      );
    }
  }

  _buildFilters() {
    return SizedBox(
      height: 80,
      child: GridView.builder(
        itemCount: filters.length,
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1, childAspectRatio: 1),
        itemBuilder: (context, index) => InkWell(
          onTap: () {
            setState(() {
              selectedPreset = filters[index];
              isNoFilter = index == 0 ? true : false;
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: ColorFilterExt.preset(filters[index]),
                child: Image.file(
                  widget.image,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
