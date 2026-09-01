import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  GuestFeedbackController()
      : super(
          GuestFeedbackState(
            feedbacks: List.from(GuestFeedback.demoFeedbacks),
          ),
        );

  /// Adds a new guest feedback.
  GuestFeedback addFeedback(GuestFeedback feedback) {
    state = state.copyWith(feedbacks: [feedback, ...state.feedbacks]);
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
  }
}

/// Riverpod provider for [GuestFeedbackController].
final guestFeedbackControllerProvider =
    StateNotifierProvider<GuestFeedbackController, GuestFeedbackState>((ref) {
      return GuestFeedbackController();
    });
