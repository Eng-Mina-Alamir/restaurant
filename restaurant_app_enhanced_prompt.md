# 🏪 Master AI Agent Prompt: Restaurant Ordering & Operations Mobile App
## Flutter | Clean Architecture | Production-Ready

---

## 📋 جدول المحتويات
1. [تعريف المشروع والأدوار](#1-تعريف-المشروع-والأدوار)
2. [المتطلبات الفنية والتوسع](#2-المتطلبات-الفنية-والتوسع)
3. [نماذج البيانات والمخطط](#3-نماذج-البيانات-والمخطط)
4. [بنية المشروع](#4-بنية-المشروع)
5. [خريطة الطريق التنفيذية](#5-خريطة-الطريق-التنفيذية)
6. [أفضل الممارسات والقيود](#6-أفضل-الممارسات-والقيود)
7. [الاختبار والجودة](#7-الاختبار-والجودة)
8. [النشر والمراقبة](#8-النشر-والمراقبة)

---

## 1. تعريف المشروع والأدوار

### الرؤية العامة
تطبيق موبايل متكامل متعدد الأدوار يحل التحديات الأساسية في عمليات المطاعم من الطلب إلى الدفع والتسليم.

### الأدوار الرئيسية و الميزات

| الدور | الجهاز | الميزات الأساسية | الأولويات |
|------|-------|-----------------|---------|
| **🧑‍💼 العميل (Dine-In)** | موبايل | QR scan، عرض الوجبات، اختيار الإضافات، الدفع الذاتي | سهولة الاستخدام، سرعة الطلب |
| **👨‍💼 النادل/الكابتن** | تابلت + موبايل | إدارة الطاولات، أخذ الطلبات، تحديث الحالة | الأداء في الوقت الفعلي |
| **👨‍🍳 المطبخ (KDS)** | شاشة كبيرة | عرض الطلبات، مؤقتات التحضير، تحديث الجاهزية | السرعة، الوضوح |
| **📊 المدير/الصاحب** | تابلت + ويب | تحليلات المبيعات، الأصناف الأعلى، مراقبة الخصومات | البيانات الفورية |
| **🚗 السائق** | موبايل | توكيل الطلبات، GPS، تحديث الحالة | الملاحة، التوثيق |

---

## 2. المتطلبات الفنية والتوسع

### تكنولوجيا المشروع

```
📱 Flutter Framework: آخر إصدار مستقر
💾 State Management: flutter_riverpod + freezed
🌐 Networking: dio + JWT interceptors
🔒 Auth: flutter_secure_storage + JWT tokens
💿 Local Storage: hive (offline support)
🧭 Routing: go_router مع role-based guards
🎨 UI: Material 3 + responsive design
📡 Real-time: WebSocket / Firebase Realtime DB
```

### المتطلبات غير الوظيفية

| المتطلب | القيمة المستهدفة |
|-------|-----------------|
| **الأداء** | 60 fps animations، بدء التطبيق < 3 ثوان |
| **التوفر (Uptime)** | 99.5% (4.38 ساعات توقف/شهر) |
| **الموثوقية** | معدل نجاح الطلبات 99.9% |
| **التوسع** | آلاف الطلبات المتزامنة |
| **الأمان** | SSL/TLS، Token Refresh، Role-Based Access |

### الأجهزة المستهدفة

- **موبايل:** iOS 12+، Android 7+
- **تابلت:** 7" فما فوق (iPad, Android Tablet)
- **شاشات المطبخ:** شاشات لمس بحجم 15"

---

## 3. نماذج البيانات والمخطط

### 3.1 Enums & Types

```dart
enum OrderType { 
  dineIn,      // الأكل في المطعم
  takeaway,    // الشراء من البيت
  delivery     // التوصيل
}

enum OrderStatus { 
  pending,     // في الانتظار
  confirmed,   // مؤكد
  preparing,   // قيد الإعداد
  ready,       // جاهز
  served,      // تم التقديم
  completed,   // مكتمل
  cancelled    // ملغى
}

enum TableStatus { 
  available,   // متاح
  occupied,    // مشغول
  reserved,    // محجوز
  needsCleaning // يحتاج تنظيف
}

enum UserRole { 
  customer,    // عميل
  waiter,      // نادل
  kitchen,     // موظف مطبخ
  manager,     // مدير
  admin,       // مسؤول
  driver       // سائق توصيل
}

enum PaymentMethod {
  cash,        // نقداً
  card,        // بطاقة
  wallet,      // محفظة رقمية
  online       // دفع أونلاين
}
```

### 3.2 Entity Models

```dart
class UserEntity {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? restaurantId;
  final String? token;
  final DateTime createdAt;
  final bool isActive;
}

class RestaurantEntity {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final String? logoUrl;
  final BusinessHours hours;
  final int totalTables;
  final List<String> categories;
}

class RestaurantTable {
  final String id;
  final int tableNumber;
  final int capacity;
  final TableStatus status;
  final String? currentOrderId;
  final String? assignedWaiterId;
  final DateTime? lastUpdated;
}

class MenuItem {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final bool isVegetarian;
  final bool isSpicy;
  final double? preparationTime; // بالدقائق
  final List<MenuModifierGroup> modifierGroups;
  final double? rating;
  final int? orderCount;
}

class MenuModifierGroup {
  final String id;
  final String title;
  final String? description;
  final bool isRequired;
  final int maxSelection;
  final List<MenuModifierOption> options;
}

class MenuModifierOption {
  final String id;
  final String name;
  final double extraPrice;
  final bool isAvailable;
}

class CartItem {
  final MenuItem menuItem;
  final int quantity;
  final List<MenuModifierOption> selectedModifiers;
  final String? specialNotes;
  final double itemTotal;
  final DateTime addedAt;
}

class OrderEntity {
  final String id;
  final String restaurantId;
  final String? customerId;
  final String? tableId;
  final String? waiterId;
  final OrderType orderType;
  final List<CartItem> items;
  final OrderStatus status;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final PaymentMethod? paymentMethod;
  final String? deliveryAddress;
  final String? deliveryNotes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? estimatedMinutes;
}

class DeliveryAssignment {
  final String id;
  final String orderId;
  final String driverId;
  final DateTime pickupTime;
  final DateTime? deliveredTime;
  final String deliveryLocation;
  final double latitude;
  final double longitude;
  final String status; // pending, accepted, picked_up, in_transit, delivered
  final double? deliveryFee;
  final String? routeOptimized;
}

class SalesMetrics {
  final double totalSales;
  final int totalOrders;
  final double averageOrderValue;
  final Map<String, int> itemsSold;
  final double peakHour;
  final double prepTimeAverage;
}
```

### 3.2 Database Schema (Firebase/REST API)

```
/restaurants/{restaurantId}
  ├── info (name, address, hours, etc)
  ├── tables/{tableId} (number, capacity, status)
  ├── menu
  │   ├── categories/{categoryId}
  │   └── items/{itemId}
  ├── orders/{orderId}
  ├── users/{userId}
  └── analytics/sales

/drivers/{driverId}
  ├── profile
  ├── active_deliveries
  └── location_history
```

---

## 4. بنية المشروع

### 4.1 Folder Structure

```
lib/
├── main.dart                          # نقطة الدخول
├── config/
│   ├── app_config.dart               # الإعدادات العامة
│   ├── environment.dart              # البيئات (dev, staging, prod)
│   └── constants.dart                # ثوابت التطبيق
├── core/
│   ├── di/                           # Dependency Injection
│   │   └── service_locator.dart
│   ├── network/
│   │   ├── dio_client.dart
│   │   ├── api_interceptors.dart
│   │   ├── api_endpoints.dart
│   │   └── http_error_handler.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── color_schemes.dart
│   │   ├── text_styles.dart
│   │   └── spacing.dart
│   ├── storage/
│   │   ├── secure_storage_service.dart
│   │   └── local_cache_service.dart
│   ├── utils/
│   │   ├── logger.dart
│   │   ├── validators.dart
│   │   ├── extensions.dart
│   │   └── formatters.dart
│   └── errors/
│       ├── failures.dart
│       └── exceptions.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── controllers/
│   │       └── pages/
│   ├── menu/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── cart/
│   ├── orders/
│   ├── table_management/
│   ├── kds/               # Kitchen Display System
│   ├── delivery/
│   └── manager_dashboard/
└── shared/
    ├── widgets/
    │   ├── app_bar.dart
    │   ├── bottom_nav.dart
    │   ├── loading_widget.dart
    │   └── error_widget.dart
    ├── animations/
    └── extensions/
```

### 4.2 Layered Architecture Pattern

```
┌─────────────────────────────────────────┐
│     🎨 PRESENTATION LAYER              │
│  (Pages, Widgets, Controllers)         │
└────────────────┬────────────────────────┘
                 │
         ┌───────▼────────┐
         │ State Manager  │
         │   Riverpod     │
         └───────┬────────┘
                 │
┌────────────────▼────────────────────────┐
│   📦 DOMAIN LAYER                      │
│ (Entities, Use Cases, Repositories)    │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│   💾 DATA LAYER                        │
│ (Data Sources, Models, Repositories)   │
└────────────────┬────────────────────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
  Remote      Local         Cache
  (API)      (Hive)       (Memory)
```

---

## 5. خريطة الطريق التنفيذية

### المرحلة 1️⃣ : إعداد المشروع و البنية الأساسية (الأسبوع 1-2)

#### 1.1 إعداد Flutter و Pubspec
```yaml
dependencies:
  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # Networking
  dio: ^5.3.0
  
  # Local Storage
  hive: ^2.2.0
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.0.0
  
  # UI & Navigation
  go_router: ^12.0.0
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.0
  
  # QR & Scanning
  mobile_scanner: ^3.5.0
  qr_flutter: ^4.0.0
  
  # Real-time
  socket_io_client: ^2.0.0
  
  # Utilities
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0
  intl: ^0.19.0
  
dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
```

#### 1.2 إعداد المشروع
```bash
flutter create --template app restaurant_app
cd restaurant_app
flutter pub get
flutter pub run build_runner build
```

#### 1.3 إنشاء بنية المجلدات الأساسية
- [ ] إنشاء مجلدات المشروع حسب البنية المقترحة
- [ ] تكوين .env و environment files
- [ ] إعداد git workflow (main, develop, feature branches)

**المخرجات:** 
✅ مشروع نظيف و معد للعمل
✅ بنية المشروع مطبقة
✅ Pubspec محدث مع جميع المكتبات

---

### المرحلة 2️⃣ : البنية الأساسية والمصادقة (الأسبوع 3-4)

#### 2.1 إعداد Dio Client
```dart
// core/network/dio_client.dart
class DioClient {
  late final Dio _dio;
  final String baseUrl;
  final SecureStorageService storage;
  
  DioClient({
    required this.baseUrl,
    required this.storage,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
    ));
    
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }
  
  // Token injection logic
  // Error mapping logic
  // Token refresh logic
}
```

#### 2.2 مصادقة المستخدم
- [ ] تسجيل دخول (Login with phone/email)
- [ ] التحقق من OTP
- [ ] تخزين آمن للـ Token (JWT)
- [ ] تحديث تلقائي للـ Token
- [ ] تسجيل خروج آمن

#### 2.3 Role-Based Routing
```dart
// config/router.dart
final goRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final authState = ref.read(authNotifierProvider);
    
    return authState.when(
      authenticated: (user) {
        // Redirect بناءً على الدور
        return _getHomeRoute(user.role);
      },
      unauthenticated: () => '/login',
    );
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => LoginPage()),
    GoRoute(path: '/customer', builder: (_, __) => CustomerHomePage()),
    GoRoute(path: '/waiter', builder: (_, __) => WaiterDashboard()),
    // ...
  ],
);
```

**المخرجات:**
✅ نظام مصادقة آمن
✅ Dio Client جاهز
✅ Role-based routing مطبق

---

### المرحلة 3️⃣ : واجهة العميل - الطلب والعربة (الأسبوع 5-7)

#### 3.1 عرض القائمة
- [ ] CategoryTab Bar مع الفئات
- [ ] MenuItem Cards مع الصور والأسعار
- [ ] شارات التوفر والحالة الخاصة
- [ ] Search & Filter functionality

#### 3.2 نظام الإضافات (Modifiers)
```dart
// عرض Modifier Bottom Sheet
class ModifierSelectionBottomSheet extends ConsumerWidget {
  final MenuItem menuItem;
  
  @override
  Widget build(context, ref) {
    return Column(
      children: [
        // Modifier groups
        // Required indicators
        // Selection counters
      ],
    );
  }
}
```

#### 3.3 عربة التسوق
- [ ] إضافة/حذف العناصر
- [ ] تحديث الكميات
- [ ] حساب تلقائي للإجمالي
- [ ] حفظ الملاحظات الخاصة
- [ ] حساب الفاتورة المقسمة (Split Bill)

**المخرجات:**
✅ واجهة عميل كاملة
✅ نظام عربة التسوق
✅ قوائم ديناميكية

---

### المرحلة 4️⃣ : عمليات النادل و إدارة الطاولات (الأسبوع 8-9)

#### 4.1 إدارة الطاولات
```dart
// TableGrid Widget
class TableGridWidget extends ConsumerWidget {
  @override
  Widget build(context, ref) {
    // عرض شبكة الطاولات
    // عرض الحالة بألوان مختلفة
    // Tap للطاولة = اختيار للطلب
  }
}
```

#### 4.2 أخذ الطلبات
- [ ] ربط الطاولة بالعربة
- [ ] تأكيد الطلب وإرساله
- [ ] تحديث حالة الطاولة تلقائياً
- [ ] معالجة الطلبات المعلقة

**المخرجات:**
✅ واجهة النادل كاملة
✅ إدارة الطاولات في الوقت الفعلي

---

### المرحلة 5️⃣ : نظام عرض المطبخ KDS (الأسبوع 10-11)

#### 5.1 واجهة Kanban
```dart
class KdsScreen extends ConsumerWidget {
  @override
  Widget build(context, ref) {
    return Row(
      children: [
        KdsColumn(status: OrderStatus.pending),
        KdsColumn(status: OrderStatus.preparing),
        KdsColumn(status: OrderStatus.ready),
      ],
    );
  }
}
```

#### 5.2 مؤقتات و تنبيهات
- [ ] مؤقتات لكل طلب
- [ ] تحذيرات لونية (أخضر/أصفر/أحمر)
- [ ] صوت للطلبات الجديدة
- [ ] اهتزاز الجهاز (Haptic Feedback)
- [ ] عرض التفاصيل والملاحظات

**المخرجات:**
✅ KDS نظام عرض المطبخ
✅ تنبيهات وتحذيرات

---

### المرحلة 6️⃣ : تطبيق السائق والتوصيل (الأسبوع 12-14)

#### 6.1 تخصيص الطلبات
- [ ] قائمة الطلبات المتاحة للتوصيل
- [ ] قبول/رفض الطلب
- [ ] حساب المسافة والرسوم تلقائياً
- [ ] تحسين المسار (Route Optimization)

#### 6.2 التتبع الحي
```dart
class LiveTrackingMap extends ConsumerWidget {
  // عرض موقع السائق
  // خط المسار
  // المحطات (البيك اب والتوصيل)
  // عرض المسافة المتبقية
}
```

#### 6.3 تحديثات الحالة
- [ ] "تم الاستلام"
- [ ] "قيد الطريق"
- [ ] "تم التسليم"
- [ ] صور توثيق التسليم

**المخرجات:**
✅ تطبيق السائق كامل
✅ نظام التتبع الحي

---

### المرحلة 7️⃣ : لوحة تحكم المدير والتحسين (الأسبوع 15-17)

#### 7.1 التحليلات والمقاييس
```dart
class ManagerDashboard extends ConsumerWidget {
  @override
  Widget build(context, ref) {
    final metrics = ref.watch(salesMetricsProvider);
    
    return ListView(
      children: [
        MetricCard(title: 'إجمالي المبيعات', value: metrics.totalSales),
        MetricCard(title: 'عدد الطلبات', value: metrics.totalOrders),
        TopSellingItemsChart(items: metrics.topItems),
        AverageOrderValueTrend(),
        PeakHourAnalysis(),
      ],
    );
  }
}
```

#### 7.2 الميزات المتقدمة
- [ ] إدارة الخصومات والعروض
- [ ] تقارير التنبيهات
- [ ] مراقبة أداء الموظفين
- [ ] إدارة المخزون
- [ ] الفواتير والدفع

#### 7.3 Optimizations & Polish
- [ ] Caching strategies
- [ ] Image optimization
- [ ] Animation polish
- [ ] Error handling improvements
- [ ] Offline support

**المخرجات:**
✅ لوحة تحكم المدير كاملة
✅ تطبيق متكامل وجاهز للإنتاج

---

## 6. أفضل الممارسات والقيود

### 6.1 القيود الإجبارية

#### ✋ قيود الكود

```dart
// ❌ لا تفعل
class OrderPage extends StatefulWidget {
  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List<CartItem> cartItems = []; // ❌ state خارج Riverpod
  
  void addToCart(MenuItem item) {
    cartItems.add(item); // ❌ logic في widget
  }
}

// ✅ افعل هذا
final cartProvider = StateNotifierProvider((ref) {
  return CartNotifier(ref);
});

class OrderPage extends ConsumerWidget {
  @override
  Widget build(context, ref) {
    final cart = ref.watch(cartProvider);
    return CartView(cart: cart);
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier(this.ref) : super([]);
  final Ref ref;
  
  void addToCart(MenuItem item) {
    // ✅ كل logic هنا
    state = [...state, CartItem(item)];
  }
}
```

#### 🔒 معايير الأمان

```dart
// ✅ JWT Token Management
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token expired - refresh
      final newToken = await refreshToken();
      if (newToken != null) {
        // Retry request with new token
      }
    }
    handler.next(err);
  }
}

// ✅ Secure Storage
await secureStorage.write(
  key: 'jwt_token',
  value: token,
  // في iOS: استخدم Keychain
  // في Android: استخدم EncryptedSharedPreferences
);
```

#### 🎯 معايير الأداء

```dart
// ✅ استخدم const constructors
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    Key? key,
    required this.item,
  }) : super(key: key);
  
  final MenuItem item;
  
  @override
  Widget build(BuildContext context) {
    return const Text('Item'); // ✅ const
  }
}

// ✅ Image caching
import 'package:cached_network_image/cached_network_image.dart';

CachedNetworkImage(
  imageUrl: menuItem.imageUrl,
  placeholder: (context, url) => Skeleton(),
  cacheManager: customCacheManager,
);

// ✅ List performance
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => MenuItemCard(
    item: items[index],
    key: ValueKey(items[index].id), // ✅ keys
  ),
)
```

### 6.2 SOLID Principles

```dart
// 🎯 S - Single Responsibility
class MenuRepository {
  // مسؤول عن بيانات القائمة فقط
  Future<List<MenuItem>> getMenuItems();
}

class OrderRepository {
  // مسؤول عن بيانات الطلبات فقط
  Future<OrderEntity> createOrder(List<CartItem> items);
}

// 🎯 O - Open/Closed
abstract class DataSource {
  Future<T> get<T>(String endpoint);
}

class RemoteDataSource implements DataSource { }
class LocalDataSource implements DataSource { }

// 🎯 L - Liskov Substitution
// استخدم RemoteDataSource أو LocalDataSource بنفس الطريقة

// 🎯 I - Interface Segregation
abstract class OrderCreator {
  Future<OrderEntity> createOrder(List<CartItem> items);
}

abstract class OrderTracker {
  Stream<OrderStatus> trackOrder(String orderId);
}

// 🎯 D - Dependency Inversion
class OrderUseCase {
  final OrderRepository repository; // تعتمد على abstraction
  OrderUseCase(this.repository);
}
```

### 6.3 Immutability & Freezed

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_state.freezed.dart';

@freezed
class OrderState with _$OrderState {
  const factory OrderState({
    required List<CartItem> items,
    required double total,
    @Default(false) bool isSubmitting,
    String? error,
  }) = _OrderState;
  
  // مثال: لا يمكن تعديل مباشر
  // ❌ orderState.items.add(newItem); // خطأ
  
  // ✅ استخدم copyWith
  final updatedState = orderState.copyWith(
    items: [...orderState.items, newItem],
  );
}
```

### 6.4 Error Handling

```dart
// نموذج الأخطاء
abstract class Failure {
  final String message;
  Failure(this.message);
}

class NetworkFailure extends Failure {
  NetworkFailure() : super('خطأ في الاتصال');
}

class ServerFailure extends Failure {
  ServerFailure(String message) : super(message);
}

class ValidationFailure extends Failure {
  ValidationFailure(String message) : super(message);
}

// معالجة الأخطاء في Use Cases
class CreateOrderUseCase {
  Future<Either<Failure, OrderEntity>> call(List<CartItem> items) async {
    try {
      if (items.isEmpty) {
        return Left(ValidationFailure('العربة فارغة'));
      }
      
      final order = await repository.createOrder(items);
      return Right(order);
    } on DioException catch (e) {
      return Left(NetworkFailure());
    } catch (e) {
      return Left(Failure('خطأ غير متوقع'));
    }
  }
}

// عرض الأخطاء في UI
ref.listen(createOrderProvider, (previous, next) {
  next.when(
    loading: () => showLoadingDialog(),
    error: (error, stack) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    },
    data: (order) => navigateToOrderSuccess(order),
  );
});
```

---

## 7. الاختبار والجودة

### 7.1 Unit Tests

```dart
// test/features/order/domain/usecases/create_order_usecase_test.dart

void main() {
  group('CreateOrderUseCase', () {
    late MockOrderRepository mockRepository;
    late CreateOrderUseCase useCase;
    
    setUp(() {
      mockRepository = MockOrderRepository();
      useCase = CreateOrderUseCase(mockRepository);
    });
    
    test('should return OrderEntity when repository call is successful', () async {
      // Arrange
      final cartItems = [
        CartItem(menuItem: mockMenuItem, quantity: 1),
      ];
      final expectedOrder = OrderEntity(
        id: '1',
        items: cartItems,
        totalAmount: 50.0,
      );
      
      when(mockRepository.createOrder(cartItems))
          .thenAnswer((_) async => expectedOrder);
      
      // Act
      final result = await useCase(cartItems);
      
      // Assert
      expect(result, Right(expectedOrder));
      verify(mockRepository.createOrder(cartItems));
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
```

### 7.2 Widget Tests

```dart
void main() {
  group('MenuItemCard Widget Tests', () {
    testWidgets('should display menu item correctly', (WidgetTester tester) async {
      final menuItem = MenuItem(
        id: '1',
        name: 'برجر',
        price: 50.0,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: MenuItemCard(item: menuItem),
        ),
      );
      
      expect(find.text('برجر'), findsOneWidget);
      expect(find.text('50.0 ر.س'), findsOneWidget);
    });
  });
}
```

### 7.3 Integration Tests

```dart
void main() {
  group('Order Flow Integration Test', () {
    testWidgets('Complete order flow', (WidgetTester tester) async {
      // 1. تحميل التطبيق
      await tester.pumpWidget(const MyApp());
      
      // 2. تسجيل الدخول
      await tester.enterText(find.byType(TextField).first, 'customer@test.com');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      
      // 3. اختيار عنصر
      await tester.tap(find.byType(MenuItemCard).first);
      await tester.pumpAndSettle();
      
      // 4. الطلب
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pumpAndSettle();
      
      expect(find.text('تم تأكيد الطلب'), findsOneWidget);
    });
  });
}
```

### 7.4 Test Coverage

```bash
# تشغيل الاختبارات مع coverage
flutter test --coverage

# عرض التقرير
lcov --list coverage/lcov.info

# هدف: >= 80% code coverage
```

---

## 8. النشر والمراقبة

### 8.1 بيئات التطوير

```dart
// lib/config/environment.dart
enum Environment { dev, staging, production }

class EnvironmentConfig {
  static const Environment _current = Environment.production;
  
  static const String devBaseUrl = 'https://dev-api.restaurant.com';
  static const String stagingBaseUrl = 'https://staging-api.restaurant.com';
  static const String prodBaseUrl = 'https://api.restaurant.com';
  
  static String get baseUrl {
    switch (_current) {
      case Environment.dev:
        return devBaseUrl;
      case Environment.staging:
        return stagingBaseUrl;
      case Environment.production:
        return prodBaseUrl;
    }
  }
}
```

### 8.2 إجراءات النشر

#### iOS
```bash
# الإعداد
flutter build ios --release

# الرفع إلى App Store
cd ios
fastlane ios beta
```

#### Android
```bash
# الإعداد
flutter build appbundle --release

# الرفع إلى Google Play
cd android
fastlane android beta
```

### 8.3 المراقبة والتحليلات

```dart
// Firebase Analytics Setup
import 'package:firebase_analytics/firebase_analytics.dart';

final analytics = FirebaseAnalytics.instance;

// Track Events
analytics.logEvent(
  name: 'order_created',
  parameters: {
    'order_value': order.totalAmount,
    'item_count': order.items.length,
    'user_role': user.role.name,
  },
);

// Performance Monitoring
analytics.logTiming(
  name: 'api_response_time',
  duration: responseTime,
);

// Crash Reporting
try {
  // كود
} catch (e, stack) {
  FirebaseCrashlytics.instance.recordError(e, stack);
}
```

### 8.4 Version Management

```yaml
# pubspec.yaml
version: 1.0.0+1

# Version Format: MAJOR.MINOR.PATCH+BUILD_NUMBER
# Example: 1.2.3+42
# 1 = major version (breaking changes)
# 2 = minor version (new features)
# 3 = patch (bug fixes)
# 42 = build number
```

---

## 📊 Checklist المشروع

### قبل الإطلاق النهائي

- [ ] جميع الاختبارات تمر (test coverage >= 80%)
- [ ] لا توجد تحذيرات في `flutter analyze`
- [ ] عملية المصادقة آمنة (JWT + refresh token)
- [ ] معالجة الأخطاء تغطي جميع الحالات
- [ ] الصور محسّنة (WebP, caching)
- [ ] الأداء: 60 fps في جميع الشاشات
- [ ] RTL support كامل (العربية)
- [ ] Offline mode يعمل للقوائم والطلبات
- [ ] جميع الأدوار مختبرة
- [ ] توثيق API كامل
- [ ] Privacy policy و terms of service

---

## 🚀 نصائح للنجاح

1. **ابدأ بـ MVP:** ركز على الميزات الأساسية أولاً
2. **اختبر بناءً على الأدوار:** كل دور قد يعمل بشكل مختلف
3. **راقب الأداء:** استخدم DevTools و Profiler
4. **حافظ على التنظيم:** اتبع البنية الموضحة
5. **وثّق باستمرار:** اكتب تعليقات واضحة
6. **اطلب التغذية الراجعة:** من المستخدمين الفعليين
7. **كن مرناً:** التعديلات ستأتي مع الاستخدام

---

**آخر تحديث:** 2025
**الإصدار:** 2.0
**الحالة:** 🟢 جاهز للاستخدام في الإنتاج
