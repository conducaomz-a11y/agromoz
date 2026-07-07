import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final IconData icon = rating >= i + 1
            ? Icons.star_rounded
            : rating > i
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded;
        return Icon(icon, size: size, color: const Color(0xFFF9A825));
      }),
    );
  }
}
