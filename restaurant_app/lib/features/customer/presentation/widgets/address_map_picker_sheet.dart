import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mhj_maps/mhj_maps.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../delivery/presentation/widgets/live_tracking_map.dart';

/// Result returned from the interactive address map picker.
class AddressPickerResult {
  const AddressPickerResult({
    required this.latLng,
    required this.formattedAddress,
    this.street,
    this.city,
    this.district,
    this.distanceKmFromRestaurant,
  });

  final LatLng latLng;
  final String formattedAddress;
  final String? street;
  final String? city;
  final String? district;
  final double? distanceKmFromRestaurant;
}

/// A full-featured interactive address picker powered by [mhj_maps].
///
/// Gives the user full freedom to:
/// - 🔍 Search places with live autocomplete suggestions via Photon
/// - 📍 Tap anywhere on the map or drag the center pin
/// - 🏷️ Automatic reverse geocoding to resolve street & district names in Arabic
/// - 🛰️ Switch map themes (Satellite imagery, Streets, Dark mode, Topo)
/// - 🧭 Auto-detect current GPS location
/// - ⭕ Check delivery range from restaurant
class AddressMapPickerSheet extends StatefulWidget {
  const AddressMapPickerSheet({
    super.key,
    this.initialLatLng,
    this.restaurantLatLng = const LatLng(30.0444, 31.2357), // Downtown Cairo
    this.maxDeliveryRadiusKm = 25.0,
    this.title = 'تحديد عنوان التوصيل على الخريطة',
  });

  final LatLng? initialLatLng;
  final LatLng restaurantLatLng;
  final double maxDeliveryRadiusKm;
  final String title;

  /// Helper static method to open the picker as a bottom sheet.
  static Future<AddressPickerResult?> show(
    BuildContext context, {
    LatLng? initialLatLng,
    LatLng restaurantLatLng = const LatLng(30.0444, 31.2357),
    double maxDeliveryRadiusKm = 25.0,
  }) {
    return showModalBottomSheet<AddressPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddressMapPickerSheet(
        initialLatLng: initialLatLng,
        restaurantLatLng: restaurantLatLng,
        maxDeliveryRadiusKm: maxDeliveryRadiusKm,
      ),
    );
  }

  @override
  State<AddressMapPickerSheet> createState() => _AddressMapPickerSheetState();
}

