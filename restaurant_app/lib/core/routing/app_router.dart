import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/customer/presentation/pages/customer_home_page.dart';
import '../../features/customer/presentation/pages/order_history_page.dart';
import '../../features/customer/presentation/pages/order_tracking_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/loyalty/presentation/pages/loyalty_page.dart';
import '../../features/orders/presentation/pages/order_confirmation_page.dart';
import '../../features/orders/domain/entities/order_entity.dart';
import '../../features/delivery/presentation/pages/driver_home_page.dart';
import '../../features/delivery/presentation/pages/driver_earnings_page.dart';
import '../../features/kds/presentation/pages/kds_page.dart';
import '../../features/manager_dashboard/presentation/pages/alerts_page.dart';
import '../../features/manager_dashboard/presentation/pages/discounts_page.dart';
import '../../features/manager_dashboard/presentation/pages/dispatch_board_page.dart';
import '../../features/manager_dashboard/presentation/pages/inventory_page.dart';
import '../../features/manager_dashboard/presentation/pages/invoices_page.dart';
import '../../features/coupons/presentation/pages/coupon_management_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/manager_dashboard/presentation/pages/financial_reports_page.dart';
import '../../features/manager_dashboard/presentation/pages/manager_dashboard_page.dart';
import '../../features/manager_dashboard/presentation/pages/qr_generator_page.dart';
import '../../features/manager_dashboard/presentation/pages/shift_management_page.dart';
import '../../features/manager_dashboard/presentation/pages/staff_performance_page.dart';
import '../../features/manager_dashboard/presentation/pages/user_management_page.dart';
import '../../features/menu/presentation/pages/menu_management_page.dart';
import '../../features/reservations/presentation/pages/reservations_page.dart';
import '../../features/cashier/presentation/pages/cashier_dashboard_page.dart';
import '../../features/cashier/presentation/pages/fast_pos_checkout_page.dart';
import '../../features/settings/presentation/pages/privacy_policy_page.dart';
import '../../features/settings/presentation/pages/terms_page.dart';
import '../../features/table_management/presentation/pages/all_orders_page.dart';
import '../../features/table_management/presentation/pages/table_detail_page.dart';
import '../../features/table_management/presentation/pages/table_management_crud_page.dart';
import '../../features/table_management/presentation/pages/waiter_dashboard_page.dart';
import '../../features/table_management/presentation/pages/waiter_order_page.dart';
import '../../features/table_management/presentation/pages/waiter_tips_page.dart';
import '../../features/inventory/presentation/pages/recipe_management_page.dart';
import '../../features/inventory/presentation/pages/waste_logs_page.dart';
import '../../features/manager_dashboard/presentation/pages/menu_engineering_page.dart';
import '../../features/manager_dashboard/presentation/pages/owner_daily_digest_page.dart';
import '../../features/manager_dashboard/presentation/pages/staff_timesheet_page.dart';
import '../../features/manager_dashboard/presentation/pages/purchase_orders_page.dart';
import '../../features/manager_dashboard/presentation/pages/security_audit_logs_page.dart';
import '../../features/manager_dashboard/presentation/pages/guest_feedback_hub_page.dart';
import '../../features/manager_dashboard/presentation/pages/sales_velocity_target_page.dart';
import '../../features/customer/presentation/pages/group_order_room_page.dart';
import '../../features/customer/presentation/pages/gift_cards_hub_page.dart';
import '../../features/customer/presentation/pages/customer_dietary_profile_page.dart';
import '../../shared/animations/page_transitions.dart';
import '../../shared/widgets/not_found_page.dart';

/// Builds the root [GoRouter] with role-based redirects and smooth page transitions.
///
/// Route map:
///   /login           – authentication
///   /customer        – Dine-in customer flow
///   /cashier         – Cashier POS & cash drawer hub
///   /waiter          – Waiter / captain
///   /kds             – Kitchen Display System
///   /manager         – Manager / admin dashboard
///   /driver          – Delivery driver
/// Route prefixes restricted to staff roles. An authenticated user whose role
/// is not listed for a matched prefix is redirected to their [UserRole.homeRoute].
///
/// The customer area (`/customer/**`) stays open to every authenticated role:
/// it grants no privileges, and managers/waiters legitimately preview it.
const Map<String, Set<UserRole>> _roleProtectedPrefixes = {
  '/cashier': {UserRole.cashier, UserRole.manager, UserRole.admin},
  '/manager/shifts': {UserRole.cashier, UserRole.waiter, UserRole.manager, UserRole.admin},
  '/manager/invoices': {UserRole.cashier, UserRole.manager, UserRole.admin},
  '/manager/orders': {UserRole.cashier, UserRole.waiter, UserRole.manager, UserRole.admin},
  '/manager': {UserRole.manager, UserRole.admin},
  '/waiter': {UserRole.waiter, UserRole.cashier, UserRole.manager, UserRole.admin},
  '/kds': {UserRole.kitchen, UserRole.manager, UserRole.admin},
  '/driver': {UserRole.driver, UserRole.manager, UserRole.admin},
};

