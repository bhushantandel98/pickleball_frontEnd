import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_profile_entities.dart';

/// Selected KYC document metadata produced by [KycDocumentPickerDialog].
class PickedKycDocument {
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  final String localFileRef;

  const PickedKycDocument({
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.localFileRef,
  });
}

/// Structured PDF/Image document picker dialog using existing Flutter widgets.
///
/// Captures file name, MIME type, size, and local mock file reference without
/// claiming remote server upload when running in mock mode.
class KycDocumentPickerDialog extends StatelessWidget {
  final SellerDocumentType documentType;

  const KycDocumentPickerDialog({super.key, required this.documentType});

  static Future<PickedKycDocument?> show(
    BuildContext context, {
    required SellerDocumentType documentType,
  }) {
    return showDialog<PickedKycDocument>(
      context: context,
      builder: (_) => KycDocumentPickerDialog(documentType: documentType),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candidates = _sampleCandidatesFor(documentType);

    return AlertDialog(
      title: Text('Select ${documentType.label}'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supported formats: PDF (.pdf), JPEG (.jpg), PNG (.png) up to 5 MB. '
              'Mock mode attaches a local file reference pending backend upload.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...candidates.map(
              (c) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  c.mimeType == 'application/pdf'
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                ),
                title: Text(c.fileName),
                subtitle: Text(
                  '${c.mimeType} • ${(c.fileSizeBytes / 1024).ceil()} KB',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pop(c),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  List<PickedKycDocument> _sampleCandidatesFor(SellerDocumentType type) {
    final slug = type.name;
    return [
      PickedKycDocument(
        fileName: '${slug}_verified_copy.pdf',
        mimeType: 'application/pdf',
        fileSizeBytes: 342016,
        localFileRef: 'local://kyc/device/${slug}_verified_copy.pdf',
      ),
      PickedKycDocument(
        fileName: '${slug}_scan_front.jpg',
        mimeType: 'image/jpeg',
        fileSizeBytes: 215040,
        localFileRef: 'local://kyc/device/${slug}_scan_front.jpg',
      ),
      PickedKycDocument(
        fileName: '${slug}_photo.png',
        mimeType: 'image/png',
        fileSizeBytes: 489472,
        localFileRef: 'local://kyc/device/${slug}_photo.png',
      ),
    ];
  }
}
