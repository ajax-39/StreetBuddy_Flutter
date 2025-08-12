import 'package:flutter/material.dart';

class ShiningStarButton extends StatefulWidget {
  final VoidCallback onTap;
  final String? tooltip;
  final double size;
  const ShiningStarButton({
    super.key,
    required this.onTap,
    this.tooltip,
    this.size = 50,
  });

  @override
  State<ShiningStarButton> createState() => _ShiningStarButtonState();
}

class _ShiningStarButtonState extends State<ShiningStarButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip ?? 'Ambassador Program',
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade300,
                      Colors.amber.shade600,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber
                          .withOpacity(_opacityAnimation.value * 0.5),
                      blurRadius: widget.size * 0.2,
                      spreadRadius: widget.size * 0.04,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.star,
                  color: Colors.white,
                  size: widget.size * 0.6,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
