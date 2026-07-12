import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Central helper for picking + compressing images across the app.
///
/// Every screen that needs a photo (avatar, product image, business logo…)
/// goes through here, so compression and the camera/gallery chooser stay
/// consistent. Compression matters a lot for users on metered/expensive data
/// in Moçambique — we shrink both dimensions and quality before upload.
class ImagePickerService {
  ImagePickerService._();
  static final ImagePickerService instance = ImagePickerService._();

  final ImagePicker _picker = ImagePicker();

  /// Shows a bottom sheet letting the user choose camera or gallery,
  /// then returns the picked+compressed file path (or null if cancelled).
  Future<String?> pickAndCompress(
    BuildContext context, {
    int maxDimension = 1280,
    int quality = 80,
  }) async {
    final ImageSource? source = await _chooseSource(context);
    if (source == null) return null;

    final XFile? raw = await _picker.pickImage(
      source: source,
      maxWidth: maxDimension.toDouble(),
      maxHeight: maxDimension.toDouble(),
      imageQuality: quality,
    );
    if (raw == null) return null;

    return _compress(raw.path, quality: quality);
  }

  /// Pick directly from a known source (no chooser) — handy when the caller
  /// already has its own UI. Still compresses.
  Future<String?> pickFrom(
    ImageSource source, {
    int maxDimension = 1280,
    int quality = 80,
  }) async {
    final XFile? raw = await _picker.pickImage(
      source: source,
      maxWidth: maxDimension.toDouble(),
      maxHeight: maxDimension.toDouble(),
      imageQuality: quality,
    );
    if (raw == null) return null;
    return _compress(raw.path, quality: quality);
  }

  Future<ImageSource?> _chooseSource(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Re-encodes to JPEG at the given quality. Falls back to the original
  /// path if compression fails for any reason (never blocks the user).
  Future<String> _compress(String path, {required int quality}) async {
    try {
      final dir = await getTemporaryDirectory();
      final target =
          '${dir.path}/agromoz_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        path,
        target,
        quality: quality,
        minWidth: 1280,
        minHeight: 1280,
      );
      return result?.path ?? path;
    } catch (_) {
      return path;
    }
  }

  /// Convenience for showing the picked file before upload.
  static File fileFor(String path) => File(path);
}
