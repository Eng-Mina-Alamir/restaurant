import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/spacing.dart';

/// Widget that lets a driver take or pick a photo to document delivery
/// completion.
///
/// Pass [onPhotoSelected] to receive the captured [File].
class DeliveryPhotoCapture extends StatefulWidget {
  const DeliveryPhotoCapture({
    super.key,
    required this.onPhotoSelected,
    this.initialPhoto,
  });

  final ValueChanged<File?> onPhotoSelected;
  final File? initialPhoto;

  @override
  State<DeliveryPhotoCapture> createState() => _DeliveryPhotoCaptureState();
}

class _DeliveryPhotoCaptureState extends State<DeliveryPhotoCapture> {
  final ImagePicker _picker = ImagePicker();
  File? _photo;

  @override
  void initState() {
    super.initState();
    _photo = widget.initialPhoto;
  }

  Future<void> _capture(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
    if (picked == null) return;
    final file = File(picked.path);
    setState(() => _photo = file);
    widget.onPhotoSelected(file);
  }

  void _remove() {
    setState(() => _photo = null);
    widget.onPhotoSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_camera, color: colorScheme.primary, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'صورة توثيق التسليم',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        if (_photo != null) ...[
          // Photo preview
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.md),
                child: Image.file(
                  _photo!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: GestureDetector(
                  onTap: _remove,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('إعادة التصوير'),
            onPressed: () => _capture(ImageSource.camera),
          ),
        ] else ...[
          // Placeholder card
          GestureDetector(
            onTap: () => _showSourcePicker(context),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.5),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.md),
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 40,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'اضغط لالتقاط صورة التسليم',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('الكاميرا'),
                  onPressed: () => _capture(ImageSource.camera),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('المعرض'),
                  onPressed: () => _capture(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showSourcePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('الكاميرا'),
              onTap: () {
                Navigator.pop(context);
                _capture(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('اختيار من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _capture(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
