import 'package:flutter/material.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/screens/MainScreens/Guides/view_guide_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuideRouter extends StatefulWidget {
  final String postId;
  const GuideRouter({super.key, required this.postId});

  @override
  State<GuideRouter> createState() => _GuideRouterState();
}

class _GuideRouterState extends State<GuideRouter> {
  final PostProvider _postProvider = PostProvider();
  bool _isLoading = true;
  PostModel? _guide;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchGuideData();
  }

  Future<void> _fetchGuideData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch the guide data directly, not as a stream
      final guide = await _postProvider.getGuideOnce(widget.postId);

      if (mounted) {
        setState(() {
          _guide = guide;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching guide: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e is PostgrestException
              ? 'Guide not found'
              : 'Failed to load guide: ${e.toString().split(":").first}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Guide')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchGuideData, // Retry fetching data
                child: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Show guide not found
    if (_guide == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Guide')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Guide not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Show guide content
    final currentUser = globalUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Guide')),
        body: const Center(
          child: Text('Please log in to view guides'),
        ),
      );
    }

    return ViewGuideScreen(
        post: _guide!, isOwnProfile: currentUser.uid == _guide!.userId);
  }
}
