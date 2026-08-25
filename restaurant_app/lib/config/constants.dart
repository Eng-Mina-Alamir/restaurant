/// Centralized Arabic string constants for the app.
///
/// Kept as pure Dart (no Flutter imports) so the strings can be consumed from
/// any layer, including the domain layer and unit tests.
abstract final class AppConstants {
  AppConstants._();

  // ── Auth / Login ───────────────────────────────────────────────────────────
  static const String loginSubtitle = 'مرحباً بعودتك! سجّل للوصول إلى طلباتك';
  static const String emailLabel = 'البريد الإلكتروني';
  static const String passwordLabel = 'كلمة المرور';
  static const String loginButton = 'دخول';

  // ── Orders ─────────────────────────────────────────────────────────────────
  static const String orderNumberLabel = 'رقم الطلب';
  static const String orderTotalLabel = 'الإجمالي';
  static const String emptyOrders = 'لا توجد طلبات حالياً';
  static const String orderConfirmationTitle = 'تأكيد الطلب';
  static const String orderPlacedMessage =
      'تم استلام طلبك بنجاح! سنقوم بتحضيره قريباً.';
  static const String orderSummaryLabel = 'ملخص الطلب';
  static const String itemCountLabel = 'عدد الأصناف';
  static const String subtotalLabel = 'المجموع الفرعي';
  static const String taxLabel = 'الضريبة (15%)';
  static const String estimatedTimeLabel = 'الوقت المتوقع';
  static const String minutes = 'دقيقة';
  static const String sincePrefix = 'منذ';
  static const String distanceLabel = 'المسافة';
  static const String unitKm = 'كم';
  static const String unitMeter = 'م';
  static const String statusLabel = 'الحالة';
  static const String backToMenu = 'العودة إلى القائمة';

  // ── Cart ───────────────────────────────────────────────────────────────────
  static const String cartTitle = 'سلة الطلب';
  static const String cartEmpty = 'العربة فارغة';
  static const String cartEmptyBrowse = 'تصفح القائمة';
  static const String clearCart = 'إفراغ السلة';
  static const String cartCleared = 'تم إفراغ السلة';
  static const String addToCart = 'أضف إلى السلة';
  static const String customizeOrder = 'تخصيص الطلب';
  static const String checkout = 'إتمام الطلب';
  static const String totalLabel = 'الإجمالي';

  // ── Menu ───────────────────────────────────────────────────────────────────
  static const String menuTitle = 'القائمة';
  static const String noItemsFound = 'لا توجد أصناف مطابقة';

  // ── Common UI ──────────────────────────────────────────────────────────────
  static const String ok = 'حسناً';
  static const String cancel = 'إلغاء';
  static const String delete = 'حذف';
  static const String notFoundTitle = 'الصفحة غير موجودة';
  static const String notFoundAction = 'العودة للرئيسية';

  // ── Staff / Tables ──────────────────────────────────────────────────────────
  static const String tablesTitle = 'الطاولات';
  static const String tableStatusAvailable = 'متاحة';
  static const String tableStatusOccupied = 'مشغولة';
  static const String tableStatusReserved = 'محجوزة';
  static const String tableStatusNeedsCleaning = 'تحتاج تنظيف';
  static const String tableActionTakeOrder = 'أخذ الطلب';
  static const String tableActionRelease = 'تسليم الطاولة';
  static const String tableActionReserve = 'حجز';
  static const String seats = 'مقاعد';
  static const String sendToKitchen = 'إرسال إلى المطبخ';
  static const String sentToKitchen = 'تم إرسال الطلب إلى المطبخ';
  static const String orderHistoryTitle = 'سجل الطلبات';

  /// Display window for the customer order-history page: how many of the
  /// newest orders render initially ([orderHistoryInitialWindow]) and how
  /// many more each "عرض المزيد" tap reveals ([orderHistoryPageSize]).
  /// Purely a UI pagination knob — the session list itself is never trimmed.
  static const int orderHistoryInitialWindow = 20;
  static const int orderHistoryPageSize = 20;
  static const String orderHistoryLoadMore = 'عرض المزيد';
  static const String reorderAction = 'أعد الطلب';
  static const String tableDetailTitle = 'تفاصيل الطاولة';
  static const String tableActiveOrder = 'الطلب النشط';
  static const String tableNoOrder = 'لا يوجد طلب نشط';
  static const String allOrdersTitle = 'جميع الطلبات';
  static const String filterAll = 'الكل';
  static const String orderCompletedToaster = 'تم تحديث حالة الطلب';
  static const String orderItemsCount = 'عناصر';
  static const String orderTablePrefix = 'طاولة';
  static const String orderMoveTo = 'نقل إلى:';
  static const String searchMenuHint = 'ابحث عن صنف...';
  static const String demoAccountsTitle = 'حسابات تجريبية';
  static const String demoPasswordHint = 'كلمة المرور: 123456';
  static const String specialNotesLabel = 'ملاحظات الطلب';
  static const String specialNotesHint = 'اكتب ملاحظاتك هنا (اختياري)';
  static const String pickupTimeLabel = 'وقت الجهوزية';
  static const String orderItemsLabel = 'تفاصيل الطلب';
  static const String paymentMethodLabel = 'طريقة الدفع';
  static const String paymentCash = 'نقداً';
  static const String paymentCard = 'بطاقة';
  static const String paymentWallet = 'محفظة رقمية';
  static const String paymentOnline = 'دفع أونلاين';
  static const String paymentMethodDisplayLabel = 'الدفع';
  static const String orderTypeDineIn = 'في المطعم';
  static const String orderTypeTakeaway = 'طلب سفري';
  static const String orderTypeDelivery = 'توصيل';
  static const String roleCustomer = 'عميل';
  static const String roleWaiter = 'نادل';
  static const String roleKitchen = 'مطبخ';
  static const String roleManager = 'مدير';
  static const String roleAdmin = 'مسؤول';
  static const String roleDriver = 'سائق';
  static const String cartEmptySend = 'أضف أصنافاً أولاً';
  static const String metricsByCategory = 'الإيرادات حسب الفئة';
  static const String deliveryEtaLabel = 'الوقت المتوقع للوصول';
  static const String kdsNewBadge = 'جديد';
  static const String kdsEmptyColumn = 'لا توجد طلبات';
  static const String dietAll = 'الكل';
  static const String dietVegetarian = 'نباتي';
  static const String dietSpicy = 'حار';
  static const String itemUnavailable = 'غير متوفر';
  static const String metricsByPayment = 'الإيرادات حسب طريقة الدفع';
  static const String metricsOrdersByStatus = 'الطلبات حسب الحالة';
  static const String paymentUnknown = 'غير محدد';
  static const String reorderFailed = 'لا يوجد أصناف لإعادة طلبها';
  static const String reorderSkipped = 'تم تخطي';
  static const String waiterOrdersSummary = 'الطلبات النشطة';
  static const String waiterPendingCount = 'قيد الانتظار';
  static const String waiterPreparingCount = 'قيد التحضير';
  static const String waiterReadyCount = 'جاهزة للتسليم';
  static const String waiterReadyForPickupBadge = 'جاهز للاستلام';
  static const String waiterPickupAlertMessage = 'طلب جاهز للاستلام من المطبخ';
  static const String driverFilterAll = 'الكل';
  static const String logout = 'تسجيل الخروج';
  static const String logoutMessage = 'تم تسجيل الخروج بنجاح';

