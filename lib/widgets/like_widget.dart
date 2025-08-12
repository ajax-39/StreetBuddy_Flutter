import 'package:flutter/material.dart';

class LikeWidget extends StatefulWidget {
  final bool isLiked;
  final VoidCallback callback;
  const LikeWidget({super.key, required this.isLiked, required this.callback});

  @override
  State<LikeWidget> createState() => _LikeWidgetState();
}
 
class _LikeWidgetState extends State<LikeWidget> {
  bool isLiked = false;
  int c = 0;
  @override
  Widget build(BuildContext context) {
    isLiked = c == 0 ? widget.isLiked : isLiked;
    return GestureDetector(
      onTap: () {
        c++;
        setState(() {
          isLiked = !isLiked;
        });
        widget.callback();
      },
      child: Image.asset(
        isLiked ? 'assets/icon/like-fill.png' : 'assets/icon/like.png',
        color: isLiked ? Colors.red : null,
        width: 20,
      ),
    );
  }
}
