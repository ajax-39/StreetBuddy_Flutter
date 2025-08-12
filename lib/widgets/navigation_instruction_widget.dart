import 'package:flutter/material.dart';

class NavigationInstructionWidget extends StatelessWidget {
  final String instruction;
  final double distance;

  const NavigationInstructionWidget({
    super.key,
    required this.instruction,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _getDirectionIcon(instruction),
            size: 32,
            color: Colors.blue,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  instruction,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'In ${distance < 1000 ? '${distance.round()}m' : '${(distance / 1000).toStringAsFixed(1)}km'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDirectionIcon(String instruction) {
    if (instruction.contains('right')) return Icons.turn_right;
    if (instruction.contains('left')) return Icons.turn_left;
    if (instruction.contains('U-turn')) return Icons.u_turn_left;
    return Icons.straight;
  }
}
