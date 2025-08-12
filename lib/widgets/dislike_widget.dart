import 'package:flutter/material.dart';

class DislikeWidget extends StatefulWidget {
  final bool isDisliked;
  final VoidCallback callback;
  const DislikeWidget(
      {super.key, required this.isDisliked, required this.callback});

  @override
  State<DislikeWidget> createState() => _DislikeWidgetState();
}

class _DislikeWidgetState extends State<DislikeWidget> {
  bool isDisliked = false;
  int c = 0;
  @override
  Widget build(BuildContext context) {
    isDisliked = c == 0 ? widget.isDisliked : isDisliked;
    return GestureDetector(
      onTap: () {
        c++;
        setState(() {
          isDisliked = !isDisliked;
        });
        widget.callback();
      },
      child: Image.asset(
        isDisliked ? 'assets/icon/dislike-fill.png' : 'assets/icon/dislike.png',
        color: isDisliked ? Colors.blue : null,
        width: 20,
      ),
    );
  }
}
