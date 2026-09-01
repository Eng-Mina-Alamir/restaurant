import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_config.dart';
import '../../../../core/network/realtime_event.dart';
import '../../../../core/notifications/waiter_alert_service.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/supabase/supabase_realtime_service.dart';
import '../../../../core/utils/logger.dart';
import '../../data/repositories/in_memory_table_service_repository.dart';
import '../../data/repositories/supabase_table_service_repository.dart';
import '../../domain/entities/table_service_request.dart';
import '../../domain/repositories/table_service_repository.dart';

/// Provider for [TableServiceRepository].
final tableServiceRepositoryProvider = Provider<TableServiceRepository>((ref) {
  if (AppConfig.useSupabase) {
    return SupabaseTableServiceRepository(ref.watch(supabaseClientProvider));
  }
  return InMemoryTableServiceRepository();
});

/// Manages active in-restaurant table service requests (e.g. Call Waiter, Request Bill).
class TableServiceController extends StateNotifier<List<TableServiceRequest>> {
  TableServiceController(
    this._repository, {
    SupabaseRealtimeService? realtimeService,
    WaiterAlertService? waiterAlertService,
  }) : _realtimeService = realtimeService,
       _waiterAlertService = waiterAlertService,
       super(const []) {
    _loadActive();
    _initRealtime();
  }

  final TableServiceRepository _repository;
  final SupabaseRealtimeService? _realtimeService;
  final WaiterAlertService? _waiterAlertService;
  StreamSubscription<RealtimeEvent>? _realtimeSub;

  Future<void> _loadActive() async {
    final result = await _repository.getActiveRequests();
    if (!mounted) return;
    result.when(
      onLeft: (failure) {
        AppLogger.warning('Failed to load active table service requests: ${failure.message}');
      },
      onRight: (requests) {
        final existingUnpersisted =
            state.where((r) => !requests.any((rem) => rem.id == r.id)).toList();
        state = [...existingUnpersisted, ...requests];
      },
    );
  }

  void _initRealtime() {
    final service = _realtimeService;
    if (service == null) return;

    _realtimeSub = service.events.listen((event) {
      if (event.type == RealtimeEventType.tableServiceRequested) {
        try {
          final request = TableServiceRequest.fromJson(event.payload);
          if (state.any((r) => r.id == request.id)) return;
          state = [request, ...state];
          _waiterAlertService?.notifyReadyForPickup();
        } catch (e, st) {
          AppLogger.warning(
            'TableServiceController: malformed tableServiceRequested payload',
            error: e,
            stackTrace: st,
          );
        }
      } else if (event.type == RealtimeEventType.tableServiceHandled) {
        try {
          final requestId = event.payload['requestId']?.toString() ??
              event.payload['id']?.toString();
          if (requestId == null) return;
          final waiterId = event.payload['waiterId']?.toString() ??
              event.payload['handled_by_waiter_id']?.toString();
          final handledAtStr = event.payload['handledAt']?.toString() ??
              event.payload['handled_at']?.toString();
          final handledAt = handledAtStr != null
              ? DateTime.tryParse(handledAtStr) ?? DateTime.now()
              : DateTime.now();

          state = state.map((r) {
            if (r.id == requestId) {
              return r.copyWith(
                isHandled: true,
                handledAt: handledAt,
                handledByWaiterId: waiterId,
              );
            }
            return r;
          }).toList();
        } catch (e, st) {
          AppLogger.warning(
            'TableServiceController: malformed tableServiceHandled payload',
            error: e,
            stackTrace: st,
          );
        }
      }
    });
  }

  /// Sends a new table service/assistance request from a customer at a dining table.
  Future<TableServiceRequest> requestService({
    required String tableId,
    required int tableNumber,
    required TableServiceType type,
    String? note,
  }) async {
    final request = TableServiceRequest(
      id: 'REQ-${DateTime.now().millisecondsSinceEpoch}',
      tableId: tableId,
      tableNumber: tableNumber,
      type: type,
      note: note,
      requestedAt: DateTime.now(),
      isHandled: false,
    );

    state = [request, ...state];
    AppLogger.info(
      'TableServiceController: Table $tableNumber requested ${type.name}',
    );

    // Persist to database; Supabase Realtime delivers event to waiters
    await _repository.createRequest(request);
    return request;
  }

  /// Acknowledges and completes a table assistance request by a waiter.
  Future<void> acknowledgeService(String requestId, {String? waiterId}) async {
    final now = DateTime.now();
    state = state.map((r) {
      if (r.id == requestId) {
        return r.copyWith(
          isHandled: true,
          handledAt: now,
          handledByWaiterId: waiterId,
        );
      }
      return r;
    }).toList();

    AppLogger.info('TableServiceController: Request $requestId handled');

    // Persist to database; Supabase Realtime delivers update event to clients
    await _repository.acknowledgeRequest(
      requestId,
      waiterId: waiterId,
      handledAt: now,
    );
  }

  /// All active (unhandled) service requests.
  List<TableServiceRequest> get activeRequests =>
      state.where((r) => !r.isHandled).toList();

  /// Total count of active requests requiring waiter attention.
  int get activeRequestsCount => activeRequests.length;

  /// Active requests for a specific [tableId].
  List<TableServiceRequest> activeRequestsForTable(String tableId) =>
      state.where((r) => r.tableId == tableId && !r.isHandled).toList();

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }
}

/// Provider for [TableServiceController].
final tableServiceControllerProvider =
    StateNotifierProvider<TableServiceController, List<TableServiceRequest>>(
      (ref) => TableServiceController(
        ref.watch(tableServiceRepositoryProvider),
        realtimeService: ref.watch(supabaseRealtimeServiceProvider),
        waiterAlertService: ref.watch(waiterAlertServiceProvider),
      ),
    );
