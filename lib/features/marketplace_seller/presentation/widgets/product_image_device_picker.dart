import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Result returned when selecting a product image from the seller's device.
sealed class ProductImagePickResult {
  const ProductImagePickResult();
}

class ProductImagePickSuccess extends ProductImagePickResult {
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  final String localFileRef;
  final Uint8List fileBytes;

  const ProductImagePickSuccess({
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.localFileRef,
    required this.fileBytes,
  });
}

class ProductImagePickCancelled extends ProductImagePickResult {
  const ProductImagePickCancelled();
}

class ProductImagePickError extends ProductImagePickResult {
  final String message;

  const ProductImagePickError(this.message);
}

/// Opens the actual device file browser using `file_picker` for JPG, PNG, and
/// WEBP product images up to 5 MB.
class ProductImageDevicePicker {
  static const int maxFileSizeBytes = 5 * 1024 * 1024;
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  static Future<ProductImagePickResult> pickImage() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (file == null) {
        return const ProductImagePickCancelled();
      }

      final name = file.name.trim();
      final ext = _extractExtension(name, file.extension);
      final mimeType = _mimeTypeForExtension(ext);
      if (mimeType == null) {
        return const ProductImagePickError(
          'Unsupported image format. Please select a JPG, PNG, or WEBP file.',
        );
      }

      final reportedSize = file.lengthSync() ?? await file.length();
      if (reportedSize != null && reportedSize > maxFileSizeBytes) {
        return const ProductImagePickError(
          'Selected image exceeds the maximum allowed size of 5 MB.',
        );
      }

      final bytes = await file.readAsBytes();
      final size = reportedSize ?? bytes.length;
      if (size <= 0 || bytes.isEmpty) {
        return const ProductImagePickError('Selected image file is empty.');
      }
      if (size > maxFileSizeBytes) {
        return const ProductImagePickError(
          'Selected image exceeds the maximum allowed size of 5 MB.',
        );
      }

      final pathRef = kIsWeb
          ? file.uri.toString().trim()
          : (file.path ?? file.uri.toString()).trim();

      return ProductImagePickSuccess(
        fileName: name,
        mimeType: mimeType,
        fileSizeBytes: size,
        localFileRef: pathRef.isNotEmpty ? pathRef : 'memory://$name',
        fileBytes: bytes,
      );
    } catch (e) {
      return ProductImagePickError('Unable to select image from device: $e');
    }
  }

  static String _extractExtension(String fileName, String? reportedExt) {
    if (reportedExt != null && reportedExt.trim().isNotEmpty) {
      return reportedExt.trim().toLowerCase();
    }
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  static String? _mimeTypeForExtension(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }
}
