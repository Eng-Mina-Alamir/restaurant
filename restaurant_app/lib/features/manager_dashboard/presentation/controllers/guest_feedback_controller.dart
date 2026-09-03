import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/app_config.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/guest_feedback_entity.dart';

/// State of customer feedback, CSAT metrics, and complaint resolution.
class GuestFeedbackState {
  const GuestFeedbackState({
    this.feedbacks = const [],
  });

  final List<GuestFeedback> feedbacks;

  List<GuestFeedback> get unresolvedComplaints =>
      feedbacks.where((f) => f.isNegative && !f.isResolved).toList();

  FeedbackMetrics get metrics {
    if (feedbacks.isEmpty) {
      return const FeedbackMetrics(
        averageOverallRating: 5.0,
        averageFoodQuality: 5.0,
        averageServiceSpeed: 5.0,
        averageCleanliness: 5.0,
        totalReviewsCount: 0,
        csatPercentage: 100.0,
        unresolvedComplaintsCount: 0,
      );
    }

    final total = feedbacks.length;
    final overallSum = feedbacks.fold<int>(0, (acc, f) => acc + f.overallRating);
    final foodSum = feedbacks.fold<int>(0, (acc, f) => acc + f.foodQualityRating);
    final speedSum = feedbacks.fold<int>(0, (acc, f) => acc + f.serviceSpeedRating);
    final cleanSum = feedbacks.fold<int>(0, (acc, f) => acc + f.cleanlinessRating);

    final positiveCount = feedbacks.where((f) => f.overallRating >= 4).length;
    final csat = (positiveCount / total) * 100;

    return FeedbackMetrics(
      averageOverallRating: double.parse((overallSum / total).toStringAsFixed(1)),
      averageFoodQuality: double.parse((foodSum / total).toStringAsFixed(1)),
      averageServiceSpeed: double.parse((speedSum / total).toStringAsFixed(1)),
      averageCleanliness: double.parse((cleanSum / total).toStringAsFixed(1)),
      totalReviewsCount: total,
      csatPercentage: double.parse(csat.toStringAsFixed(1)),
      unresolvedComplaintsCount: unresolvedComplaints.length,
    );
  }

  GuestFeedbackState copyWith({
    List<GuestFeedback>? feedbacks,
  }) {
    return GuestFeedbackState(
      feedbacks: feedbacks ?? this.feedbacks,
    );
  }
}

/// Controller managing guest ratings and resolving complaints.
class GuestFeedbackController extends StateNotifier<GuestFeedbackState> {
  GuestFeedbackController({SupabaseClient? supabase})
      : _supabase = supabase,
        super(
          GuestFeedbackState(
            feedbacks: List.from(GuestFeedback.demoFeedbacks),
          ),
        ) {
    if (_supabase != null) {
      _loadFromSupabase();
    }
  }

  final SupabaseClient? _supabase;

  Future<void> _loadFromSupabase() async {
    final client = _supabase;
    if (client == null) return;
    try {
      final rows = await client
          .from('guest_feedbacks')
          .select()
          .order('created_at', ascending: false);

      if (rows.isNotEmpty) {
        final List<GuestFeedback> list = [];
        for (final r in (rows as List)) {
          final m = Map<String, dynamic>.from(r as Map);
          list.add(
            GuestFeedback(
              id: m['id']?.toString() ?? '',
              orderId: m['order_id']?.toString() ?? '1',
              customerName: m['customer_name']?.toString() ?? '',
              customerPhone: m['customer_phone']?.toString() ?? '',
              overallRating: (m['overall_rating'] as num?)?.toInt() ?? 5,
              foodQualityRating: (m['food_quality_rating'] as num?)?.toInt() ?? 5,
              serviceSpeedRating: (m['service_speed_rating'] as num?)?.toInt() ?? 5,
              cleanlinessRating: (m['cleanliness_rating'] as num?)?.toInt() ?? 5,
              comment: m['comment']?.toString() ?? '',
              createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
              isResolved: m['is_resolved'] as bool? ?? false,
              resolutionNotes: m['resolution_notes']?.toString(),
              compensationCouponCode: m['compensation_coupon_code']?.toString(),
            ),
          );
        }
        state = state.copyWith(feedbacks: list);
      }
    } catch (e) {
      AppLogger.warning('GuestFeedbackController loadFromSupabase error: $e');
    }
  }

  /// Adds a new guest feedback.
  GuestFeedback addFeedback(GuestFeedback feedback) {
    state = state.copyWith(feedbacks: [feedback, ...state.feedbacks]);

    final client = _supabase;
    if (client != null) {
      Future.microtask(() async {
        try {
          await client.from('guest_feedbacks').insert({
            'id': feedback.id,
            'restaurant_id': '1e08b47c-15be-4604-a913-431af7fbd54f',
            'customer_name': feedback.customerName,
            'customer_phone': feedback.customerPhone,
            'order_id': int.tryParse(feedback.orderId),
            'overall_rating': feedback.overallRating,
            'food_quality_rating': feedback.foodQualityRating,
            'service_speed_rating': feedback.serviceSpeedRating,
            'cleanliness_rating': feedback.cleanlinessRating,
            'comment': feedback.comment,
            'is_resolved': feedback.isResolved,
            'resolution_notes': feedback.resolutionNotes,
            'compensation_coupon_code': feedback.compensationCouponCode,
            'created_at': feedback.createdAt.toIso8601String(),
          });
        } catch (e) {
          AppLogger.warning('GuestFeedback addFeedback sync error: $e');
        }
      });
    }

    return feedback;
  }

  /// Resolves a customer complaint with manager resolution notes and optional compensation coupon.
  void resolveComplaint({
    required String feedbackId,
    required String resolutionNotes,
    String? compensationCouponCode,
  }) {
    final updated = state.feedbacks.map((f) {
      if (f.id == feedbackId) {
        return f.copyWith(
          isResolved: true,
          resolutionNotes: resolutionNotes,
          compensationCouponCode: compensationCouponCode,
        );
      }
      return f;
    }).toList();

    state = state.copyWith(feedbacks: updated);

    final client = _supabase;
    if (client != null) {
      Future.microtask(() async {
        try {
          await client.from('guest_feedbacks').update({
            'is_resolved': true,
            'resolution_notes': resolutionNotes,
            'compensation_coupon_code': compensationCouponCode,
          }).eq('id', feedbackId);
        } catch (e) {
          AppLogger.warning('GuestFeedback resolveComplaint sync error: $e');
        }
      });
    }
  }
}

/// Riverpod provider for [GuestFeedbackController].
final guestFeedbackControllerProvider =
    StateNotifierProvider<GuestFeedbackController, GuestFeedbackState>((ref) {
      final supabase = AppConfig.useSupabase ? ref.watch(supabaseClientProvider) : null;
      return GuestFeedbackController(supabase: supabase);
    });
