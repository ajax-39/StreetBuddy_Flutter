import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/models/post.dart';

class ImageLoadingTestScreen extends StatefulWidget {
  const ImageLoadingTestScreen({super.key});

  @override
  State<ImageLoadingTestScreen> createState() => _ImageLoadingTestScreenState();
}

class _ImageLoadingTestScreenState extends State<ImageLoadingTestScreen> {
  List<PostModel> _posts = [];
  bool _isLoading = true;
  String? _error;
  late DateTime _startTime;
  DateTime? _endTime;
  int _totalImages = 0;
  int _loadedImages = 0;
  final Set<String> _loadedImageUrls =
      {}; // Track which images are already loaded

  @override
  void initState() {
    super.initState();
    _startFetching();
  }

  Future<void> _startFetching() async {
    _startTime = DateTime.now();
    setState(() {
      _isLoading = true;
      _error = null;
      _loadedImages = 0; // Reset counter
      _loadedImageUrls.clear(); // Clear tracking set
    });

    try {
      final postProvider = context.read<PostProvider>();

      // Fetch ALL posts to get all images
      final posts = await postProvider.getAllPostsFuture();

      // Filter only posts that have images
      final imagePosts = posts
          .where((post) =>
              post.type == PostType.image && post.mediaUrls.isNotEmpty)
          .toList();

      _totalImages =
          imagePosts.fold(0, (sum, post) => sum + post.mediaUrls.length);

      setState(() {
        _posts = imagePosts;
        _isLoading = false;
        _endTime = DateTime.now();
      });

      debugPrint(
          '📊 Fetched ${imagePosts.length} posts with $_totalImages images');
      debugPrint(
          '⏱️ Fetch time: ${_endTime!.difference(_startTime).inMilliseconds}ms');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _endTime = DateTime.now();
      });
    }
  }

  void _onImageLoaded(String imageUrl) {
    // Only count if this image hasn't been counted before
    if (!_loadedImageUrls.contains(imageUrl)) {
      _loadedImageUrls.add(imageUrl);
      setState(() {
        _loadedImages++;
      });

      debugPrint('🖼️ Image loaded: $_loadedImages/$_totalImages');

      if (_loadedImages == _totalImages) {
        final totalTime = DateTime.now().difference(_startTime).inMilliseconds;
        debugPrint('🖼️ All $_totalImages images loaded in ${totalTime}ms');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All $_totalImages images loaded in ${totalTime}ms'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final crossAxisCount = isTablet ? 4 : 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Loading Test'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startFetching,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Posts', '${_posts.length}', Colors.blue),
                    _buildStatCard('Images', '$_totalImages', Colors.green),
                    _buildStatCard('Loaded', '$_loadedImages', Colors.orange),
                  ],
                ),
                const SizedBox(height: 12),
                if (_endTime != null)
                  Text(
                    'Fetch Time: ${_endTime!.difference(_startTime).inMilliseconds}ms',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                if (_isLoading)
                  const Text(
                    'Fetching posts...',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(crossAxisCount),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(int crossAxisCount) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text('Fetching all posts...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startFetching,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No image posts found'),
          ],
        ),
      );
    }

    // Build grid of all images
    final allImages = <String>[];
    for (final post in _posts) {
      allImages.addAll(post.mediaUrls);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: allImages.length,
      itemBuilder: (context, index) {
        return _buildImageTile(allImages[index], index);
      },
    );
  }

  Widget _buildImageTile(String imageUrl, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orange,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 20),
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          imageBuilder: (context, imageProvider) {
            // Call this when image loads successfully
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _onImageLoaded(imageUrl);
            });

            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
