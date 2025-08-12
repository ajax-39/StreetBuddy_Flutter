import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/services/settings_service.dart';
import 'package:street_buddy/utils/optimized_image_loader.dart';

/// A widget that displays an image with data saver mode in mind
class DataSaverAwareImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const DataSaverAwareImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });
  @override
  Widget build(BuildContext context) {
    // Use the singleton instance
    final optimizedImageLoader = OptimizedImageLoader();

    // Use the optimized image loader which checks data saver mode internally
    return optimizedImageLoader.loadNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}

/// Use this widget to display an example of data saver mode in action
class DataSaverModeExample extends StatelessWidget {
  const DataSaverModeExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Saver Mode: ${settings.dataSaverMode ? 'ON' : 'OFF'}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Image Quality: ${settings.dataSaverMode ? 'Optimized (lower)' : 'High'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: DataSaverAwareImage(
                    imageUrl: 'https://picsum.photos/600/800',
                    width: 250,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Sample image with adjusted quality',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
