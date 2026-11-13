import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Selected KYC document metadata and bytes captured from the device file picker.
class PickedKycDocument {
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  final String localFileRef;
  final Uint8List? fileBytes;

  const PickedKycDocument({
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.localFileRef,
    this.fileBytes,
  });
}

sealed class KycPickResult {
  const KycPickResult();
}

final class KycPickSuccess extends KycPickResult {
  final PickedKycDocument document;
  const KycPickSuccess(this.document);
}

final class KycPickCancelled extends KycPickResult {
  const KycPickCancelled();
}

final class KycPickError extends KycPickResult {
  final String message;
  const KycPickError(this.message);
}

/// Opens the actual device file browser using `file_picker` for PDF, JPG, and
/// PNG documents up to 5 MB.
class KycDeviceFilePicker {
  static const int maxFileSizeBytes = 5 * 1024 * 1024;
  static const List<String> allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

  static Future<KycPickResult> pickDocument() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (file == null) {
        return const KycPickCancelled();
      }

      final name = file.name.trim();
      final ext = _extractExtension(name, file.extension);
      final mimeType = _mimeTypeForExtension(ext);

      if (mimeType == null) {
        return const KycPickError(
          'Unsupported file format. Only PDF, JPG, and PNG files are allowed.',
        );
      }

      final reportedSize = file.lengthSync() ?? await file.length();
      if (reportedSize != null && reportedSize > maxFileSizeBytes) {
        return const KycPickError(
          'Selected file exceeds the maximum allowed size of 5 MB.',
        );
      }

      final bytes = await file.readAsBytes();
      final size = reportedSize ?? bytes.length;
      if (size <= 0) {
        return const KycPickError('Selected file is empty.');
      }
      if (size > maxFileSizeBytes) {
        return const KycPickError(
          'Selected file exceeds the maximum allowed size of 5 MB.',
        );
      }

      final pathRef = kIsWeb
          ? file.uri.toString().trim()
          : (file.path ?? file.uri.toString()).trim();
      if (pathRef.isEmpty && bytes.isEmpty) {
        return const KycPickError(
          'Unable to read selected file reference or bytes.',
        );
      }

      return KycPickSuccess(
        PickedKycDocument(
          fileName: name,
          mimeType: mimeType,
          fileSizeBytes: size,
          localFileRef: pathRef.isNotEmpty ? pathRef : 'memory://$name',
          fileBytes: bytes,
        ),
      );
    } catch (e) {
      return KycPickError('Unable to select file from device: $e');
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
    return switch (ext) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      _ => null,
    };
  }
}
