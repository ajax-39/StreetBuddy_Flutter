import 'package:flutter/cupertino.dart';

Widget CustomOverlayContainer({required Widget child, double? height = 500}) {
  return Container(
    height: height,
    decoration: BoxDecoration(
      backgroundBlendMode: BlendMode.multiply,
      gradient: LinearGradient(
        colors: [
          Color(0x47FFFFFF).withOpacity(0.57),
          Color(0xD6373737).withOpacity(0.57),
          Color(0xFF000000).withOpacity(0.57),
          Color(0xFF000000).withOpacity(0.57),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0, 0.14, 0.18, 1],
      ),
    ),
    child: child,
  );
}
 