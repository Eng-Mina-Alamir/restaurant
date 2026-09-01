import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../controllers/curbside_controller.dart';

/// Modal sheet for registering car details for Curbside Car Pickup.
class CurbsidePickupSheet extends ConsumerStatefulWidget {
  const CurbsidePickupSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CurbsidePickupSheet(),
    );
  }

  @override
  ConsumerState<CurbsidePickupSheet> createState() => _CurbsidePickupSheetState();
}

class _CurbsidePickupSheetState extends ConsumerState<CurbsidePickupSheet> {
  final _modelController = TextEditingController(text: 'كيا سبورتاج');
  final _colorController = TextEditingController(text: 'أبيض');
  final _plateController = TextEditingController(text: 'أ ب ج ١٢٣٤');
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _modelController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final curbsideInfo = ref.watch(curbsideControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  const Icon(Icons.directions_car_rounded, color: Color(0xFFC2410C)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'بيانات استلام الوجبة من السيارة',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (curbsideInfo != null)
                    TextButton(
                      onPressed: () {
                        ref.read(curbsideControllerProvider.notifier).clear();
                        Navigator.pop(context);
                      },
                      child: const Text('إلغاء', style: TextStyle(color: Colors.redAccent)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'أدخل مواصفات سيارتك لنتمكن من التعرف عليك وتسليمك الطلب فور وصولك بالخارج دون أن تنزل.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Divider(height: 24),

              TextField(
                controller: _modelController,
                decoration: InputDecoration(
                  labelText: 'نوع وموديل السيارة *',
                  hintText: 'مثال: هيونداي توسان / تويوتا كورولا',
                  prefixIcon: const Icon(Icons.car_repair_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _colorController,
                      decoration: InputDecoration(
                        labelText: 'لون السيارة *',
                        hintText: 'مثال: أبيض / أسود',
                        prefixIcon: const Icon(Icons.color_lens_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _plateController,
                      decoration: InputDecoration(
                        labelText: 'رقم اللوحة *',
                        hintText: 'مثال: س ص ع ٤٥٦',
                        prefixIcon: const Icon(Icons.pin_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'ملاحظة مكان التوقف (اختياري)',
                  hintText: 'مثال: واقف بجوار الصيدلية / مشغل الانتظار',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC2410C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    final model = _modelController.text.trim();
                    final color = _colorController.text.trim();
                    final plate = _plateController.text.trim();
                    if (model.isEmpty || color.isEmpty || plate.isEmpty) return;

                    ref.read(curbsideControllerProvider.notifier).setVehicleInfo(
                          carModel: model,
                          carColor: color,
                          licensePlate: plate,
                          parkingSpotNote: _noteController.text.trim(),
                        );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تسجيل بيانات السيارة للاستلام السريع!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('تأكيد بيانات السيارة', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