/// Returns `true` when [role] may open the route at [location].
///
/// Pure and exhaustive so the RBAC boundary can be unit-tested without a
/// widget tree (see `test/integration/rbac_security_flow_test.dart`).
bool canRoleAccess(UserRole role, String location) {
  for (final entry in _roleProtectedPrefixes.entries) {
    final prefix = entry.key;
    final matches = location == prefix || location.startsWith('$prefix/');
    if (!matches) continue;
    return entry.value.contains(role);
  }
  return true;
}

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
      final registering = state.matchedLocation == '/register';

      if (auth.status == AuthStatus.unauthenticated) {
        return (loggingIn || registering) ? null : '/login';
      }

      final user = auth.user;
      if (user == null) {
        return (loggingIn || registering) ? null : '/login';
      }

      // Authenticated users landing on /login (or / or /register) go to their role home.
      if (loggingIn || registering || state.matchedLocation == '/') {
        return user.role.homeRoute;
      }

      // Role-based area guard: deep links cannot cross privilege boundaries.
      if (!canRoleAccess(user.role, state.matchedLocation)) {
        return user.role.homeRoute;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/login'),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const NotificationsPage(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => AppPageTransitions.scaleFade(
          key: state.pageKey,
          child: const OnboardingPage(),
        ),
      ),
      GoRoute(
        path: '/customer',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const CustomerHomePage(),
        ),
        routes: [
          GoRoute(
            path: 'orders',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const OrderHistoryPage(),
            ),
          ),
          GoRoute(
            path: 'cart',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const CartPage(),
            ),
          ),
          GoRoute(
            path: 'order-confirmation',
            pageBuilder: (context, state) {
              final order = state.extra as OrderEntity?;
              if (order == null) {
                return AppPageTransitions.fadeSlide(
                  key: state.pageKey,
                  child: const CustomerHomePage(),
                );
              }
              return AppPageTransitions.scaleFade(
                key: state.pageKey,
                child: OrderConfirmationPage(order: order),
              );
            },
          ),
          GoRoute(
            path: 'track/:orderId',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: OrderTrackingPage(
                orderId: state.pathParameters['orderId'] ?? 'ORD-0001',
              ),
            ),
          ),
          GoRoute(
            path: 'loyalty',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const LoyaltyPage(),
            ),
          ),
          GoRoute(
            path: 'group-order',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const GroupOrderRoomPage(),
            ),
          ),
          GoRoute(
            path: 'gift-cards',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const GiftCardsHubPage(),
            ),
          ),
          GoRoute(
            path: 'dietary-profile',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const CustomerDietaryProfilePage(),
            ),
          ),
        ],
      ),

      GoRoute(
        path: '/cashier',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const CashierDashboardPage(),
        ),
        routes: [
          GoRoute(
            path: 'pos',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const FastPOSCheckoutPage(),
            ),
          ),
        ],
      ),

      GoRoute(
        path: '/waiter',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const WaiterDashboardPage(),
        ),
        routes: [
          GoRoute(
            path: 'table/:tableId',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: TableDetailPage(tableId: state.pathParameters['tableId']!),
            ),
          ),
          GoRoute(
            path: 'order/:tableId',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: WaiterOrderPage(tableId: state.pathParameters['tableId']!),
            ),
          ),
          GoRoute(
            path: 'tips',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const WaiterTipsPage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/kds',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const KdsPage(),
        ),
      ),
      GoRoute(
        path: '/chat/:orderId',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child:
              ChatPage(orderId: state.pathParameters['orderId'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/manager',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const ManagerDashboardPage(),
        ),
        routes: [
          GoRoute(
            path: 'orders',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const AllOrdersPage(),
            ),
          ),
          GoRoute(
            path: 'discounts',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const DiscountsPage(),
            ),
          ),
          GoRoute(
            path: 'inventory',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const InventoryPage(),
            ),
          ),
          GoRoute(
            path: 'staff',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const StaffPerformancePage(),
            ),
          ),
          GoRoute(
            path: 'invoices',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const InvoicesPage(),
            ),
          ),
          GoRoute(
            path: 'qr-codes',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const QrGeneratorPage(),
            ),
          ),
          GoRoute(
            path: 'alerts',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const AlertsPage(),
            ),
          ),
          GoRoute(
            path: 'menu',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const MenuManagementPage(),
            ),
          ),
          GoRoute(
            path: 'tables',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const TableManagementCrudPage(),
            ),
          ),
          GoRoute(
            path: 'reservations',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const ReservationsPage(),
            ),
          ),
          GoRoute(
            path: 'users',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const UserManagementPage(),
            ),
          ),
          GoRoute(
            path: 'coupons',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const CouponManagementPage(),
            ),
          ),
          GoRoute(
            path: 'dispatch',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const DispatchBoardPage(),
            ),
          ),
          GoRoute(
            path: 'financial-reports',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const FinancialReportsPage(),
            ),
          ),
          GoRoute(
            path: 'shifts',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const ShiftManagementPage(),
            ),
          ),
          GoRoute(
            path: 'recipes',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const RecipeManagementPage(),
            ),
          ),
          GoRoute(
            path: 'waste-logs',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const WasteLogsPage(),
            ),
          ),
          GoRoute(
            path: 'menu-engineering',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const MenuEngineeringPage(),
            ),
          ),
          GoRoute(
            path: 'owner-digest',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const OwnerDailyDigestPage(),
            ),
          ),
          GoRoute(
            path: 'timesheet',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const StaffTimesheetPage(),
            ),
          ),
          GoRoute(
            path: 'purchase-orders',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const PurchaseOrdersPage(),
            ),
          ),
          GoRoute(
            path: 'security-audit',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const SecurityAuditLogsPage(),
            ),
          ),
          GoRoute(
            path: 'guest-feedback',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const GuestFeedbackHubPage(),
            ),
          ),
          GoRoute(
            path: 'sales-target',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const SalesVelocityTargetPage(),
            ),
          ),
        ],
      ),

      GoRoute(
        path: '/driver',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const DriverHomePage(),
        ),
      ),
      GoRoute(
        path: '/driver/earnings',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const DriverEarningsPage(),
        ),
      ),
      GoRoute(
        path: '/privacy-policy',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const PrivacyPolicyPage(),
        ),
      ),
      GoRoute(
        path: '/terms',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const TermsPage(),
        ),
      ),
      GoRoute(
        path: '/:page',
        builder: (context, state) => const NotFoundPage(),
      ),
    ],
  );
}
