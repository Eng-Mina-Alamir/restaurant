import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/customer/presentation/pages/customer_home_page.dart';
import '../../features/orders/presentation/pages/order_confirmation_page.dart';
import '../../features/orders/domain/entities/order_entity.dart';
import '../../features/delivery/presentation/pages/driver_home_page.dart';
import '../../features/kds/presentation/pages/kds_page.dart';
import '../../features/manager_dashboard/presentation/pages/manager_dashboard_page.dart';
import '../../features/table_management/presentation/pages/waiter_dashboard_page.dart';
import '../../features/table_management/presentation/pages/waiter_order_page.dart';
import '../../shared/widgets/not_found_page.dart';

/// Builds the root [GoRouter] with role-based redirects.
///
/// Route map:
///   /login           – authentication
///   /customer        – Dine-in customer flow
///   /waiter          – Waiter / captain
///   /kds             – Kitchen Display System
///   /manager         – Manager / admin dashboard
///   /driver          – Delivery driver
GoRouter createAppRouter({required WidgetRef ref}) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);

      // While the session is still being resolved (app bootstrap), stay put.
      if (auth.status == AuthStatus.unknown) {
        return null;
      }

      final loggingIn = state.matchedLocation == '/login';

      if (auth.status == AuthStatus.unauthenticated) {
        return loggingIn ? null : '/login';
      }

      final user = auth.user;
      if (user == null) {
        return loggingIn ? null : '/login';
      }

      // Authenticated users landing on /login (or /) go to their role home.
      if (loggingIn || state.matchedLocation == '/') {
        return user.role.homeRoute;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/login'),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/customer',
        builder: (context, state) => const CustomerHomePage(),
        routes: [
          GoRoute(path: 'cart', builder: (context, state) => const CartPage()),
          GoRoute(
            path: 'order-confirmation',
            builder: (context, state) {
              final order = state.extra as OrderEntity?;
              if (order == null) {
                return const CustomerHomePage();
              }
              return OrderConfirmationPage(order: order);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/waiter',
        builder: (context, state) => const WaiterDashboardPage(),
        routes: [
          GoRoute(
            path: 'order/:tableId',
            builder: (context, state) =>
                WaiterOrderPage(tableId: state.pathParameters['tableId']!),
          ),
        ],
      ),
      GoRoute(path: '/kds', builder: (context, state) => const KdsPage()),
      GoRoute(
        path: '/manager',
        builder: (context, state) => const ManagerDashboardPage(),
      ),
      GoRoute(
        path: '/driver',
        builder: (context, state) => const DriverHomePage(),
      ),
      GoRoute(
        path: '/:page',
        builder: (context, state) => const NotFoundPage(),
      ),
    ],
  );
}
