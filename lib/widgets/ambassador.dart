import 'package:flutter/material.dart';
import 'package:street_buddy/utils/styles.dart';

class BrandAmbassadorBadge extends StatelessWidget {
  final bool isVip;
  final double? size;
  final Color? color;
  const BrandAmbassadorBadge({
    super.key,
    required this.isVip,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isVip,
      child: GestureDetector(
        onTap: () => showModalBottomSheet(
          backgroundColor: Colors.grey.shade900,
          context: context,
          builder: (context) => verifiedBottomSheet(),
        ),
        child: Icon(
          Icons.verified,
          size: size,
          color: color,
        ),
      ),
    );
  }

  Widget verifiedBottomSheet() {
    return const SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified,
            size: 100,
            color: Colors.pinkAccent,
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'Brand Ambassador',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.pinkAccent,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            textAlign: TextAlign.center,
            'This badge indicates that the user is officially a Street Buddy trusted and verified user and a prominent guide',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
