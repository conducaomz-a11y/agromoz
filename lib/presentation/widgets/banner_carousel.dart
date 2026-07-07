import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../data/models/banner_model.dart';
import 'app_network_image.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key, required this.banners, this.onTap});

  final List<BannerModel> banners;
  final void Function(BannerModel banner)? onTap;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _controller = PageController(viewportFraction: .92);
  Timer? _autoplay;

  @override
  void initState() {
    super.initState();
    _autoplay = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_controller.hasClients || widget.banners.length < 2) return;
      final next =
          ((_controller.page ?? 0).round() + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoplay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            itemBuilder: (_, i) {
              final banner = widget.banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => widget.onTap?.call(banner),
                  child: AppNetworkImage(
                    url: banner.imageUrl,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SmoothPageIndicator(
          controller: _controller,
          count: widget.banners.length,
          effect: ExpandingDotsEffect(
            dotHeight: 6,
            dotWidth: 6,
            activeDotColor: Theme.of(context).colorScheme.primary,
            dotColor: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ],
    );
  }
}
