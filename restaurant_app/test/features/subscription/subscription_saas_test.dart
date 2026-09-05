import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/tenant/tenant_context.dart';
import 'package:restaurant_app/features/auth/domain/entities/user_entity.dart';
import 'package:restaurant_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:restaurant_app/features/subscription/domain/entities/subscription_plan.dart';
import 'package:restaurant_app/features/subscription/presentation/widgets/subscription_status_card.dart';
import 'package:restaurant_app/features/subscription/presentation/widgets/upgrade_plan_dialog.dart';

void main() {
  group('SaaS Subscription & Entitlements Unit Tests', () {
    test('Starter Tier allows POS and KDS but restricts Driver Tracking and Chat', () {
      expect(
        SubscriptionEntitlements.isFeatureAllowed(
          SubscriptionTier.starter,
          SaaSFeature.posCheckout,
        ),
        isTrue,
      );
      expect(
        SubscriptionEntitlements.isFeatureAllowed(
          SubscriptionTier.starter,
          SaaSFeature.kdsKitchen,
        ),
        isTrue,
      );
      expect(
        SubscriptionEntitlements.isFeatureAllowed(
          SubscriptionTier.starter,
          SaaSFeature.liveDriverGpsTracking,
        ),
        isFalse,
      );
      expect(
        SubscriptionEntitlements.isFeatureAllowed(
          SubscriptionTier.starter,
          SaaSFeature.inAppCustomerChat,
        ),
        isFalse,
      );
    });

    test('Pro Tier unlocks Driver Tracking, Chat, and Loyalty', () {
      expect(
        SubscriptionEntitlements.isFeatureAllowed(
          SubscriptionTier.pro,
          SaaSFeature.liveDriverGpsTracking,
        ),
        isTrue,
      );
      expect(
        SubscriptionEntitlements.isFeatureAllowed(
          SubscriptionTier.pro,
          SaaSFeature.inAppCustomerChat,
        ),
        isTrue,
      );
      expect(
        SubscriptionEntitlements.isFeatureAllowed(
          SubscriptionTier.pro,
          SaaSFeature.loyaltyAndCoupons,
        ),
        isTrue,
      );
      expect(
        SubscriptionEntitlements.isFeatureAllowed(
          SubscriptionTier.pro,
          SaaSFeature.multiBranchManagement,
        ),
        isFalse, // Multi-branch is Enterprise only
      );
    });

    test('Enterprise Tier unlocks all features including Multi-Branch', () {
      for (final feature in SaaSFeature.values) {
        expect(
          SubscriptionEntitlements.isFeatureAllowed(
            SubscriptionTier.enterprise,
            feature,
          ),
          isTrue,
        );
      }
    });

    test('SubscriptionTier.fromString parses correctly with fallback', () {
      expect(SubscriptionTier.fromString('starter'), equals(SubscriptionTier.starter));
      expect(SubscriptionTier.fromString('pro'), equals(SubscriptionTier.pro));
      expect(SubscriptionTier.fromString('enterprise'), equals(SubscriptionTier.enterprise));
      expect(SubscriptionTier.fromString('unknown_tier'), equals(SubscriptionTier.pro));
    });
  });

  group('TenantContext Resolution Tests', () {
    test('currentRestaurantIdProvider resolves user restaurantId when authenticated', () {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _StubAuthController(
              AuthState(
                status: AuthStatus.authenticated,
                user: UserEntity(
                  id: 'u1',
                  name: 'Owner',
                  email: 'owner@test.com',
                  phone: '0501234567',
                  role: UserRole.admin,
                  restaurantId: 'custom-tenant-uuid-999',
                  createdAt: DateTime.now(),
                ),
              ),
            ),
          ),
        ],
      );

      final restaurantId = container.read(currentRestaurantIdProvider);
      expect(restaurantId, equals('custom-tenant-uuid-999'));
    });

    test('currentRestaurantIdProvider falls back to default when unauthenticated', () {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _StubAuthController(
              const AuthState(status: AuthStatus.unauthenticated),
            ),
          ),
        ],
      );

      final restaurantId = container.read(currentRestaurantIdProvider);
      expect(restaurantId, isNotEmpty);
    });
  });

  group('Subscription UI Widgets Tests', () {
    testWidgets('SubscriptionStatusCard renders with active trial badge and upgrade button',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SubscriptionStatusCard(),
            ),
          ),
        ),
      );

      expect(find.text('باقة المحترفين (Pro)'), findsOneWidget);
      expect(find.text('نشط - تجربة مجانية'), findsOneWidget);
      expect(find.text('ترقية الباقة'), findsOneWidget);
    });

    testWidgets('UpgradePlanDialog shows all 3 subscription plans', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UpgradePlanDialog(),
            ),
          ),
        ),
      );

      expect(find.text('باقات الاشتراك والترقية السحابية'), findsOneWidget);
      expect(find.text('باقة المبتدئين (Starter)'), findsOneWidget);
      expect(find.text('باقة المحترفين (Pro)'), findsOneWidget);
      expect(find.text('باقة سلاسل المطاعم (Enterprise)'), findsOneWidget);
    });
  });
}

class _StubAuthController extends StateNotifier<AuthState>
    implements AuthController {
  _StubAuthController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