class _AddressMapPickerSheetState extends State<AddressMapPickerSheet>
    with SingleTickerProviderStateMixin {
  final MhjMaps _mhjService = MhjMaps();
  final TextEditingController _searchCtrl = TextEditingController();
  MhjMapsMapController? _mapController;

  late LatLng _selectedLatLng;
  AppMapThemeOption _currentTheme = AppMapThemeOption.voyager;

  String _resolvedAddress = 'جارٍ تحديد اسم الموقع...';
  bool _isGeocoding = false;
  Timer? _debounceTimer;

  List<AutocompleteResult> _autocompleteResults = [];
  bool _isSearching = false;

  late AnimationController _pinAnimCtrl;
  late Animation<double> _pinBounceAnim;

  @override
  void initState() {
    super.initState();
    _selectedLatLng =
        widget.initialLatLng ??
        const LatLng(30.0626, 31.2497); // Zamalek/Cairo fallback

    _pinAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pinBounceAnim = Tween<double>(
      begin: 0,
      end: -14,
    ).animate(CurvedAnimation(parent: _pinAnimCtrl, curve: Curves.easeOut));

    _reverseGeocode(_selectedLatLng);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    _pinAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() => _isGeocoding = true);
    _pinAnimCtrl.forward().then((_) => _pinAnimCtrl.reverse());

    try {
      final res = await _mhjService
          .reverseGeocode(latLng.latitude, latLng.longitude)
          .timeout(const Duration(seconds: 4));

      if (!mounted) return;
      setState(() {
        _resolvedAddress = res.displayName.isNotEmpty
            ? res.displayName
            : 'موقع محدد (${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)})';
        _isGeocoding = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resolvedAddress =
            'الموقع المحدد (${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)})';
        _isGeocoding = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _autocompleteResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await _mhjService.autocomplete(query, limit: 5);
        if (!mounted) return;
        setState(() {
          _autocompleteResults = results;
          _isSearching = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _autocompleteResults = [];
          _isSearching = false;
        });
      }
    });
  }

  void _selectAutocompleteSuggestion(AutocompleteResult item) {
    FocusScope.of(context).unfocus();
    final newPos = LatLng(item.lat, item.lng);
    setState(() {
      _selectedLatLng = newPos;
      _resolvedAddress = item.displayName.isNotEmpty
          ? item.displayName
          : item.name;
      _autocompleteResults = [];
      _searchCtrl.text = item.name;
    });

    _mapController?.moveTo(
      MhjMapsLatLng(lat: newPos.latitude, lng: newPos.longitude),
      zoom: 16,
    );
  }

  Future<void> _locateCurrentPosition() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى منح إذن الوصول للموقع الجغرافي')),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentLatLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _selectedLatLng = currentLatLng);
      _mapController?.moveTo(
        MhjMapsLatLng(lat: pos.latitude, lng: pos.longitude),
        zoom: 16,
      );
      _reverseGeocode(currentLatLng);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر جلب موقعك الحالي تلقائياً')),
      );
    }
  }

  double get _distanceKm {
    const distCalc = Distance();
    return distCalc.as(
      LengthUnit.Kilometer,
      widget.restaurantLatLng,
      _selectedLatLng,
    );
  }

  bool get _isWithinRange => _distanceKm <= widget.maxDeliveryRadiusKm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Approved warm amber/orange step from the audited StatusColors palette.
    final warningColor = StatusColors.tone(
      SemanticTone.warning,
      theme.brightness,
    );
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Sheet Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pin_drop,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'إغلاق',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ── Live Autocomplete Search Bar ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن اسم الشارع أو المعلم أو الحي...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            tooltip: 'مسح البحث',
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _autocompleteResults = []);
                            },
                          )
                        : (_isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),

                // Autocomplete Suggestions List
                if (_autocompleteResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.26),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _autocompleteResults.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final item = _autocompleteResults[idx];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.location_on_outlined,
                            size: 20,
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            item.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall,
                          ),
                          onTap: () => _selectAutocompleteSuggestion(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Map View Area with Center Pin Overlay ───────────────────────
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MhjMapsMap(
                  key: ValueKey(_currentTheme.id),
                  center: MhjMapsLatLng(
                    lat: _selectedLatLng.latitude,
                    lng: _selectedLatLng.longitude,
                  ),
                  zoom: 15,
                  theme: _currentTheme.theme,
                  showZoomControls: false,
                  onMapCreated: (ctrl) => _mapController = ctrl,
                  onTap: (pos) {
                    final latlng = LatLng(pos.lat, pos.lng);
                    setState(() => _selectedLatLng = latlng);
                    _reverseGeocode(latlng);
                  },
                ),

                // Center Pin Indicator
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _pinBounceAnim,
                    builder: (_, _) => Transform.translate(
                      offset: Offset(0, _pinBounceAnim.value - 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.location_pin,
                              color: colorScheme.onPrimary,
                              size: 26,
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colorScheme.shadow.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Floating Map Controls (Theme Switcher & GPS Locate)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.md,
                  child: Column(
                    children: [
                      // Satellite / Theme Toggle
                      FloatingActionButton.small(
                        heroTag: 'picker_theme_toggle',
                        backgroundColor: theme.cardColor,
                        foregroundColor: colorScheme.onSurface,
                        tooltip: 'تبديل مظهر الخريطة (قمر صناعي / شوارع)',
                        onPressed: () {
                          setState(() {
                            if (_currentTheme == AppMapThemeOption.voyager) {
                              _currentTheme = AppMapThemeOption.satellite;
                            } else if (_currentTheme ==
                                AppMapThemeOption.satellite) {
                              _currentTheme = AppMapThemeOption.dark;
                            } else {
                              _currentTheme = AppMapThemeOption.voyager;
                            }
                          });
                        },
                        child: Icon(
                          _currentTheme == AppMapThemeOption.satellite
                              ? Icons.satellite_alt
                              : (_currentTheme == AppMapThemeOption.dark
                                    ? Icons.dark_mode
                                    : Icons.map),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // GPS My Location
                      FloatingActionButton.small(
                        heroTag: 'picker_gps_locate',
                        tooltip: 'موقعي الحالي',
                        onPressed: _locateCurrentPosition,
                        child: const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Address Confirmation Card ───────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.place,
                      color: _isWithinRange
                          ? colorScheme.primary
                          : warningColor,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'عنوان التوصيل المختار',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _isGeocoding
                              ? Row(
                                  children: [
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'جارٍ جلب تفاصيل العنوان...',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                )
                              : Text(
                                  _resolvedAddress,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Distance from Restaurant Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isWithinRange
                        ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : warningColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isWithinRange
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            size: 16,
                            color: _isWithinRange
                                ? colorScheme.primary
                                : warningColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isWithinRange
                                ? 'ضمن نطاق التوصيل المتاح (${_distanceKm.toStringAsFixed(1)} كم عن المطعم)'
                                : 'خارج نطاق التوصيل الأساسي (${_distanceKm.toStringAsFixed(1)} كم)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _isWithinRange
                                  ? colorScheme.primary
                                  : warningColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Confirm Selection Button
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('تأكيد هذا العنوان ومتابعة الطلب'),
                  onPressed: () {
                    final result = AddressPickerResult(
                      latLng: _selectedLatLng,
                      formattedAddress: _resolvedAddress,
                      distanceKmFromRestaurant: _distanceKm,
                    );
                    Navigator.pop(context, result);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
