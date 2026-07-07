import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 22,
    this.showOnlineDot = false,
    this.isOnline = false,
  });

  final String name;
  final String? imageUrl;
  final double radius;
  final bool showOnlineDot;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final String initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
          ? CachedNetworkImageProvider(imageUrl!)
          : null,
      child: Text(
        initials,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: radius * .7,
        ),
      ),
    );

    if (!showOnlineDot) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: radius * .55,
            height: radius * .55,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF2E9E5B) : scheme.outline,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
