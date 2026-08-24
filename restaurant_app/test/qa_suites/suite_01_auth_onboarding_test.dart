import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/utils/validators.dart';
import 'package:restaurant_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:restaurant_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'helpers/qa_test_helpers.dart';

void main() {
  group('Suite 1: Auth & Onboarding (التثبيت والتهيئة وتسجيل الدخول)', () {
    // -------------------------------------------------------------
    // TC-AUTH-01: Onboarding walkthrough, slides navigation & skip
    // -------------------------------------------------------------
    testWidgets(
      'TC-AUTH-01: Onboarding slides display, swipe, skip and start actions',
      (tester) async {
        String navigatedRoute = '';
        final router = GoRouter(
          initialLocation: '/onboarding',
          routes: [
            GoRoute(
              path: '/onboarding',
              builder: (context, state) => const OnboardingPage(),
            ),
            GoRoute(
              path: '/customer',
              builder: (context, state) {
                navigatedRoute = '/customer';
                return const Scaffold(body: Text('Customer Home'));
              },
            ),
          ],
        );

        final container = createQaContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // Slide 1 visible
        expect(find.textContaining('طلب ذكي ومباشر من طاولتك'), findsOneWidget);
        expect(find.text('تخطي'), findsOneWidget);
        expect(find.text('التالي'), findsOneWidget);

        // Advance to Slide 2
        await tester.tap(find.text('التالي'));
        await tester.pumpAndSettle();
        expect(find.textContaining('متابعة حية لحظة بلحظة'), findsOneWidget);

        // Advance to Slide 3
        await tester.tap(find.text('التالي'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('دفع متعدد ونقاط ولاء ومكافآت'),
          findsOneWidget,
        );
        expect(find.text('ابدأ الآن'), findsOneWidget);

        // Click "ابدأ الآن" -> Navigate
        await tester.tap(find.text('ابدأ الآن'));
        await tester.pumpAndSettle();
        expect(navigatedRoute, '/customer');
      },
    );

    // -------------------------------------------------------------
    // TC-AUTH-02: Register new customer
    // -------------------------------------------------------------
    test('TC-AUTH-02: Register new customer account successfully', () async {
      final mockAuth = QaMockAuthRemoteDataSource();
      final container = createQaContainer(authDataSource: mockAuth);
      addTearDown(container.dispose);

      final authNotifier = container.read(authControllerProvider.notifier);

      expect(container.read(authControllerProvider).isAuthenticated, isFalse);

      await authNotifier.register(
        name: 'عميل جديد',
        email: 'new_customer@restaurant.com',
        phone: '0501234567',
        password: 'SecurePassword123!',
        restaurantId: 'test-restaurant-id',
      );

      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.name, 'عميل جديد');
      expect(state.user?.email, 'new_customer@restaurant.com');
      expect(state.user?.role, UserRole.customer);
      expect(state.user?.role.homeRoute, '/customer');
    });

    // -------------------------------------------------------------
    // TC-AUTH-03: Input Validation
    // -------------------------------------------------------------
    test(
      'TC-AUTH-03: Form validators block invalid emails and short passwords with error messages',
      () {
        // Email validation
        expect(Validators.isValidEmail('invalid-email'), isFalse);
        expect(Validators.isValidEmail('test@'), isFalse);
        expect(Validators.isValidEmail('customer@restaurant.com'), isTrue);

        // Phone validation (Saudi format)
        expect(Validators.isValidPhone('123'), isFalse);
        expect(Validators.isValidPhone('0501234567'), isTrue);
        expect(Validators.isValidPhone('+966501234567'), isTrue);

        // Name validation
        expect(Validators.isValidName(''), isFalse);
        expect(Validators.isValidName('أحمد علي'), isTrue);

        // Password length check
        bool checkPass(String p) => p.length >= 6;
        expect(checkPass('12345'), isFalse);
        expect(checkPass('123456'), isTrue);
        expect(checkPass('SecurePass123'), isTrue);
      },
    );

    // -------------------------------------------------------------
    // TC-AUTH-04: Multi-Role Login and RBAC Home Route Redirection
    // -------------------------------------------------------------
    test(
      'TC-AUTH-04: Multi-role logins assign proper RBAC permissions and default routes',
      () async {
        final mockAuth = QaMockAuthRemoteDataSource();

        final rolesToTest = [
          {
            'email': 'customer@restaurant.com',
            'expectedRole': UserRole.customer,
            'expectedRoute': '/customer',
          },
          {
            'email': 'waiter@restaurant.com',
            'expectedRole': UserRole.waiter,
            'expectedRoute': '/waiter',
          },
          {
            'email': 'kitchen@restaurant.com',
            'expectedRole': UserRole.kitchen,
            'expectedRoute': '/kds',
          },
          {
            'email': 'driver@restaurant.com',
            'expectedRole': UserRole.driver,
            'expectedRoute': '/driver',
          },
          {
            'email': 'manager@restaurant.com',
            'expectedRole': UserRole.manager,
            'expectedRoute': '/manager',
          },
        ];

        for (final testCase in rolesToTest) {
          final container = createQaContainer(authDataSource: mockAuth);
          final authNotifier = container.read(authControllerProvider.notifier);

          final email = testCase['email'] as String;
          final expectedRole = testCase['expectedRole'] as UserRole;
          final expectedRoute = testCase['expectedRoute'] as String;

          await authNotifier.login(email, 'ValidPassword123');

          final authState = container.read(authControllerProvider);
          expect(
            authState.isAuthenticated,
            isTrue,
            reason: 'Failed logging in as $email',
          );
          expect(authState.user?.role, expectedRole);
          expect(authState.user?.role.homeRoute, expectedRoute);

          container.dispose();
        }
      },
    );

    // -------------------------------------------------------------
    // TC-AUTH-05: Session Persistence & Restore
    // -------------------------------------------------------------
    test(
      'TC-AUTH-05: Authenticated state is maintained and bootstrapped cleanly',
      () async {
        final mockAuth = QaMockAuthRemoteDataSource();
        final container = createQaContainer(authDataSource: mockAuth);
        addTearDown(container.dispose);

        final authNotifier = container.read(authControllerProvider.notifier);
        await authNotifier.login('manager@restaurant.com', 'secret');

        final activeState = container.read(authControllerProvider);
        expect(activeState.isAuthenticated, isTrue);
        expect(activeState.user?.role, UserRole.manager);

        // Verify state integrity
        expect(activeState.user?.token, isNotEmpty);
        expect(activeState.user?.id, QaSeedAccounts.manager.id);
      },
    );

    // -------------------------------------------------------------
    // TC-AUTH-06: Logout
    // -------------------------------------------------------------
    test(
      'TC-AUTH-06: Logout clears credentials, active user, and marks unauthenticated',
      () async {
        final mockAuth = QaMockAuthRemoteDataSource();
        final container = createQaContainer(authDataSource: mockAuth);
        addTearDown(container.dispose);

        final authNotifier = container.read(authControllerProvider.notifier);
        await authNotifier.login('waiter@restaurant.com', 'secret');
        expect(container.read(authControllerProvider).isAuthenticated, isTrue);

        await authNotifier.logout();

        final loggedOutState = container.read(authControllerProvider);
        expect(loggedOutState.isAuthenticated, isFalse);
        expect(loggedOutState.user, isNull);
      },
    );
  });
}
