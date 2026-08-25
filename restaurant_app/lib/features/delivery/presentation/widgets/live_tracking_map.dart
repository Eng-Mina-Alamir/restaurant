import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mhj_maps/mhj_maps.dart';

import '../../../../core/theme/spacing.dart';

/// Available map themes with localized Arabic labels and icons.
enum AppMapThemeOption {
  voyager(
    id: 'voyager',
    labelAr: 'الملاحة والشوارع',
    icon: Icons.navigation_outlined,
    theme: MhjMapsMapThemes.voyager,
  ),
  satellite(
    id: 'satellite',
    labelAr: 'قمر صناعي (Satellite)',
    icon: Icons.satellite_alt_outlined,
    theme: MhjMapsMapThemes.satellite,
  ),
  dark(
    id: 'dark',
    labelAr: 'الوضع الليلي الفاخر',
    icon: Icons.dark_mode_outlined,
    theme: MhjMapsMapThemes.darkElegant,
  ),
  cleanLight(
    id: 'clean_light',
    labelAr: 'التصميم البسيط (Clean)',
    icon: Icons.wb_sunny_outlined,
    theme: MhjMapsMapThemes.cleanLight,
  ),
  topographic(
    id: 'topographic',
    labelAr: 'تضاريس ومرتفعات',
    icon: Icons.terrain_outlined,
    theme: MhjMapsMapThemes.topographic,
  ),
  cycling(
    id: 'cycling',
    labelAr: 'مسارات الدراجات والسكوتر',
    icon: Icons.pedal_bike_outlined,
    theme: MhjMapsMapThemes.cycling,
  ),
  standard(
    id: 'standard',
    labelAr: 'الخريطة القياسية (OSM)',
    icon: Icons.map_outlined,
    theme: MhjMapsMapThemes.standard,
  );

  const AppMapThemeOption({
    required this.id,
    required this.labelAr,
    required this.icon,
    required this.theme,
  });

  final String id;
  final String labelAr;
  final IconData icon;
  final MhjMapsMapTheme theme;
}

/// Routing transport mode for calculating turn-by-turn paths.
enum RoutingMode {
  car(costing: 'auto', labelAr: 'سيارة / تاكسي', icon: Icons.directions_car),
  motorcycle(
    costing: 'bicycle',
    labelAr: 'موتوسيكل / سكوتر',
    icon: Icons.two_wheeler,
  ),
  pedestrian(
    costing: 'pedestrian',
    labelAr: 'مشياً على الأقدام',
    icon: Icons.directions_walk,
  );

  const RoutingMode({
    required this.costing,
    required this.labelAr,
    required this.icon,
  });

  final String costing;
  final String labelAr;
  final IconData icon;
}

/// Comprehensive, interactive live tracking and navigation map powered by [mhj_maps].
///
/// Features:
/// - 🛰️ Multi-theme switcher (Satellite imagery, Voyager, Dark matter, Topo, Bike lanes, etc.)
/// - 🧭 Multi-modal live routing via Valhalla (Car, Motorcycle/Scooter, Walking)
/// - 📍 Real-time turn-by-turn navigation HUD & maneuvers
/// - ⭕ Delivery zone coverage circle overlays (`addCircle`)
/// - 🎯 Smart camera controls (Fit route, Focus driver/restaurant/customer, North reset, GPS locate)
/// - 🚀 Resilient network handling with geodesic fallback
class LiveTrackingMap extends StatefulWidget {
  const LiveTrackingMap({
    super.key,
    required this.pickupLatLng,
    required this.deliveryLatLng,
    this.pickupLabel = 'المطعم',
    this.deliveryLabel = 'العميل',
    this.onLocationUpdate,
    this.initialTheme = AppMapThemeOption.voyager,
    this.showControls = true,
    this.showNavigationHud = true,
    this.showDeliveryRadius = false,
    this.deliveryRadiusMeters = 5000,
    this.interactive = true,
  });