  // ── KDS / Kitchen ─────────────────────────────────────────────────────────
  static const String kdsTitle = 'شاشة المطبخ';
  static const String kdsPending = 'بانتظار التحضير';
  static const String kdsPreparing = 'قيد التحضير';
  static const String kdsReady = 'جاهز للتسليم';
  static const String kdsCompleting = 'استكمال';
  static const String kdsClaimOrder = 'استلام الطلب';
  static const String kdsRevertTooltip = 'تراجع عن الحالة';
  static const String kdsRevertConfirmAction = 'تأكيد التراجع';

  // ── Order audit trail ─────────────────────────────────────────────────────
  static const String orderAuditTrailTitle = 'سجل الحالة';
  static const String orderAuditTrailEmpty = 'لا يوجد سجل لهذا الطلب';
  static const String orderAuditTrailReasonPrefix = 'السبب:';
  static const String orderAuditTrailActorPrefix = 'بواسطة:';
  static const String orderAuditTrailRevertBadge = 'تراجع';
  static const String orderAuditTrailLoadFailed = 'تعذر تحميل سجل الحالة';
  static const String orderAuditTrailRetryAction = 'إعادة المحاولة';

  // ── Manager ────────────────────────────────────────────────────────────────
  static const String managerTitle = 'لوحة المدير';
  static const String metricsSalesTitle = 'إجمالي المبيعات';
  static const String metricsOrdersTitle = 'عدد الطلبات';
  static const String metricsAvgOrderTitle = 'متوسط قيمة الطلب';
  static const String metricsActiveTitle = 'طلبات نشطة';
  static const String metricsOverview = 'نظرة عامة';
  static const String metricsItemsSold = 'الأصناف الأكثر مبيعاً';
  static const String metricsNoData = 'لا توجد بيانات بعد';
  static const String dispatchHealthPendingOrders = 'طلبات بانتظار سواق';
  static const String dispatchHealthFailedAssignments = 'تكليفات فاشلة';
  static const String dispatchHealthAvailableDrivers = 'سواق متاحون';
  static const String dispatchHealthLoading = 'جارٍ تحميل حالة التوصيل…';
  static const String dispatchHealthUnavailable = 'تعذر تحميل حالة التوصيل';

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
  static const String customerPhoneLabel = 'رقم العميل';
  static const String deliveryFeeLabel = 'رسوم التوصيل';
  static const String noDeliveryJobs = 'لا توجد مهام توصيل حالياً';
  static const String driverNewAssignmentAlert = 'مهمة توصيل جديدة';
  static const String driverNewAssignmentOrderPrefix = 'طلب';
  static const String unreadChatMessagesLabel = 'رسائل غير مقروءة';
  static const String unknownDriverName = 'سائق غير معروف';
  static const String rateDriverAction = 'قيّم السائق';
  static const String rateDriverDialogTitle = 'تقييم السائق';
  static const String rateDriverDialogSubtitle = 'ما رأيك في خدمة التوصيل؟';

  // ── Validation messages ────────────────────────────────────────────────────
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
  static const String errorCache = 'تعذر حفظ البيانات محلياً';
  static const String errorDemoUnavailable = 'غير متاح في وضع العرض';
  static const String errorInvalidToken = 'رمز غير صالح';
  static const String errorInvalidResponse = 'استجابة غير صالحة';

  static const String errorLoadingData = 'تعذر تحميل البيانات';
  static const String retryAction = 'إعادة المحاولة';

  /// Renders a UI error line with the exception detail appended, e.g.
  /// `خطأ: <err>`. Used by `.when(error: ...)` branches in pages.
  static String errorWithDetail(Object err) => 'خطأ: $err';
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
