/// Centralized Arabic string constants for the app.
///
/// Kept as pure Dart (no Flutter imports) so the strings can be consumed from
/// any layer, including the domain layer and unit tests.
abstract final class AppConstants {
  AppConstants._();

  // ── App ────────────────────────────────────────────────────────────────────
  static const String appName = 'مطعمي';
  static const String appTagline = 'طبخك المفضل في مكان واحد';
  static const String currency = 'ر.س';

  // ── Auth / Login ───────────────────────────────────────────────────────────
  static const String loginTitle = 'تسجيل الدخول';
  static const String loginSubtitle = 'مرحباً بعودتك! سجّل للوصول إلى طلباتك';
  static const String phoneTab = 'جوال';
  static const String emailTab = 'بريد إلكتروني';
  static const String phoneLabel = 'رقم الجوال';
  static const String emailLabel = 'البريد الإلكتروني';
  static const String passwordLabel = 'كلمة المرور';
  static const String otpLabel = 'رمز التحقق';
  static const String loginButton = 'دخول';
  static const String loginWithOtpButton = 'تسجيل الدخول بالرمز';
  static const String sendOtpButton = 'إرسال الرمز';
  static const String resendOtpButton = 'إعادة إرسال الرمز';
  static const String forgotPassword = 'نسيت كلمة المرور؟';
  static const String noAccount = 'ليس لديك حساب؟';
  static const String createAccount = 'إنشاء حساب جديد';
  static const String welcome = 'أهلاً بك';

  // ── Orders ─────────────────────────────────────────────────────────────────
  static const String ordersTitle = 'الطلبات';
  static const String orderDetailsTitle = 'تفاصيل الطلب';
  static const String orderNumberLabel = 'رقم الطلب';
  static const String orderTotalLabel = 'الإجمالي';
  static const String orderStatusLabel = 'الحالة';
  static const String emptyOrders = 'لا توجد طلبات حالياً';
  static const String cancelOrder = 'إلغاء الطلب';
  static const String reorder = 'إعادة الطلب';
  static const String orderConfirmationTitle = 'تأكيد الطلب';
  static const String orderPlacedMessage =
      'تم استلام طلبك بنجاح! سنقوم بتحضيره قريباً.';
  static const String orderSummaryLabel = 'ملخص الطلب';
  static const String itemCountLabel = 'عدد الأصناف';
  static const String subtotalLabel = 'المجموع الفرعي';
  static const String taxLabel = 'الضريبة (15%)';
  static const String estimatedTimeLabel = 'الوقت المتوقع';
  static const String minutes = 'دقيقة';
  static const String statusLabel = 'الحالة';
  static const String backToMenu = 'العودة إلى القائمة';

  // ── Cart ───────────────────────────────────────────────────────────────────
  static const String cartTitle = 'سلة الطلب';
  static const String cartEmpty = 'العربة فارغة';
  static const String addToCart = 'أضف إلى السلة';
  static const String checkout = 'إتمام الطلب';
  static const String totalLabel = 'الإجمالي';
  static const String itemCount = 'عدد الأصناف';

  // ── Menu ───────────────────────────────────────────────────────────────────
  static const String menuTitle = 'القائمة';
  static const String searchHint = 'ابحث عن طبق…';
  static const String categoriesLabel = 'التصنيفات';
  static const String featuredLabel = 'الأطباق المميزة';
  static const String noItemsFound = 'لا توجد أصناف مطابقة';

  // ── Common UI ──────────────────────────────────────────────────────────────
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String confirm = 'تأكيد';
  static const String retry = 'إعادة المحاولة';
  static const String ok = 'حسناً';
  static const String delete = 'حذف';
  static const String back = 'رجوع';
  static const String loading = 'جارٍ التحميل…';
  static const String optional = '(اختياري)';

  // ── Staff / Tables ──────────────────────────────────────────────────────────
  static const String staffTitle = 'شاشة الموظفين';
  static const String tablesTitle = 'الطاولات';
  static const String tableStatusAvailable = 'متاحة';
  static const String tableStatusOccupied = 'مشغولة';
  static const String tableStatusReserved = 'محجوزة';
  static const String tableStatusNeedsCleaning = 'تحتاج تنظيف';
  static const String tableCapacityLabel = 'مقاعد';
  static const String tableActionTakeOrder = 'أخذ الطلب';
  static const String tableActionRelease = 'تسليم الطاولة';
  static const String tableActionClean = 'تم التنظيف';
  static const String tableActionReserve = 'حجز';
  static const String tableNoActiveOrder = 'لا يوجد طلب نشط';
  static const String seats = 'مقاعد';
  static const String sendToKitchen = 'إرسال إلى المطبخ';
  static const String sentToKitchen = 'تم إرسال الطلب إلى المطبخ';
  static const String newOrderAlert = 'طلب جديد';
  static const String orderHistoryTitle = 'سجل الطلبات';
  static const String reorderAction = 'أعد الطلب';
  static const String tableDetailTitle = 'تفاصيل الطاولة';
  static const String tableActiveOrder = 'الطلب النشط';
  static const String tableNoOrder = 'لا يوجد طلب نشط';
  static const String actionCleanTable = 'تم التنظيف';
  static const String actionReserveTable = 'حجز الطاولة';
  static const String actionReleaseTable = 'تسليم الطاولة';
  static const String allOrdersTitle = 'جميع الطلبات';
  static const String filterAll = 'الكل';
  static const String noOrdersFound = 'لا توجد طلبات حالياً';
  static const String orderCompletedToaster = 'تم تحديث حالة الطلب';
  static const String searchMenuHint = 'ابحث عن صنف...';
  static const String demoAccountsTitle = 'حسابات تجريبية';
  static const String demoPasswordHint = 'كلمة المرور: 123456';
  static const String specialNotesLabel = 'ملاحظات الطلب';
  static const String pickupTimeLabel = 'وقت الجهوزية';
  static const String orderItemsLabel = 'تفاصيل الطلب';
  static const String paymentMethodLabel = 'طريقة الدفع';
  static const String paymentCash = 'نقداً';
  static const String paymentCard = 'بطاقة';
  static const String paymentMethodDisplayLabel = 'الدفع';
  static const String cartEmptySend = 'أضف أصنافاً أولاً';
  static const String metricsByCategory = 'الإيرادات حسب الفئة';
  static const String deliveryEtaLabel = 'الوقت المتوقع للوصول';
  static const String kdsNewBadge = 'جديد';
  static const String dietAll = 'الكل';
  static const String dietVegetarian = 'نباتي';
  static const String dietSpicy = 'حار';
  static const String metricsByPayment = 'الإيرادات حسب طريقة الدفع';
  static const String paymentUnknown = 'غير محدد';

