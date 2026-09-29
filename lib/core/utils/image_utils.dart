import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  ImageUtils._();

  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from the specified [source] (gallery or camera),
  /// resizes it so its maximum dimension is at most [maxDimension] pixels (default 512x512 max),
  /// and compresses it into an efficient JPEG format for local storage.
  static Future<Uint8List?> pickAndCompressImage({
    ImageSource source = ImageSource.gallery,
    int maxDimension = 512,
    int quality = 65,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: maxDimension.toDouble(),
        maxHeight: maxDimension.toDouble(),
      );

      if (file == null) return null;

      final rawBytes = await file.readAsBytes();
      return await compressAndResize(
        rawBytes,
        maxDimension: maxDimension,
        quality: quality,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[ImageUtils] Error picking/compressing image: $e');
      }
      return null;
    }
  }

  /// Resizes [rawBytes] so width and height do not exceed [maxDimension],
  /// preserving aspect ratio, and encodes into a highly compact JPEG format.
  static Future<Uint8List?> compressAndResize(
    Uint8List rawBytes, {
    int maxDimension = 512,
    int quality = 65,
  }) async {
    return compute(
      _compressWorker,
      _CompressParams(
        rawBytes: rawBytes,
        maxDimension: maxDimension,
        quality: quality,
      ),
    );
  }
}

class _CompressParams {
  const _CompressParams({
    required this.rawBytes,
    required this.maxDimension,
    required this.quality,
  });

  final Uint8List rawBytes;
  final int maxDimension;
  final int quality;
}

Uint8List? _compressWorker(_CompressParams params) {
  try {
    final decoded = img.decodeImage(params.rawBytes);
    if (decoded == null) return null;

    // Correct orientation if EXIF orientation is present
    img.Image processed = img.bakeOrientation(decoded);

    // Calculate aspect ratio resize if larger than maxDimension
    if (processed.width > params.maxDimension || processed.height > params.maxDimension) {
      if (processed.width >= processed.height) {
        processed = img.copyResize(
          processed,
          width: params.maxDimension,
          interpolation: img.Interpolation.linear,
        );
      } else {
        processed = img.copyResize(
          processed,
          height: params.maxDimension,
          interpolation: img.Interpolation.linear,
        );
      }
    }

    // Encode to efficient JPEG format (quality 65 achieves small byte size)
    final compressed = img.encodeJpg(processed, quality: params.quality);
    return Uint8List.fromList(compressed);
  } catch (e) {
    return null;
  }
}
