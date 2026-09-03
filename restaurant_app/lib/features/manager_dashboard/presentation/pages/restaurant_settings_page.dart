import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../restaurant/presentation/controllers/restaurant_controller.dart';

/// Manager-only page for editing the single restaurant profile row.
///
/// Edits the Supabase `restaurants` row tied to
/// `SupabaseConfig.defaultRestaurantId` only — no insert, no new branch,
/// no logo upload (per product decision). `total_tables` is manual but
/// compared against the actual `tables` count with an explicit sync action.
class RestaurantSettingsPage extends ConsumerStatefulWidget {
  const RestaurantSettingsPage({super.key});

  @override
  ConsumerState<RestaurantSettingsPage> createState() =>
      _RestaurantSettingsPageState();
}

class _RestaurantSettingsPageState
    extends ConsumerState<RestaurantSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _openTime = TextEditingController();
  final _closeTime = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _totalTables = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _openTime.dispose();
    _closeTime.dispose();
    _lat.dispose();
    _lng.dispose();
    _totalTables.dispose();
    super.dispose();
  }

  void _fillFromState(RestaurantSettingsState s) {
    if (_initialized) return;
    _initialized = true;
    _name.text = s.restaurant.name;
    _address.text = s.restaurant.address;
    _phone.text = s.restaurant.phone;
    _openTime.text = s.restaurant.hours.openTime;
    _closeTime.text = s.restaurant.hours.closeTime;
    _lat.text = s.restaurant.latitude.toString();
    _lng.text = s.restaurant.longitude.toString();
    _totalTables.text = s.restaurant.totalTables.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(restaurantSettingsControllerProvider.notifier)
          .loadActualTablesCount();
    });
  }

  int? _parseTimeToMinutes(String time) {
    final parts = time.trim().split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return h * 60 + m;
  }

  String? _validateTime(String? v) {
    if (v == null || v.trim().isEmpty) return 'مطلوب (مثال 10:00)';
    final ok = RegExp(r'^\d{1,2}:\d{2}$').hasMatch(v.trim());
    return ok ? null : 'صيغة الوقت HH:MM';
  }

  String? _validateCloseTime(String? v) {
    final basic = _validateTime(v);
    if (basic != null) return basic;
    final openM = _parseTimeToMinutes(_openTime.text);
    final closeM = _parseTimeToMinutes(v ?? '');
    if (openM != null && closeM != null && openM >= closeM) {
      return 'يجب أن يكون بعد الفتح';
    }
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'يرجى إدخال رقم الهاتف';
    final clean = v.trim().replaceAll(' ', '');
    final ok = RegExp(r'^(\+201|01)[0125]\d{8}$').hasMatch(clean);
    return ok ? null : 'رقم مصري صالح (مثال: 01012345678)';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final actual =
        ref.read(restaurantSettingsControllerProvider).valueOrNull?.actualTablesCount;
    final manual = int.tryParse(_totalTables.text.trim()) ?? -1;
    if (actual != null && manual < actual) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'عدد الطاولات اليدوي ($manual) أقل من الفعلي في النظام ($actual). زوده أو اعمل مزامنة.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await ref
        .read(restaurantSettingsControllerProvider.notifier)
        .save(
          name: _name.text,
          address: _address.text,
          phone: _phone.text,
          openTime: _openTime.text.trim(),
          closeTime: _closeTime.text.trim(),
          latitude: double.tryParse(_lat.text.trim()) ?? 0.0,
          longitude: double.tryParse(_lng.text.trim()) ?? 0.0,
          totalTables: manual,
        );
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'تم حفظ بيانات المطعم بنجاح' : 'فشل الحفظ — تحقق من الحقول أو الاتصال'),
          backgroundColor:
              ok ? const Color(0xFF10B981) : Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restaurantSettingsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('بيانات المطعم')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'فشل تحميل بيانات المطعم من Supabase',
          errorDetail: e,
          onRetry: () =>
              ref.refresh(restaurantSettingsControllerProvider),
        ),
        data: (s) {
          _fillFromState(s);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (s.actualTablesCount != null)
                  Card(
                    color: s.hasDivergence
                        ? Colors.amber.shade50
                        : Colors.green.shade50,
                    child: ListTile(
                      leading: Icon(
                        s.hasDivergence
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        color: s.hasDivergence
                            ? Colors.amber.shade800
                            : Colors.green.shade700,
                      ),
                      title: Text(
                        'المعلن (يدوي): ${s.restaurant.totalTables} • الفعلي (جدول الطاولات): ${s.actualTablesCount}',
                      ),
                      subtitle: s.hasDivergence
                          ? const Text(
                              'يوجد فرق بين الرقم اليدوي والفعلي. المزامنة تتم بضغطة صريحة منك فقط.')
                          : const Text('الرقمان متطابقان.'),
                      trailing: s.hasDivergence
                          ? TextButton(
                              onPressed: () => ref
                                  .read(
                                      restaurantSettingsControllerProvider
                                          .notifier)
                                  .syncTotalTablesFromActual()
                                  .then((_) => setState(
                                      () => _initialized = false)),
                              child: const Text('مزامنة من الطاولات'),
                            )
                          : null,
                    ),
                  ),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'اسم المطعم *',
                    prefixIcon: Icon(Icons.storefront_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'يرجى إدخال الاسم'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(
                    labelText: 'العنوان *',
                    prefixIcon: Icon(Icons.place_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'يرجى إدخال العنوان'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'التليفون *',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                  validator: _validatePhone,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _openTime,
                        decoration: const InputDecoration(
                          labelText: 'الفتح (HH:MM) *',
                          prefixIcon: Icon(Icons.schedule_rounded),
                        ),
                        validator: _validateTime,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _closeTime,
                        decoration: const InputDecoration(
                          labelText: 'الإغلاق (HH:MM) *',
                          prefixIcon: Icon(Icons.schedule_rounded),
                        ),
                        validator: _validateCloseTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lat,
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'خط العرض',
                          prefixIcon: Icon(Icons.map_rounded),
                        ),
                        validator: (v) {
                          final d = double.tryParse(v?.trim() ?? '');
                          if (d == null || d < -90 || d > 90) {
                            return 'من -90 إلى 90';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _lng,
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'خط الطول',
                          prefixIcon: Icon(Icons.map_rounded),
                        ),
                        validator: (v) {
                          final d = double.tryParse(v?.trim() ?? '');
                          if (d == null || d < -180 || d > 180) {
                            return 'من -180 إلى 180';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _totalTables,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'عدد الطاولات (يدوي) *',
                    prefixIcon: Icon(Icons.table_restaurant_rounded),
                    helperText: 'رقم معلن يدوياً — يقارن مع العدد الفعلي أعلاه',
                  ),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n < 0) return 'رقم غير صالح';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('حفظ بيانات المطعم'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
