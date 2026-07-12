import 'package:flutter/material.dart';

import '../../core/network/connectivity_service.dart';

/// A thin banner that slides in when the device loses connectivity and slides
/// away when it returns. Purely informational — the app keeps working from the
/// Hive cache while offline.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _online = true;

  @override
  void initState() {
    super.initState();
    ConnectivityService.instance.isOnline.then((v) {
      if (mounted) setState(() => _online = v);
    });
    ConnectivityService.instance.onStatusChange.listen((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: _online
          ? const SizedBox.shrink()
          : Container(
              width: double.infinity,
              color: const Color(0xFF6B7280),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Sem ligação — a mostrar dados guardados',
                    style: TextStyle(color: Colors.white, fontSize: 12.5),
                  ),
                ],
              ),
            ),
    );
  }
}