  // ── KDS / Kitchen ─────────────────────────────────────────────────────────
  static const String kdsTitle = 'شاشة المطبخ';
  static const String kdsPending = 'بانتظار التحضير';
  static const String kdsPreparing = 'قيد التحضير';
  static const String kdsReady = 'جاهز للتسليم';
  static const String kdsCompleting = 'استكمال';

  // ── Manager ────────────────────────────────────────────────────────────────
  static const String managerTitle = 'لوحة المدير';
  static const String metricsSalesTitle = 'إجمالي المبيعات';
  static const String metricsOrdersTitle = 'عدد الطلبات';
  static const String metricsAvgOrderTitle = 'متوسط قيمة الطلب';
  static const String metricsActiveTitle = 'طلبات نشطة';
  static const String metricsOverview = 'نظرة عامة';
  static const String metricsItemsSold = 'الأصناف الأكثر مبيعاً';
  static const String metricsNoData = 'لا توجد بيانات بعد';
  static const String salesTitle = 'المبيعات';

  // ── Driver / Delivery ────────────────────────────────────────────────────
  static const String driverTitle = 'شاشة السائق';
  static const String deliveryPending = 'بانتظار التوكيل';
  static const String deliveryAccepted = 'مقبول';
  static const String deliveryInTransit = 'قيد التوصيل';
  static const String deliveryDelivered = 'تم التسليم';
  static const String deliveryFailed = 'فشل التسليم';
  static const String deliveryPickedUp = 'تم الاستلام';
  static const String actionAccept = 'قبول التوصيل';
  static const String actionStartDelivery = 'بدء التوصيل';
  static const String actionCompleteDelivery = 'تسليم الطلب';
  static const String deliveryLocationLabel = 'العنوان';
  static const String noDeliveryJobs = 'لا توجد مهام توصيل حالياً';

  // ── Validation messages ────────────────────────────────────────────────────
  static const String invalidEmail = 'أدخل بريداً إلكترونياً صحيحاً';
  static const String invalidPhone =
      'أدخل رقم جوال سعودياً صحيحاً (05xxxxxxxx)';
  static const String invalidOtp = 'أدخل رمز التحقق المكوّن من 6 أرقام';
  static const String invalidName = 'أدخل اسماً صحيحاً';
  static const String requiredField = 'هذا الحقل مطلوب';

  // ── Error messages ─────────────────────────────────────────────────────────
  static const String errorConnection = 'خطأ في الاتصال';
  static const String errorServer = 'حدث خطأ في الخادم';
  static const String errorGeneric = 'حدث خطأ غير متوقع';
  static const String errorInvalidCredentials = 'بيانات الدخول غير صحيحة';
  static const String errorSessionExpired =
      'انتهت الجلسة، سجّل الدخول مرة أخرى';
  static const String errorCartEmpty = 'العربة فارغة';
  static const String errorNoNetwork = 'لا يوجد اتصال بالإنترنت';
  static const String errorTimeout = 'انتهت مهلة الطلب، حاول مرة أخرى';
  static const String errorCache = 'تعذر حفظ البيانات محلياً';
}

/// Arabic labels for order statuses.
///
/// Uses string keys instead of a domain enum so the UI layer can map any
/// backend-provided status without introducing a hard dependency.
abstract final class OrderStatusAr {
  OrderStatusAr._();

  /// Map of backend order status keys to their Arabic labels.
  static const Map<String, String> labels = <String, String>{
    'pending': 'قيد الانتظار',
    'confirmed': 'مؤكد',
    'preparing': 'قيد التحضير',
    'ready': 'جاهز',
    'delivering': 'قيد التوصيل',
    'delivered': 'تم التوصيل',
    'completed': 'مكتمل',
    'cancelled': 'ملغي',
    'rejected': 'مرفوض',
  };

  /// Returns the Arabic label for [status], falling back to the raw key when
  /// the status is unknown.
  static String labelOf(String status) => labels[status] ?? status;
}
