import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'app_logger.dart';

/// Compresses vendor-picked document/ID photos so uploads stay under the
/// backend's request size limit (nginx `client_max_body_size` rejects
/// oversized multipart uploads with a 413).
class ImageCompressionUtils {
  ImageCompressionUtils._();

  static const int defaultMaxBytes = 10 * 1024 * 1024; // 10 MB

  /// Returns [file] unchanged if it's already within [maxBytes]; otherwise
  /// re-encodes it (dropping quality, then dimensions, if needed) and
  /// returns a new compressed file alongside the original. Falls back to
  /// the original file if decoding fails, so a bad image never blocks
  /// upload outright.
  static Future<File> compressIfNeeded(
    File file, {
    int maxBytes = defaultMaxBytes,
  }) async {
    final originalSize = await file.length();
    if (originalSize <= maxBytes) return file;

    final compressed = await compute(
      _compress,
      _CompressJob(bytes: await file.readAsBytes(), maxBytes: maxBytes),
    );
    if (compressed == null) {
      appLogger.w(
        'ImageCompressionUtils.compressIfNeeded → decode failed, uploading original (${originalSize}B)',
      );
      return file;
    }

    final outFile = File(
      '${file.parent.path}/compressed_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await outFile.writeAsBytes(compressed, flush: true);
    appLogger.d(
      'ImageCompressionUtils.compressIfNeeded → ${originalSize}B -> ${compressed.lengthInBytes}B',
    );
    return outFile;
  }

  static Uint8List? _compress(_CompressJob job) {
    var image = img.decodeImage(job.bytes);
    if (image == null) return null;

    var quality = 90;
    var encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));

    while (encoded.lengthInBytes > job.maxBytes && quality > 30) {
      quality -= 15;
      encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));
    }

    while (encoded.lengthInBytes > job.maxBytes &&
        image!.width > 800 &&
        image.height > 800) {
      image = img.copyResize(image, width: (image.width * 0.8).round());
      quality = 80;
      encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));
      while (encoded.lengthInBytes > job.maxBytes && quality > 30) {
        quality -= 15;
        encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));
      }
    }

    return encoded;
  }
}

class _CompressJob {
  final Uint8List bytes;
  final int maxBytes;

  const _CompressJob({required this.bytes, required this.maxBytes});
}
