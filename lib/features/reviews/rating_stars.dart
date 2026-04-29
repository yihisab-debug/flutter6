import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double value;
  final ValueChanged<int>? onChanged;
  final double size;
  final Color color;

  const RatingStars({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 32,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    final isInteractive = onChanged != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        IconData icon;

        if (isInteractive) {
          icon = value >= starValue ? Icons.star : Icons.star_border;
        } else {
          if (value >= starValue) {
            icon = Icons.star;
          } else if (value >= starValue - 0.5) {
            icon = Icons.star_half;
          } else {
            icon = Icons.star_border;
          }
        }

        final iconWidget = Icon(icon, size: size, color: color);

        if (!isInteractive) return iconWidget;

        return GestureDetector(
          onTap: () => onChanged!(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: iconWidget,
          ),
        );
      }),
    );
  }
}
