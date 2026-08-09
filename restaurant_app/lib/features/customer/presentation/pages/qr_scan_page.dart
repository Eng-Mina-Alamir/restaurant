import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/spacing.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';

/// The expected QR code format is a plain table ID string, e.g. `table-3`.
/// When a valid code is detected the user is navigated to the customer home
/// with the table pre-selected in the cart controller.
class QrScanPage extends ConsumerStatefulWidget {
  const QrScanPage({super.key});

  @override
  ConsumerState<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends ConsumerState<QrScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;
    final raw = barcode.rawValue;
    if (raw == null || raw.isEmpty) return;

    _scanned = true;
    _controller.stop();

    // Set the scanned table id in the cart controller so the order
    // created from the cart will be associated with the correct table.
    ref.read(cartControllerProvider.notifier).setTableId(raw);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم التعرف على الطاولة: $raw'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Go to customer home – the cart is already linked to the table.
    context.go('/customer');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('مسح رمز QR الطاولة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'تشغيل/إيقاف الفلاش',
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            tooltip: 'تبديل الكاميرا',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── camera feed ──────────────────────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // ── scan frame overlay ───────────────────────────────────────────
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary, width: 3),
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              child: Stack(
                children: [
                  // corner decorations
                  _Corner(top: true, left: true, color: colorScheme.primary),
                  _Corner(top: true, left: false, color: colorScheme.primary),
                  _Corner(top: false, left: true, color: colorScheme.primary),
                  _Corner(top: false, left: false, color: colorScheme.primary),
                ],
              ),
            ),
          ),

          // ── instruction text ─────────────────────────────────────────────
          Positioned(
            bottom: AppSpacing.xl * 2,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Icon(Icons.qr_code_scanner, color: Colors.white70, size: 32),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'وجّه الكاميرا نحو رمز QR الموجود على الطاولة',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Corner decoration widget ──────────────────────────────────────────────────

class _Corner extends StatelessWidget {
  const _Corner({
    required this.top,
    required this.left,
    required this.color,
  });

  final bool top;
  final bool left;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top ? -1 : null,
      bottom: top ? null : -1,
      left: left ? -1 : null,
      right: left ? null : -1,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? BorderSide(color: color, width: 4)
                : BorderSide.none,
            bottom: !top
                ? BorderSide(color: color, width: 4)
                : BorderSide.none,
            left: left
                ? BorderSide(color: color, width: 4)
                : BorderSide.none,
            right: !left
                ? BorderSide(color: color, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
