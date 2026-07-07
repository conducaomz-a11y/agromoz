import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Cached image with graceful placeholder + broken-image fallback.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget fallback = Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.agriculture_outlined,
          size: 36, color: scheme.onSurfaceVariant.withValues(alpha: .5),),
    );

    final Widget image = (url == null || url!.isEmpty)
        ? fallback
        : CachedNetworkImage(
            imageUrl: url!,
            fit: fit,
            width: width,
            height: height,
            placeholder: (_, __) => Container(
              width: width,
              height: height,
              color: scheme.surfaceContainerHighest,
            ),
            errorWidget: (_, __, ___) => fallback,
          );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
