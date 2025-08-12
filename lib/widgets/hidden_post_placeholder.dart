import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/post_provider.dart';

class HiddenPostPlaceholder extends StatelessWidget {
  final String postId;
  final double cardMargin;
  final bool isTablet;

  const HiddenPostPlaceholder({
    super.key,
    required this.postId,
    this.cardMargin = 8.0,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    final horizontalPadding = isTablet ? 20.0 : 10.0;

    return Card(
      margin: EdgeInsets.only(bottom: cardMargin),
      elevation: 0,
      color: Colors.grey[100],
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: isTablet ? 20 : 16,
        ),
        child: Column(
          children: [
            Icon(
              Icons.visibility_off_outlined,
              size: isTablet ? 32 : 28,
              color: Colors.grey[500],
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              'Post Hidden',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: isTablet ? 8 : 4),
            Text(
              'This post has been hidden from your feed',
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 16 : 12),
            TextButton(
              onPressed: () {
                postProvider.unhidePost(postId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post restored to your feed'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                'Show Post',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
