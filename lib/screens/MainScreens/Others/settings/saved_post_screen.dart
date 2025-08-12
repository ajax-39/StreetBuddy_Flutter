import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/services/share_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:street_buddy/models/post.dart';

class SavedPostScreen extends StatelessWidget {
  const SavedPostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = globalUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved Posts')),
        body: const Center(child: Text('Please log in to view saved posts.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Posts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<String>>(
        stream: context.read<PostProvider>().getSavedPostsStream(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final savedPostIds = snapshot.data!;
          if (savedPostIds.isEmpty) {
            return const Center(child: Text('No saved posts.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: savedPostIds.length,
            itemBuilder: (context, index) {
              final postId = savedPostIds[index];
              return SavedPostTile(postId: postId);
            },
          );
        },
      ),
    );
  }
}

class SavedPostTile extends StatelessWidget {
  final String postId;
  const SavedPostTile({super.key, required this.postId});

  Future<PostModel?> _fetchPostModel(String postId) async {
    final supabase = Supabase.instance.client;
    final res =
        await supabase.from('posts').select().eq('id', postId).maybeSingle();
    if (res == null) return null;
    return PostModel.fromMap(postId, res);
  }

  Future<void> _removeFromSaved(BuildContext context, String postId) async {
    final user = globalUser;
    if (user == null) return;
    final supabase = Supabase.instance.client;
    final data = await supabase
        .from('users')
        .select('saved_post')
        .eq('uid', user.uid)
        .single();
    List savedPosts = List.from(data['saved_post'] ?? []);
    savedPosts.remove(postId);
    await supabase
        .from('users')
        .update({'saved_post': savedPosts}).eq('uid', user.uid);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed from saved posts.')),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, String postId) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[200],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Text('Are you sure you want to Delete post ?',
              style: TextStyle(fontSize: 16)),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    if (result == true) {
      await _removeFromSaved(context, postId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🏗️ Building SavedPostTile widget
    // ignore: avoid_print
    print('🏗️ [SavedPostTile] Building widget for postId $postId');
    return FutureBuilder<PostModel?>(
      future: _fetchPostModel(postId),
      builder: (context, snapshot) {
        // 🕵️‍♂️ FutureBuilder state
        // ignore: avoid_print
        print(
            '🕵️‍♂️ [SavedPostTile] FutureBuilder state for postId $postId: ${snapshot.connectionState}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          // ⏳ Waiting for post data
          // ignore: avoid_print
          print('⏳ [SavedPostTile] Waiting for post data for postId $postId');
          return _buildLoadingPlaceholder();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          // ⚠️ No post data found
          // ignore: avoid_print
          print('⚠️ [SavedPostTile] No post data found for postId $postId');
          return _buildErrorPlaceholder();
        }

        final post = snapshot.data!;
        // 📦 Post data fetched
        // ignore: avoid_print
        print('📦 [SavedPostTile] Post data fetched for postId $postId: $post');
        final hasMedia = post.mediaUrls.isNotEmpty;
        // 🖼️ Media check
        // ignore: avoid_print
        print('🖼️ [SavedPostTile] hasMedia for postId $postId: $hasMedia');
        final imageUrl = hasMedia ? post.mediaUrls.first : null;
        // Debug: Print the fetched image URL
        // 🖼️ Image fetch debug
        // ignore: avoid_print
        print(
            '🖼️ [SavedPostTile] Fetched imageUrl for postId $postId: $imageUrl');

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[200],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image content
              if (hasMedia)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) {
                      // 🕒 Image loading debug
                      // ignore: avoid_print
                      print(
                          '⏳ [SavedPostTile] Loading image for postId $postId: $url');
                      return _buildLoadingPlaceholder();
                    },
                    errorWidget: (context, url, error) {
                      // ❌ Image error debug
                      // ignore: avoid_print
                      print(
                          '❌ [SavedPostTile] Error loading image for postId $postId: $url, error: $error');
                      return _buildErrorPlaceholder();
                    },
                  ),
                )
              else
                _buildErrorPlaceholder(),

              // Options menu
              Positioned(
                top: 4,
                right: 4,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) async {
                    if (value == 'share') {
                      final user = globalUser;
                      if (user != null) {
                        await ShareService().sharePost(context, user.uid, post);
                      }
                    } else if (value == 'delete') {
                      await _showDeleteConfirmation(context, postId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Text('Share'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child:
                          Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),

              // Video indicator if applicable
              if (post.type == PostType.video)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    // 🔄 Loading placeholder shown
    // ignore: avoid_print
    print('🔄 [SavedPostTile] Showing loading placeholder for postId $postId');
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    // 🛑 Error placeholder shown
    // ignore: avoid_print
    print('🛑 [SavedPostTile] Showing error placeholder for postId $postId');
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.error, size: 40),
      ),
    );
  }
}
