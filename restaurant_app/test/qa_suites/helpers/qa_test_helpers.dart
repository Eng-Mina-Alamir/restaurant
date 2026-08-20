import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import 'package:restaurant_app/core/di/service_locator.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/network/connectivity_service.dart';
import 'package:restaurant_app/core/network/realtime_service.dart';
import 'package:restaurant_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:restaurant_app/features/auth/data/models/user_model.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/coupons/domain/entities/coupon_entity.dart';

import '../../helpers/test_container.dart';

/// Global QA Test initialization for GoogleFonts and Hive
bool _qaEnvInitialized = false;
void initQaTestEnvironment() {
  if (_qaEnvInitialized) return;
  _qaEnvInitialized = true;
  GoogleFonts.config.allowRuntimeFetching = false;
  try {
    final tempDir = Directory.systemTemp.createTempSync('hive_qa_test');
    Hive.init(tempDir.path);
  } catch (_) {}
}

/// Seed Accounts for all roles matching QA Plan
class QaSeedAccounts {
  static final customer = UserModel(
    id: 'usr-cust-1',
    name: 'عميل تجريبي',
    email: 'customer@restaurant.com',
    phone: '0501111222',
    role: UserRole.customer,
    token: 'jwt-token-customer',
    createdAt: DateTime(2025, 1, 1),
  );

  static final waiter = UserModel(
    id: 'usr-waiter-1',
    name: 'نادل تجريبي',
    email: 'waiter@restaurant.com',
    phone: '0503333444',
    role: UserRole.waiter,
    token: 'jwt-token-waiter',
    createdAt: DateTime(2025, 1, 1),
  );

  static final kitchen = UserModel(
    id: 'usr-kitchen-1',
    name: 'شيف المطبخ',
    email: 'kitchen@restaurant.com',
    phone: '0505555666',
    role: UserRole.kitchen,
    token: 'jwt-token-kitchen',
    createdAt: DateTime(2025, 1, 1),
  );

  static final driver = UserModel(
    id: 'usr-driver-1',
    name: 'مندوب التوصيل',
    email: 'driver@restaurant.com',
    phone: '0507777888',
    role: UserRole.driver,
    token: 'jwt-token-driver',
    createdAt: DateTime(2025, 1, 1),
  );

  static final manager = UserModel(
    id: 'usr-manager-1',
    name: 'المدير العام',
    email: 'manager@restaurant.com',
    phone: '0509999000',
    role: UserRole.manager,
    token: 'jwt-token-manager',
    createdAt: DateTime(2025, 1, 1),
  );
}

/// Mock Auth Remote DataSource for QA Suites
class QaMockAuthRemoteDataSource implements AuthRemoteDataSource {
  UserRole roleToReturn = UserRole.customer;
  bool shouldThrowError = false;
  String errorMessage = 'Invalid credentials';

  @override
  Future<UserModel> login(String identifier, String password) async {
    if (shouldThrowError) {
      throw Exception(errorMessage);
    }
    switch (identifier) {
      case 'waiter@restaurant.com':
        return QaSeedAccounts.waiter;
      case 'kitchen@restaurant.com':
        return QaSeedAccounts.kitchen;
      case 'driver@restaurant.com':
        return QaSeedAccounts.driver;
      case 'manager@restaurant.com':
        return QaSeedAccounts.manager;
      default:
        return QaSeedAccounts.customer.copyWith(email: identifier);
    }
  }

  @override
  Future<void> logout(String? token) async {}

  @override
  Future<String> refreshToken(String refreshToken) async => 'jwt-token-refreshed';

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.customer,
  }) async {
    if (shouldThrowError) {
      throw Exception(errorMessage);
    }
    return UserModel(
      id: 'usr-registered-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      role: role,
      token: 'jwt-token-registered',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<UserModel> verifyOtp({required String otp, required String phone}) async {
    return QaSeedAccounts.customer.copyWith(phone: phone);
  }
}

/// QA Seed Items for testing
class QaSeedData {
  static const burgerWithModifiers = MenuItem(
    id: 'qa-burger-1',
    categoryId: 'البرجر',
    name: 'سوبر برجر ديلوكس',
    description: 'برجر لحم فاخر مع صوص خاص',
    price: 60.0,
    isAvailable: true,
    modifierGroups: [
      MenuModifierGroup(
        id: 'mod-grp-cheese',
        title: 'إضافات الجبن',
        isRequired: false,
        maxSelection: 3,
        options: [
          MenuModifierOption(id: 'opt-extra-cheese', name: 'جبن شيدر إضافي', extraPrice: 15.0),
        ],
      ),
      MenuModifierGroup(
        id: 'mod-grp-size',
        title: 'الحجم',
        isRequired: true,
        maxSelection: 1,
        options: [
          MenuModifierOption(id: 'opt-reg', name: 'حجم عادي', extraPrice: 0.0),
          MenuModifierOption(id: 'opt-large', name: 'حجم كبير (دابل)', extraPrice: 25.0),
        ],
      ),
    ],
  );

  static const outOfStockItem = MenuItem(
    id: 'qa-item-oos',
    categoryId: 'المشاوي',
    name: 'ستيك ريب آي معتق',
    description: 'لحم فاخر',
    price: 150.0,
    isAvailable: false,
  );

  static const active20Coupon = CouponEntity(
    id: 'qa-coup-20',
    code: 'SAVE20',
    title: 'خصم 20%',
    discountType: CouponDiscountType.percentage,
    discountValue: 20.0,
    maxDiscountAmount: 50.0,
    minOrderAmount: 50.0,
    isActive: true,
  );

  static final expiredCoupon = CouponEntity(
    id: 'qa-coup-exp',
    code: 'EXPIRED10',
    title: 'خصم 10% منتهي',
    discountType: CouponDiscountType.percentage,
    discountValue: 10.0,
    maxDiscountAmount: 30.0,
    minOrderAmount: 20.0,
    isActive: false,
    validUntil: DateTime.now().subtract(const Duration(days: 10)),
  );
}

/// Test helper to create configured ProviderContainer
ProviderContainer createQaContainer({
  QaMockAuthRemoteDataSource? authDataSource,
  RealtimeService? realtimeService,
  ConnectivityService? connectivityService,
  List<Override> additionalOverrides = const [],
}) {
  final container = createTestContainer(
    additionalOverrides: [
      if (authDataSource != null)
        authRemoteDataSourceProvider.overrideWithValue(authDataSource),
      if (realtimeService != null)
        realtimeServiceProvider.overrideWithValue(realtimeService),
      if (connectivityService != null)
        connectivityServiceProvider.overrideWithValue(connectivityService),
      ...additionalOverrides,
    ],
  );
  return container;
}

/// Helper to pump a test widget with theme, localization, and screen size
Future<void> pumpQaWidget(
  WidgetTester tester, {
  required Widget child,
  ProviderContainer? container,
  Locale locale = const Locale('ar'),
  ThemeMode themeMode = ThemeMode.light,
  Size screenSize = const Size(390, 844), // Phone size by default
}) async {
  tester.view.physicalSize = screenSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());

  final effectiveContainer = container ?? createTestContainer();
  if (container == null) {
    addTearDown(effectiveContainer.dispose);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: effectiveContainer,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
        darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