  final LatLng pickupLatLng;
  final LatLng deliveryLatLng;
  final String pickupLabel;
  final String deliveryLabel;
  final ValueChanged<LatLng>? onLocationUpdate;
  final AppMapThemeOption initialTheme;
  final bool showControls;
  final bool showNavigationHud;
  final bool showDeliveryRadius;
  final double deliveryRadiusMeters;
  final bool interactive;

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> {
  final MhjMaps _mhjService = MhjMaps();
  MhjMapsMapController? _mapController;

  LatLng? _driverPosition;
  StreamSubscription<Position>? _locationSub;
  bool _locationPermitted = false;

  late AppMapThemeOption _currentTheme;
  RoutingMode _routingMode = RoutingMode.motorcycle;
  bool _showRadiusCircle = false;
  bool _showTurnByTurnSheet = false;

  // Route calculation state
  RouteResult? _routeResult;
  bool _isCalculatingRoute = false;
  List<MhjMapsLatLng> _currentPolyline = [];

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initialTheme;
    _showRadiusCircle = widget.showDeliveryRadius;
    _initLocation();
  }

  @override
  void didUpdateWidget(covariant LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickupLatLng != widget.pickupLatLng ||
        oldWidget.deliveryLatLng != widget.deliveryLatLng) {
      _calculateAndDrawRoute();
    }
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      final permitted =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!mounted) return;
      setState(() => _locationPermitted = permitted);

      if (!permitted) {
        _calculateAndDrawRoute();
        return;
      }

      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final pos = LatLng(current.latitude, current.longitude);
      setState(() => _driverPosition = pos);
      widget.onLocationUpdate?.call(pos);
      _updateMapOverlays();
      _calculateAndDrawRoute();

      _locationSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((p) {
            if (!mounted) return;
            final latlng = LatLng(p.latitude, p.longitude);
            setState(() => _driverPosition = latlng);
            widget.onLocationUpdate?.call(latlng);
            _updateMapOverlays();
          });
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationPermitted = true);
      _calculateAndDrawRoute();
    }
  }

  Future<void> _calculateAndDrawRoute() async {
    if (!mounted) return;
    setState(() => _isCalculatingRoute = true);

    final startPoint = _driverPosition != null
        ? MhjMapsLatLng(
            lat: _driverPosition!.latitude,
            lng: _driverPosition!.longitude,
          )
        : MhjMapsLatLng(
            lat: widget.pickupLatLng.latitude,
            lng: widget.pickupLatLng.longitude,
          );

    final endPoint = MhjMapsLatLng(
      lat: widget.deliveryLatLng.latitude,
      lng: widget.deliveryLatLng.longitude,
    );

    try {
      final result = await _mhjService
          .route(
            origin: startPoint,
            destination: endPoint,
            costing: _routingMode.costing,
          )
          .timeout(const Duration(seconds: 4));

      if (!mounted) return;
      setState(() {
        _routeResult = result;
        _currentPolyline = result.polyline;
        _isCalculatingRoute = false;
      });
      _updateMapOverlays();
    } catch (_) {
      // Fallback: direct route line when offline or API is unreachable
      if (!mounted) return;
      final fallbackLine = [startPoint, endPoint];
      setState(() {
        _currentPolyline = fallbackLine;
        _routeResult = null;
        _isCalculatingRoute = false;
      });
      _updateMapOverlays();
    }
  }

  void _updateMapOverlays() {
    final ctrl = _mapController;
    if (ctrl == null) return;

    ctrl.clearAll();

    // 1. Optional Delivery Radius Circle
    if (_showRadiusCircle) {
      ctrl.addCircle(
        center: MhjMapsLatLng(
          lat: widget.pickupLatLng.latitude,
          lng: widget.pickupLatLng.longitude,
        ),
        radiusMeters: widget.deliveryRadiusMeters,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        borderColor: Theme.of(context).colorScheme.primary,
        borderWidth: 2,
      );
    }

    // 2. Calculated Route Polyline
    if (_currentPolyline.isNotEmpty) {
      final routeColor = _currentTheme.theme.isDark
          ? const Color(0xFF00FF94)
          : Theme.of(context).colorScheme.primary;

      ctrl.drawRoute(
        _currentPolyline,
        color: routeColor,
        width: 5.0,
        borderColor: Colors.black26,
        borderWidth: 1.0,
      );
    }

    // 3. Pickup Restaurant Marker
    ctrl.addCustomMarker(
      position: MhjMapsLatLng(
        lat: widget.pickupLatLng.latitude,
        lng: widget.pickupLatLng.longitude,
      ),
      child: _MapMarker(
        icon: Icons.store_rounded,
        label: widget.pickupLabel,
        color: Colors.orange.shade800,
        badgeText: 'استلام',
      ),
    );

    // 4. Customer Destination Marker
    ctrl.addCustomMarker(
      position: MhjMapsLatLng(
        lat: widget.deliveryLatLng.latitude,
        lng: widget.deliveryLatLng.longitude,
      ),
      child: _MapMarker(
        icon: Icons.location_pin,
        label: widget.deliveryLabel,
        color: Colors.red.shade700,
        badgeText: 'تسليم',
      ),
    );

    // 5. Live Driver Marker
    if (_driverPosition != null) {
      ctrl.addCustomMarker(
        position: MhjMapsLatLng(
          lat: _driverPosition!.latitude,
          lng: _driverPosition!.longitude,
        ),
        child: _DriverDot(
          color: Theme.of(context).colorScheme.primary,
          vehicleIcon: _routingMode.icon,
        ),
      );
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  MhjMapsLatLng get _center => MhjMapsLatLng(
    lat:
        _driverPosition?.latitude ??
        (widget.pickupLatLng.latitude + widget.deliveryLatLng.latitude) / 2,
    lng:
        _driverPosition?.longitude ??
        (widget.pickupLatLng.longitude + widget.deliveryLatLng.longitude) / 2,
  );

  void _fitRouteBounds() {
    final ctrl = _mapController;
    if (ctrl == null) return;

    if (_currentPolyline.isNotEmpty) {
      ctrl.fitRoute(
        _currentPolyline,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      );
    } else {
      ctrl.fitMarkers(padding: const EdgeInsets.all(50));
    }
  }

  void _showThemeSelectorSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'اختر مظهر ونوع الخريطة',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final opt in AppMapThemeOption.values)
                  ChoiceChip(
                    avatar: Icon(opt.icon, size: 16),
                    label: Text(opt.labelAr),
                    selected: _currentTheme == opt,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _currentTheme = opt);
                        Navigator.pop(ctx);
                        _updateMapOverlays();
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Stack(
        children: [
          // ── MhjMaps Map Widget ──────────────────────────────────────────
          MhjMapsMap(
            key: ValueKey(_currentTheme.id),
            center: _center,
            zoom: 14,
            theme: _currentTheme.theme,
            showZoomControls: false,
            interactive: widget.interactive,
            onMapCreated: (controller) {
              _mapController = controller;
              _updateMapOverlays();
              _fitRouteBounds();
            },
          ),

          // ── Location denied overlay ──────────────────────────────────────
          if (!_locationPermitted)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_off,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'يرجى السماح بالوصول إلى الموقع للحصول على تتبع حي',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      icon: const Icon(Icons.my_location),
                      onPressed: _initLocation,
                      label: const Text('منح إذن الموقع'),
                    ),
                  ],
                ),
              ),
            ),

          // ── Top Navigation / ETA HUD ─────────────────────────────────────
          if (widget.showNavigationHud)
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              child: _NavigationHudCard(
                routeResult: _routeResult,
                routingMode: _routingMode,
                isCalculating: _isCalculatingRoute,
                onToggleManeuvers: () {
                  setState(() => _showTurnByTurnSheet = !_showTurnByTurnSheet);
                },
                onModeChanged: (mode) {
                  setState(() => _routingMode = mode);
                  _calculateAndDrawRoute();
                },
              ),
            ),

          // ── Turn-by-turn Step-by-Step Drawer ─────────────────────────────
          if (_showTurnByTurnSheet && _routeResult?.maneuvers != null)
            Positioned(
              top: 105,
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              bottom: 80,
              child: _TurnByTurnSheet(
                maneuvers: _routeResult!.maneuvers!,
                onClose: () => setState(() => _showTurnByTurnSheet = false),
              ),
            ),

          // ── Floating Action Toolbar ──────────────────────────────────────
          if (widget.showControls)
            Positioned(
              bottom: AppSpacing.md,
              right: AppSpacing.md,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Theme Switcher Button
                  _MapToolButton(
                    heroTag: 'mhj_theme_toggle_${widget.hashCode}',
                    icon: Icons.layers_outlined,
                    tooltip: 'تغيير شكل الخريطة (قمر صناعي / ليلي / ستريت)',
                    onPressed: _showThemeSelectorSheet,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Delivery Zone Radius Toggle
                  _MapToolButton(
                    heroTag: 'mhj_radius_toggle_${widget.hashCode}',
                    icon: _showRadiusCircle
                        ? Icons.radar
                        : Icons.radar_outlined,
                    tooltip: 'نطاق التوصيل الجغرافي',
                    color: _showRadiusCircle
                        ? colorScheme.primaryContainer
                        : null,
                    onPressed: () {
                      setState(() => _showRadiusCircle = !_showRadiusCircle);
                      _updateMapOverlays();
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Fit Whole Route Bounds
                  _MapToolButton(
                    heroTag: 'mhj_fit_route_${widget.hashCode}',
                    icon: Icons.fit_screen_outlined,
                    tooltip: 'ملاءمة كامل المسار على الشاشة',
                    onPressed: _fitRouteBounds,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Reset North / Compass
                  _MapToolButton(
                    heroTag: 'mhj_compass_${widget.hashCode}',
                    icon: Icons.explore_outlined,
                    tooltip: 'إعادة توجيه الشمال',
                    onPressed: () => _mapController?.resetRotation(),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Recenter to Current GPS Location
                  FloatingActionButton.small(
                    heroTag: 'locate_driver_mhj_${widget.hashCode}',
                    onPressed: () {
                      if (_driverPosition != null && _mapController != null) {
                        _mapController!.moveTo(
                          MhjMapsLatLng(
                            lat: _driverPosition!.latitude,
                            lng: _driverPosition!.longitude,
                          ),
                          zoom: 16,
                        );
                      } else {
                        _mapController?.moveTo(
                          MhjMapsLatLng(
                            lat: widget.pickupLatLng.latitude,
                            lng: widget.pickupLatLng.longitude,
                          ),
                          zoom: 15,
                        );
                      }
                    },
                    tooltip: 'موقعي الحالي',
                    child: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),

          // ── Zoom In / Out Controls ───────────────────────────────────────
          if (widget.showControls)
            Positioned(
              bottom: AppSpacing.md,
              left: AppSpacing.md,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapToolButton(
                    heroTag: 'mhj_zoom_in_${widget.hashCode}',
                    icon: Icons.add,
                    tooltip: 'تكبير',
                    onPressed: () => _mapController?.zoomIn(),
                  ),
                  const SizedBox(height: 4),
                  _MapToolButton(
                    heroTag: 'mhj_zoom_out_${widget.hashCode}',
                    icon: Icons.remove,
                    tooltip: 'تصغير',
                    onPressed: () => _mapController?.zoomOut(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Top Navigation & Route HUD ────────────────────────────────────────────────

class _NavigationHudCard extends StatelessWidget {
  const _NavigationHudCard({
    required this.routeResult,
    required this.routingMode,
    required this.isCalculating,
    required this.onToggleManeuvers,
    required this.onModeChanged,
  });

  final RouteResult? routeResult;
  final RoutingMode routingMode;
  final bool isCalculating;
  final VoidCallback onToggleManeuvers;
  final ValueChanged<RoutingMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasManeuvers =
        routeResult?.maneuvers != null && routeResult!.maneuvers!.isNotEmpty;

    return Card(
      elevation: 6,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Transport Mode Selector
                PopupMenuButton<RoutingMode>(
                  initialValue: routingMode,
                  tooltip: 'نوع وسيلة التنقل',
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      routingMode.icon,
                      size: 18,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  onSelected: onModeChanged,
                  itemBuilder: (ctx) => [
                    for (final mode in RoutingMode.values)
                      PopupMenuItem(
                        value: mode,
                        child: Row(
                          children: [
                            Icon(
                              mode.icon,
                              size: 18,
                              color: mode == routingMode
                                  ? colorScheme.primary
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              mode.labelAr,
                              style: TextStyle(
                                fontWeight: mode == routingMode
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),

                // ETA & Distance Information
                Expanded(
                  child: isCalculating
                      ? Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'جارٍ حساب أدق مسار...',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  routeResult?.durationText.isNotEmpty == true
                                      ? routeResult!.durationText
                                      : 'مسار مباشر',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                if (routeResult?.distanceText != null) ...[
                                  const Text(' • '),
                                  Text(
                                    routeResult!.distanceText,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              hasManeuvers
                                  ? routeResult!.maneuvers!.first.instruction
                                  : 'ملاحة حية مع حزمة mhj_maps',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),

                // Turn-by-Turn Maneuvers List Toggle Button
                if (hasManeuvers)
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted, size: 20),
                    tooltip: 'إرشادات المسار خطوة بخطوة',
                    onPressed: onToggleManeuvers,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Turn-by-Turn Maneuvers Sheet ──────────────────────────────────────────────

class _TurnByTurnSheet extends StatelessWidget {
  const _TurnByTurnSheet({required this.maneuvers, required this.onClose});

  final List<Maneuver> maneuvers;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.alt_route, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'إرشادات خطوة بخطوة (${maneuvers.length} خطوات)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.sm),
              itemCount: maneuvers.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, index) {
                final m = maneuvers[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: index == 0
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerLow,
                    foregroundColor: index == 0
                        ? Colors.white
                        : colorScheme.onSurface,
                    child: Icon(_getManeuverIcon(m.instruction), size: 14),
                  ),
                  title: Text(
                    m.instruction,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: index == 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    m.distanceText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getManeuverIcon(String instruction) {
    final lower = instruction.toLowerCase();
    if (lower.contains('right') || lower.contains('يمين')) {
      return Icons.turn_right;
    }
    if (lower.contains('left') || lower.contains('يسار')) {
      return Icons.turn_left;
    }
    if (lower.contains('roundabout') || lower.contains('دوار')) {
      return Icons.rotate_right;
    }
    if (lower.contains('arrive') || lower.contains('وصل')) {
      return Icons.flag;
    }
    return Icons.straight;
  }
}

// ── Map Floating Tool Button ──────────────────────────────────────────────────

class _MapToolButton extends StatelessWidget {
  const _MapToolButton({
    required this.heroTag,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final String heroTag;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Theme.of(context).cardColor,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, size: 20),
          ),
        ),
      ),
    );
  }
}

// ── Custom Map Pin & Driver Dot Markers ───────────────────────────────────────

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.icon,
    required this.label,
    required this.color,
    this.badgeText,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(7),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            if (badgeText != null)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    badgeText!,
                    style: const TextStyle(
                      fontSize: 7,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _DriverDot extends StatefulWidget {
  const _DriverDot({required this.color, this.vehicleIcon = Icons.two_wheeler});
  final Color color;
  final IconData vehicleIcon;

  @override
  State<_DriverDot> createState() => _DriverDotState();
}

class _DriverDotState extends State<_DriverDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.75, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _anim.value),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.6 * _anim.value),
              blurRadius: 18,
              spreadRadius: 4,
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Icon(widget.vehicleIcon, color: Colors.white, size: 20),
      ),
    );
  }
}
