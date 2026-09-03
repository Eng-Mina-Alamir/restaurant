import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_localizations.dart';
import '../utils/formatters.dart';

/// Comprehensive bilingual translation lookup dictionary (Arabic & English).
class AppStrings {
  final Locale locale;
  AppStrings(this.locale);

  bool get isArabic => locale.languageCode == 'ar';
  bool get isRtl => isArabic;
  String get currency => isArabic ? 'ج.م' : 'EGP';

  // ── Auth & Accounts ────────────────────────────────────────────────────────
  String get loginTitle => isArabic ? 'تسجيل الدخول' : 'Sign In';
  String get loginSubtitle => isArabic
      ? 'مرحباً بعودتك! سجّل للوصول إلى حسابك'
      : 'Welcome back! Sign in to continue';
  String get emailLabel => isArabic ? 'البريد الإلكتروني' : 'Email Address';
  String get passwordLabel => isArabic ? 'كلمة المرور' : 'Password';
  String get confirmPasswordLabel => isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get nameLabel => isArabic ? 'الاسم بالكامل' : 'Full Name';
  String get phoneLabel => isArabic ? 'رقم الهاتف' : 'Phone Number';
  String get loginButton => isArabic ? 'دخول' : 'Login';
  String get registerTitle => isArabic ? 'إنشاء حساب جديد' : 'Create Account';
  String get registerSubtitle => isArabic
      ? 'سجل بياناتك للبدء في استخدام النظام بكل سهولة'
      : 'Enter your details to easily get started';
  String get registerButton => isArabic ? 'إنشاء الحساب' : 'Register';
  String get haveAccount => isArabic ? 'لديك حساب بالفعل؟' : 'Already have an account?';
  String get noAccount => isArabic ? 'ليس لديك حساب؟' : "Don't have an account?";
  String get demoAccountsTitle => isArabic ? 'حسابات تجريبية' : 'Demo Accounts';
  String get demoPasswordHint => isArabic ? 'كلمة المرور: 123456' : 'Password: 123456';
  String get logout => isArabic ? 'تسجيل الخروج' : 'Logout';
  String get logoutConfirmation => isArabic ? 'هل تريد تسجيل الخروج؟' : 'Are you sure you want to logout?';
  String get logoutSuccess => isArabic ? 'تم تسجيل الخروج بنجاح' : 'Logged out successfully';

  // ── Roles ──────────────────────────────────────────────────────────────────
  String get roleCustomer => isArabic ? 'عميل' : 'Customer';
  String get roleWaiter => isArabic ? 'كابتن صالة (ويتر)' : 'Waiter';
  String get roleKitchen => isArabic ? 'شيف مطبخ' : 'Kitchen Chef';
  String get roleManager => isArabic ? 'مدير فرع' : 'Branch Manager';
  String get roleAdmin => isArabic ? 'إدارة السلسلة (Admin)' : 'Chain Admin';
  String get roleDriver => isArabic ? 'مندوب توصيل' : 'Delivery Driver';
  String get roleCashier => isArabic ? 'كاشير' : 'Cashier';

  // ── Manager Dashboard & Multi-Branch ───────────────────────────────────────
  String get adminTitle => isArabic ? 'لوحة تحكم السلسلة (Admin)' : 'Chain Hub (Admin)';
  String get managerTitle => isArabic ? 'لوحة المدير' : 'Manager Dashboard';
  String get managerSubtitle => isArabic ? 'إدارة الفرع والعمليات' : 'Branch Operations & Management';
  String get allBranches => isArabic ? '🌐 كل الفروع (السلسلة)' : '🌐 All Branches (Chain)';
  String get addBranch => isArabic ? 'فرع جديد' : 'New Branch';
  String get branchPerformance => isArabic ? 'أداء وحالة فروع السلسلة' : 'Chain Branch Performance';
  String get chainTotalSales => isArabic ? 'إجمالي مبيعات السلسلة' : 'Total Chain Sales';
  String get chainTotalOrders => isArabic ? 'إجمالي طلبات السلسلة' : 'Total Chain Orders';
  String get chainActiveOrders => isArabic ? 'الطلبات النشطة بالسلسلة' : 'Active Chain Orders';
  String get activeBranchesCount => isArabic ? 'الفروع النشطة' : 'Active Branches';
  String get open => isArabic ? 'مفتوح' : 'Open';
  String get closed => isArabic ? 'مغلق' : 'Closed';
  String get live => isArabic ? 'مباشر' : 'Live';
  String get generalOverview => isArabic ? 'نظرة عامة' : 'Overview';
  String get metricsSalesTitle => isArabic ? 'إجمالي المبيعات' : 'Total Sales';
  String get metricsOrdersTitle => isArabic ? 'عدد الطلبات' : 'Total Orders';
  String get metricsAvgOrderTitle => isArabic ? 'متوسط قيمة الطلب' : 'Average Order';
  String get metricsActiveTitle => isArabic ? 'طلبات نشطة' : 'Active Orders';
  String get todaySalesBranch => isArabic ? 'مبيعات اليوم للفرع' : "Today's Branch Sales";
  String get totalOrdersBranch => isArabic ? 'إجمالي طلبات الفرع' : 'Total Branch Orders';
  String get avgCart => isArabic ? 'متوسط السلة' : 'Avg Ticket';
  String get inProgressBranch => isArabic ? 'قيد التنفيذ بالفرع' : 'In Progress';
  String get welcomeManager => isArabic ? 'أهلاً بك' : 'Welcome';
  String get welcomeAdmin => isArabic ? 'أهلاً بك في لوحة السلسلة' : 'Welcome to Chain Hub';
  String get readyAndReceiving => isArabic ? 'فريقك جاهز ويستقبل الطلبات بكل حب' : 'Your team is ready and welcoming orders with care';
  String get centralView => isArabic ? 'الرؤية المركزية لجميع فروع ومبيعات السلسلة' : 'Central monitoring across all branches';
  String get quickActions => isArabic ? 'الإجراءات والخدمات السريعة' : 'Quick Actions & Services';
  String get analyticsTitle => isArabic ? 'التحليلات البيانية والمبيعات' : 'Analytics & Charts';
  String get leaderboardTitle => isArabic ? 'ترتيب الفروع حسب حجم المبيعات اليوم' : 'Branch Sales Leaderboard Today';
  String get branchNameLabel => isArabic ? 'اسم الفرع' : 'Branch Name';
  String get branchAddressLabel => isArabic ? 'عنوان الفرع' : 'Branch Address';
  String get branchPhoneLabel => isArabic ? 'هاتف الفرع' : 'Branch Phone';
  String get branchManagerLabel => isArabic ? 'اسم مدير الفرع' : 'Branch Manager';
  String get branchStatusLabel => isArabic ? 'حالة الفرع' : 'Branch Status';
  String get saveBranch => isArabic ? 'حفظ الفرع' : 'Save Branch';
  String get branchAddedSuccess => isArabic ? 'تم إضافة الفرع بنجاح' : 'Branch added successfully';
  String get switchApps => isArabic ? 'التبديل بين شاشات النظام' : 'Switch System Apps';

  // ── Fleet & Dispatch ───────────────────────────────────────────────────────
  String get dispatchFleetTitle => isArabic ? 'حالة أسطول التوصيل والتكليف' : 'Fleet & Dispatch Health';
  String get dispatchBoard => isArabic ? 'لوحة التوزيع' : 'Dispatch Board';
  String get availableDrivers => isArabic ? 'سواق متاحون' : 'Available Drivers';
  String get failedAssignments => isArabic ? 'تكليفات فاشلة' : 'Failed Dispatch';
  String get pendingDrivers => isArabic ? 'طلبات بانتظار سواق' : 'Pending Orders';
  String get assignDriver => isArabic ? 'تكليف سائق' : 'Assign Driver';
  String get reassignDriver => isArabic ? 'إعادة التكليف' : 'Reassign Driver';

  // ── Orders Pipeline ────────────────────────────────────────────────────────
  String get ordersPipeline => isArabic ? 'خط مسار الطلبات' : 'Orders Pipeline';
  String get ordersByStatus => isArabic ? 'الطلبات حسب الحالة' : 'Orders by Status';
  String get noActiveOrders => isArabic ? 'لا توجد طلبات جارية الآن' : 'No active orders right now';
  String get ordersWillAppear => isArabic
      ? 'ستظهر جميع مراحل وإحصائيات الطلبات فور تسجيلها في النظام'
      : 'Orders and statistics will appear here when placed';
  String get orderNumber => isArabic ? 'رقم الطلب' : 'Order #';
  String get orderDate => isArabic ? 'تاريخ الطلب' : 'Order Date';
  String get orderType => isArabic ? 'نوع الطلب' : 'Order Type';
  String get orderStatus => isArabic ? 'حالة الطلب' : 'Order Status';
  String get orderTotal => isArabic ? 'الإجمالي' : 'Total';
  String get emptyOrders => isArabic ? 'لا توجد طلبات حالياً — استمتع بهدوء اللحظة' : 'No orders right now — enjoy the calm moment';
  String get orderHistoryTitle => isArabic ? 'سجل الطلبات' : 'Order History';
  String get orderHistoryLoadMore => isArabic ? 'عرض المزيد' : 'Load More';
  String get reorderAction => isArabic ? 'إعادة الطلب' : 'Reorder';
  String get reorderSuccess => isArabic ? 'تمت إضافة الأصناف إلى السلة' : 'Items added to cart';
  String get reorderFailed => isArabic ? 'لا توجد أصناف لإعادة طلبها' : 'No items to reorder';
  String get allOrdersTitle => isArabic ? 'جميع الطلبات' : 'All Orders';
  String get filterAll => isArabic ? 'الكل' : 'All';
  String get orderCompletedToaster => isArabic ? 'تم تحديث حالة الطلب' : 'Order status updated';
  String get itemsCount => isArabic ? 'عناصر' : 'Items';
  String get orderItemsLabel => isArabic ? 'تفاصيل الطلب' : 'Order Items';
  String get orderSummaryLabel => isArabic ? 'ملخص الطلب' : 'Order Summary';
  String get estimatedTimeLabel => isArabic ? 'الوقت المتوقع' : 'Estimated Time';
  String get minutes => isArabic ? 'دقيقة' : 'mins';
  String get pickupTimeLabel => isArabic ? 'وقت الجهوزية' : 'Ready Time';
  String get specialNotesLabel => isArabic ? 'ملاحظات الطلب' : 'Order Notes';
  String get specialNotesHint => isArabic ? 'اكتب ملاحظاتك هنا (اختياري)...' : 'Add special instructions (optional)...';

  // ── Shift Management & Cashier POS Hub ─────────────────────────────────────
  String get cashierPosHub => isArabic ? 'نقطة البيع والكاشير' : 'Cashier POS Hub';
  String get shiftManagementTitle => isArabic ? 'إدارة الوردية والصندوق' : 'Shift & Cash Register';
  String get shiftSubtitle => isArabic ? 'جرد الكاش وتقارير Z-Report' : 'Cash Audit & Z-Reports';
  String get activeShiftStatus => isArabic ? 'وردية نشطة حالياً' : 'Active Shift';
  String get shiftClosedStatus => isArabic ? 'الوردية مقفلة' : 'Shift Closed';
  String get noActiveShift => isArabic ? 'لا توجد وردية مفتوحة حالياً للكاشير' : 'No Active Cashier Shift';
  String get noActiveShiftSubtitle => isArabic
      ? 'يرجى تسجيل العهدة الافتتاحية وبدء الوردية لتفعيل نقطة البيع وتسجيل المدفوعات'
      : 'Please open a shift and enter opening float to begin selling';
  String get openNewShift => isArabic ? 'بدء وردية جديدة واستلام العهدة' : 'Start New Cashier Shift';
  String get openShiftTitle => isArabic ? 'فتح وردية واستلام الدرج' : 'Open Shift & Cash Drawer';
  String get openShiftSubtitle => isArabic ? 'تسجيل عهدة بداية اليوم وتفعيل نقطة البيع' : 'Record opening float and enable POS';
  String get closeShiftButton => isArabic ? 'إقفال الوردية وجرد الصندوق (Z-Report)' : 'Close Shift & Audit (Z-Report)';
  String get closeShiftTitle => isArabic ? 'إقفال الوردية وجرد الصندوق' : 'Close Shift & Cash Audit';
  String get closeShiftSubtitle => isArabic ? 'Z-Report • تقفيل الحسابات ومطابقة النقدية' : 'Z-Report • Reconcile & Audit Drawer';
  String get openingFloat => isArabic ? 'العهدة الافتتاحية' : 'Opening Float';
  String get openingFloatHint => isArabic ? 'العهدة الافتتاحية (ج.م) النقد في الدرج' : 'Opening float amount';
  String get completedOrders => isArabic ? 'الطلبات المكتملة' : 'Paid Orders';
  String get expectedCash => isArabic ? 'إجمالي النقد المتوقع في الدرج:' : 'Expected Drawer Cash:';
  String get actualCashCount => isArabic ? 'النقد الفعلي الموجود في الدرج (جرد الكاشير):' : 'Actual Cash Count in Drawer:';
  String get cashierResponsible => isArabic ? 'المسؤول' : 'Cashier';
  String get startedAt => isArabic ? 'بدأت في' : 'Started at';
  String get paymentMethodsBreakdown => isArabic ? 'تفصيل المقبوضات حسب وسيلة الدفع:' : 'Receipts by Payment Method:';
  String get cashSales => isArabic ? 'كاش نقد' : 'Cash';
  String get cardSales => isArabic ? 'بطاقة / مدى' : 'Card / Visa';
  String get walletSales => isArabic ? 'محفظة إلكترونية' : 'Digital Wallet';
  String get totalSales => isArabic ? 'إجمالي المبيعات' : 'Total Sales';
  String get cashInDrawer => isArabic ? 'النقد بالدرج' : 'Cash in Drawer';
  String get pastShiftsLog => isArabic ? 'سجل الورديات المقفلة السابقة' : 'Past Closed Shifts History';
  String get noPastShifts => isArabic ? 'لا توجد ورديات سابقة مقفلة حتى الآن' : 'No closed shifts in history yet';
  String get cashDiscrepancy => isArabic ? 'الفارق النقدي' : 'Cash Difference';
  String get cashMatched => isArabic ? 'المبلغ مطابق تماماً للعهدة والمبيعات (لا يوجد عجز أو زيادة)' : 'Exact match: No surplus or deficit';
  String get cashSurplus => isArabic ? 'يوجد فائض بالدرج بمقدار:' : 'Cash Surplus:';
  String get cashDeficit => isArabic ? 'يوجد عجز بالدرج بمقدار:' : 'Cash Deficit:';
  String get zReportPrint => isArabic ? 'طباعة التقرير المالي للوردية (Z-Report)' : 'Print Shift Z-Report';
  String get zReportSuccess => isArabic ? 'تم إقفال الوردية وحفظ تقرير Z-Report بنجاح' : 'Shift closed and Z-Report saved';
  String get confirmShiftStart => isArabic ? 'تأكيد وبدء الوردية' : 'Confirm & Start Shift';
  String get shiftStartedSuccess => isArabic ? 'تم فتح الوردية وتفعيل الصندوق بنجاح' : 'Shift opened successfully';
  String get recentShiftReceipts => isArabic ? 'آخر فواتير الوردية المحصلة' : 'Recent Shift Receipts';
  String get noRecentReceipts => isArabic ? 'لا توجد فواتير محصلة في هذه الوردية بعد' : 'No completed receipts in this shift yet';
  String get viewAll => isArabic ? 'عرض الكل' : 'View All';

  // ── Customer Menu & Food Ordering ──────────────────────────────────────────
  String get menuTitle => isArabic ? 'قائمة الطعام' : 'Food Menu';
  String get searchMenuHint => isArabic ? 'دوّر على كبسة، برجر، مشويات...؟' : 'Search meals & drinks...';
  String get noItemsFound => isArabic ? 'لم نجد طبقاً مطابقاً — جرّب كلمة مختلفة أو تصفح القائمة كاملة' : 'No matching dishes — try another word or browse the full menu';
  String get categoryAll => isArabic ? 'الكل' : 'All';
  String get categoryBurgers => isArabic ? 'برجر' : 'Burgers';
  String get categoryPizza => isArabic ? 'بيتزا' : 'Pizza';
  String get categoryGrills => isArabic ? 'مشويات' : 'Grills';
  String get categoryDrinks => isArabic ? 'مشروبات' : 'Beverages';
  String get categoryDesserts => isArabic ? 'حلويات' : 'Desserts';
  String get categoryAppetizers => isArabic ? 'مقبلات' : 'Appetizers';
  String get dietaryVegetarian => isArabic ? 'نباتي' : 'Vegetarian';
  String get dietarySpicy => isArabic ? 'حار' : 'Spicy';
  String get itemUnavailable => isArabic ? 'غير متوفر حالياً' : 'Currently Unavailable';
  String get itemCustomization => isArabic ? 'تخصيص الوجبة' : 'Item Customization';
  String get selectSize => isArabic ? 'اختر الحجم' : 'Select Size';
  String get selectAddons => isArabic ? 'الإضافات الإضافية' : 'Extra Add-ons';
  String get quantity => isArabic ? 'الكمية' : 'Quantity';
  String get addToCart => isArabic ? 'أضف إلى السلة' : 'Add to Cart';
  String get itemAddedToCart => isArabic ? 'تمت إضافة الصنف إلى السلة' : 'Item added to cart';
  String get customizeOrder => isArabic ? 'تخصيص الطلب' : 'Customize Order';

  // ── Cart & Checkout ────────────────────────────────────────────────────────
  String get cartTitle => isArabic ? 'سلة المشتريات' : 'Shopping Cart';
  String get cartEmpty => isArabic ? 'سلتك فارغة حالياً — ما رأيك بتصفح أطباقنا الشهية؟' : 'Your cart is empty — how about browsing our tasty dishes?';
  String get cartEmptyBrowse => isArabic ? 'تصفح قائمة الطعام وأضف وجباتك المفضلة' : 'Browse menu and add your favorite meals';
  String get clearCart => isArabic ? 'إفراغ السلة' : 'Clear Cart';
  String get cartCleared => isArabic ? 'تم إفراغ السلة بنجاح' : 'Cart cleared successfully';
  String get checkout => isArabic ? 'إتمام ودفع الطلب' : 'Checkout & Pay';
  String get dineIn => isArabic ? 'في المطعم (صالة)' : 'Dine-In';
  String get takeaway => isArabic ? 'استلام سفري (تيك أواي)' : 'Takeaway';
  String get delivery => isArabic ? 'توصيل للمنزل' : 'Delivery';
  String get selectOrderType => isArabic ? 'اختر طريقة استلام الطلب' : 'Select Order Type';
  String get selectDineInTable => isArabic ? 'اختر رقم الطاولة' : 'Select Table Number';
  String get deliveryAddressLabel => isArabic ? 'عنوان التوصيل بالتفصيل' : 'Delivery Address';
  String get deliveryNotesLabel => isArabic ? 'ملاحظات للسائق أو العنوان' : 'Driver notes or landmark';
  String get deliveryFee => isArabic ? 'رسوم التوصيل' : 'Delivery Fee';
  String get couponCodeLabel => isArabic ? 'كود الخصم' : 'Promo Code';
  String get couponCodeHint => isArabic ? 'أدخل رمز الكوبون...' : 'Enter promo code...';
  String get applyCoupon => isArabic ? 'تطبيق الكود' : 'Apply';
  String get couponApplied => isArabic ? 'تم تطبيق الخصم بنجاح!' : 'Promo code applied!';
  String get couponInvalid => isArabic ? 'رمز الخصم غير صالح أو منتهي' : 'Invalid or expired promo code';
  String get couponRemoved => isArabic ? 'تم إزالة كود الخصم' : 'Promo code removed';
  String get subtotal => isArabic ? 'المجموع الفرعي' : 'Subtotal';
  String get tax => isArabic ? 'ضريبة القيمة المضافة (15%)' : 'VAT (15%)';
  String get discount => isArabic ? 'الخصم' : 'Discount';
  String get total => isArabic ? 'المبلغ الإجمالي' : 'Grand Total';
  String get placeOrder => isArabic ? 'تأكيد وإرسال الطلب' : 'Confirm & Place Order';
  String get orderPlacedSuccess => isArabic ? 'تم استلام طلبك بنجاح! فريقنا يجهزه لك بحب' : 'Order received! Our team is preparing it with care';
  String get orderConfirmationTitle => isArabic ? 'تأكيد الطلب' : 'Order Confirmation';
  String get orderTrackingTitle => isArabic ? 'تتبع الطلب' : 'Track Order';
  String get orderTrackingSubtitle => isArabic ? 'متابعة حالة طلبك خطوة بخطوة' : 'Follow your order step by step';
  String get orderReceived => isArabic ? 'تم استلام الطلب' : 'Order Received';
  String get orderInKitchen => isArabic ? 'قيد التحضير في المطبخ' : 'In Kitchen';
  String get orderOnTheWay => isArabic ? 'في الطريق إليك' : 'Out for Delivery';
  String get orderDelivered => isArabic ? 'تم التسليم بنجاح' : 'Delivered';

  // ── Table Management (Waiter POS) ──────────────────────────────────────────
  String get tablesTitle => isArabic ? 'طاولات الصالة و POS' : 'Dine-In Tables & POS';
  String get tableNumber => isArabic ? 'طاولة رقم' : 'Table #';
  String get seatsCount => isArabic ? 'مقاعد' : 'Seats';
  String get tableStatusAvailable => isArabic ? 'متاحة' : 'Available';
  String get tableStatusOccupied => isArabic ? 'مشغولة' : 'Occupied';
  String get tableStatusReserved => isArabic ? 'محجوزة' : 'Reserved';
  String get tableStatusCleaning => isArabic ? 'تحتاج تنظيف' : 'Needs Cleaning';
  String get takeOrder => isArabic ? 'أخذ طلب جديد' : 'Take Order';
  String get activeTableOrder => isArabic ? 'الطلب النشط على الطاولة' : 'Active Order on Table';
  String get noActiveTableOrder => isArabic ? 'لا يوجد طلب نشط حالياً' : 'No active order on table';
  String get tableDetailTitle => isArabic ? 'تفاصيل الطاولة' : 'Table Details';
  String get tableServiceCalls => isArabic ? 'نداءات مساعدة من الطاولات' : 'Table Service Calls';
  String get tableCallWaiter => isArabic ? 'استدعاء كابتن الصالة' : 'Call Waiter';
  String get tableCallWater => isArabic ? 'طلب ماء' : 'Request Water';
  String get tableCallBill => isArabic ? 'طلب الفاتورة والحساب' : 'Request Bill';
  String get releaseTable => isArabic ? 'إفراغ وتسليم الطاولة' : 'Release Table';
  String get moveTable => isArabic ? 'نقل إلى طاولة أخرى' : 'Move Table';
  String get sendToKitchen => isArabic ? 'إرسال الطلب للمطبخ' : 'Send to Kitchen';
  String get sentToKitchenSuccess => isArabic ? 'تم إرسال الطلب للمطبخ فوراً' : 'Order sent to kitchen';
  String get addOrderToTable => isArabic ? 'إضافة طلب للطاولة' : 'Add Order to Table';

  // ── Kitchen Display System (KDS) ───────────────────────────────────────────
  String get kdsTitle => isArabic ? 'شاشة المطبخ' : 'Kitchen Display';
  String get kdsPending => isArabic ? 'بانتظار التحضير' : 'Pending';
  String get kdsPreparing => isArabic ? 'قيد التحضير' : 'Preparing';
  String get kdsReady => isArabic ? 'جاهز للتقديم' : 'Ready to Serve';
  String get kdsServed => isArabic ? 'تم التقديم' : 'Served';
  String get kdsCompleted => isArabic ? 'مكتمل' : 'Completed';
  String get kdsClaimOrder => isArabic ? 'استلام وبدء التحضير' : 'Claim & Start Cooking';
  String get kdsElapsed => isArabic ? 'الوقت المنقضي' : 'Elapsed Time';
  String get kdsDelayedAlert => isArabic ? 'تأخير في التحضير' : 'Delayed Order Alert';
  String get printKitchenTicket => isArabic ? 'طباعة تذكرة المطبخ' : 'Print Kitchen Ticket';

  // ── Delivery & Driver App ──────────────────────────────────────────────────
  String get driverDashboardTitle => isArabic ? 'تطبيـق الكابتن ومندوب التوصيل' : 'Driver Delivery Hub';
  String get availableDeliveries => isArabic ? 'طلبات متاحة للتوصيل' : 'Available Deliveries';
  String get activeDelivery => isArabic ? 'الطلب المكلف به حالياً' : 'Current Active Delivery';
  String get acceptDelivery => isArabic ? 'قبول المهمة بكل سرور' : 'Gladly Accept';
  String get pickupFromRestaurant => isArabic ? 'استلام الطلب من المطعم' : 'Pickup from Restaurant';
  String get startDeliveryRoute => isArabic ? 'انطلقت في الطريق' : 'On My Way';
  String get markDelivered => isArabic ? 'تم التسليم بنجاح' : 'Delivered Successfully';
  String get callCustomer => isArabic ? 'اتصال بالعميل' : 'Call Customer';
  String get chatWithCustomer => isArabic ? 'محادثة مع العميل' : 'Chat with Customer';

  // ── Invoices, Reports, Inventory & Users ───────────────────────────────────
  String get invoicesTitle => isArabic ? 'الفواتير وسندات التحصيل' : 'Invoices & Billing';
  String get noInvoicesFound => isArabic ? 'لا توجد فواتير لتصديرها' : 'No invoices found';
  String get exportCsv => isArabic ? 'تصدير CSV' : 'Export CSV';
  String get exportCsvSuccess => isArabic ? 'تم تصدير الفواتير بنجاح' : 'Invoices exported successfully';
  String get printReceipt => isArabic ? 'طباعة الفاتورة' : 'Print Receipt';
  String get receiptSentToPrinter => isArabic ? 'تم إرسال الفاتورة للطابعة الحرارية' : 'Receipt sent to thermal printer';
  String get vatAmount => isArabic ? 'ضريبة القيمة المضافة' : 'VAT Amount';
  String get taxInvoice => isArabic ? 'فاتورة ضريبية مبسطة' : 'Simplified Tax Invoice';
  String get taxNumberLabel => isArabic ? 'الرقم الضريبي' : 'Tax / VAT Number';
  String get financialReportsTitle => isArabic ? 'التقارير المالية والأرباح' : 'Financial Reports & P&L';
  String get grossRevenue => isArabic ? 'إجمالي المبيعات' : 'Gross Revenue';
  String get netProfit => isArabic ? 'صافي الربح' : 'Net Profit';
  String get totalDiscounts => isArabic ? 'إجمالي الخصومات' : 'Total Discounts';
  String get totalTaxCollected => isArabic ? 'إجمالي الضرائب المحصلة' : 'Total Tax Collected';
  String get profitMargin => isArabic ? 'هامش الربح' : 'Profit Margin';
  String get inventoryTitle => isArabic ? 'المخزون والمستودع' : 'Inventory Management';
  String get inventoryStock => isArabic ? 'الكمية المتوفرة' : 'Stock Quantity';
  String get inventoryMinThreshold => isArabic ? 'الحد الأدنى للتنبيه' : 'Min Threshold';
  String get inventoryUnitCost => isArabic ? 'تكلفة الوحدة' : 'Unit Cost';
  String get lowStockAlert => isArabic ? 'تنبيه نقص في المخزون' : 'Low Stock Alert';
  String get addInventoryItem => isArabic ? 'إضافة صنف مخزون' : 'Add Inventory Item';
  String get editInventoryItem => isArabic ? 'تعديل بيانات المخزون' : 'Edit Inventory Item';
  String get staffTitle => isArabic ? 'أداء وإنتاجية الموظفين' : 'Staff Performance';
  String get staffPerformanceTitle => isArabic ? 'تقييم كفاءة طاقم العمل' : 'Staff KPI & Performance';
  String get staffRating => isArabic ? 'التقييم' : 'Rating';
  String get couponsTitle => isArabic ? 'إدارة الكوبونات والخصومات' : 'Coupons & Discounts';
  String get addCoupon => isArabic ? 'إضافة كوبون جديد' : 'Add New Coupon';
  String get qrGeneratorTitle => isArabic ? 'توليد رموز QR للطاولات' : 'Table QR Code Generator';
  String get generateQr => isArabic ? 'إنشاء رمز QR' : 'Generate QR';
  String get downloadQr => isArabic ? 'تحميل الرمز' : 'Download QR';
  String get userManagementTitle => isArabic ? 'إدارة المستخدمين والصلاحيات' : 'User Management & RBAC';
  String get addUser => isArabic ? 'إضافة مستخدم جديد' : 'Add New User';
  String get editUser => isArabic ? 'تعديل المستخدم' : 'Edit User';
  String get deleteUser => isArabic ? 'حذف المستخدم' : 'Delete User';
  String get loyaltyTitle => isArabic ? 'برنامج ولاء ومكافآت العملاء' : 'Loyalty & Rewards';
  String get notificationsTitle => isArabic ? 'الإشعارات والتنبيهات' : 'Notifications & Alerts';
  String get noNotifications => isArabic ? 'لا توجد إشعارات جديدة حالياً' : 'No new notifications';
  String get privacyPolicyTitle => isArabic ? 'سياسة الخصوصية' : 'Privacy Policy';
  String get termsTitle => isArabic ? 'الشروط والأحكام' : 'Terms & Conditions';

  // ── Common Navigation & Sections ───────────────────────────────────────────
  String get menu => isArabic ? 'القائمة' : 'Menu';
  String get cart => isArabic ? 'السلة' : 'Cart';
  String get orders => isArabic ? 'الطلبات' : 'Orders';
  String get tables => isArabic ? 'الطاولات' : 'Tables';
  String get reservations => isArabic ? 'الحجوزات' : 'Reservations';
  String get discounts => isArabic ? 'الخصومات' : 'Discounts';
  String get coupons => isArabic ? 'الكوبونات' : 'Coupons';
  String get inventory => isArabic ? 'المخزون' : 'Inventory';
  String get staff => isArabic ? 'الموظفون' : 'Staff';
  String get users => isArabic ? 'المستخدمون' : 'Users';
  String get invoices => isArabic ? 'الفواتير' : 'Invoices';
  String get financialReports => isArabic ? 'الأرباح و P&L' : 'P&L Reports';
  String get shifts => isArabic ? 'الورديات Z-Report' : 'Shifts Z-Report';
  String get qrCodes => isArabic ? 'رموز QR' : 'QR Codes';
  String get kds => isArabic ? 'المطبخ' : 'Kitchen KDS';
  String get deliverySection => isArabic ? 'التوصيل' : 'Delivery';
  String get manager => isArabic ? 'المدير' : 'Manager';
  String get loyalty => isArabic ? 'برنامج الولاء' : 'Loyalty Rewards';
  String get settings => isArabic ? 'الإعدادات' : 'Settings';

  // ── Common Actions & Statuses ──────────────────────────────────────────────
  String get save => isArabic ? 'حفظ' : 'Save';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get delete => isArabic ? 'حذف' : 'Delete';
  String get edit => isArabic ? 'تعديل' : 'Edit';
  String get add => isArabic ? 'إضافة' : 'Add';
  String get apply => isArabic ? 'تطبيق' : 'Apply';
  String get confirm => isArabic ? 'تأكيد' : 'Confirm';
  String get clear => isArabic ? 'إفراغ' : 'Clear';
  String get search => isArabic ? 'بحث...' : 'Search...';
  String get close => isArabic ? 'إغلاق' : 'Close';
  String get back => isArabic ? 'رجوع' : 'Back';
  String get ok => isArabic ? 'حسناً' : 'OK';
  String get done => isArabic ? 'تم' : 'Done';
  String get retry => isArabic ? 'إعادة المحاولة' : 'Retry';
  String get loading => isArabic ? 'جاري التحميل...' : 'Loading...';
  String get errorOccurred => isArabic ? 'حدث خطأ غير متوقع' : 'An error occurred';
  String get areYouSure => isArabic ? 'هل أنت متأكد؟' : 'Are you sure?';
  String get deleteConfirmation => isArabic ? 'لا يمكن التراجع عن هذا الإجراء بعد الحذف.' : 'This action cannot be undone.';
  String get notFoundTitle => isArabic ? 'الصفحة غير موجودة' : 'Page Not Found';
  String get notFoundAction => isArabic ? 'العودة للرئيسية' : 'Return to Home';

  // ── App Identity & Fallbacks ───────────────────────────────────────────────
  String get appName => isArabic ? 'مطعم ليالي المحروسة' : 'Layali Al Mahrousa Restaurant';
  String get appTagline => isArabic ? 'أشهى المأكولات والمشويات المصرية الأصيلة' : 'Authentic Egyptian Grills & Cuisine';
  String get fallbackBranchLabel => isArabic ? 'الفرع' : 'Branch';
  String get fallbackCashierName => isArabic ? 'كاشير الصالة' : 'Cashier';
  String get fallbackMainBranch => isArabic ? 'الفرع الرئيسي' : 'Main Branch';
  String get defaultCashierShortName => isArabic ? 'الكاشير' : 'Cashier';
  String get notAssigned => isArabic ? 'غير محدد' : 'Not Assigned';
  String get roleManagerChef => isArabic ? 'رئيس الطهاة' : 'Manager Chef';

  // ── Add Branch Dialog ──────────────────────────────────────────────────────
  String get addBranchDialogTitle => isArabic ? 'إضافة فرع جديد للسلسلة' : 'Add New Branch to Chain';
  String get addBranchDialogSubtitle => isArabic ? 'سجل بيانات الفرع الجديد وتفاصيل التشغيل' : 'Enter new branch profile and operations';
  String get branchNameHint => isArabic ? 'مثال: فرع مدينة نصر' : 'e.g. Downtown Branch';
  String get branchNameRequired => isArabic ? 'يرجى إدخال اسم الفرع' : 'Please enter branch name';
  String get cityLabel => isArabic ? 'المدينة *' : 'City *';
  String get cityRequired => isArabic ? 'يرجى إدخال المدينة' : 'Please enter city';
  String get branchAddressHint => isArabic ? 'الشارع، المنطقة، أقرب علامة مميزة' : 'Street, district, landmark';
  String get branchAddressRequired => isArabic ? 'يرجى إدخال عنوان الفرع' : 'Please enter branch address';
  String get branchAccentColor => isArabic ? 'اللون المميز للفرع في اللوحة:' : 'Branch Accent Color:';
  String get addBranchTooltip => isArabic ? 'إضافة فرع جديد' : 'Add new branch';

  // ── Manager Dynamic Messages ───────────────────────────────────────────────
  String allBranchesCount(int count) => isArabic ? 'إدارة كل الفروع ($count)' : 'All Branches ($count)';
  String managingBranch(String name) => isArabic ? 'متابعة $name' : 'Managing $name';
  String activeOrdersInBranchMessage(int count) => isArabic
      ? 'لديك $count طلبات جارية الآن في هذا الفرع'
      : 'You have $count active orders in this branch';

  // ── Weekdays ───────────────────────────────────────────────────────────────
  String get weekdaySat => isArabic ? 'السبت' : 'Sat';
  String get weekdaySun => isArabic ? 'الأحد' : 'Sun';
  String get weekdayMon => isArabic ? 'الإثنين' : 'Mon';
  String get weekdayTue => isArabic ? 'الثلاثاء' : 'Tue';
  String get weekdayWed => isArabic ? 'الأربعاء' : 'Wed';
  String get weekdayThu => isArabic ? 'الخميس' : 'Thu';
  String get weekdayFri => isArabic ? 'الجمعة' : 'Fri';

  // ── Owner & New Screens ────────────────────────────────────────────────────
  String get ownerDigest => isArabic ? 'تقرير المالك 🌟' : 'Owner Digest 🌟';
  String get menuMatrix => isArabic ? 'هندسة المنيو' : 'Menu Matrix';
  String get recipesAndBom => isArabic ? 'الوصفات والتكلفة' : 'Recipes & BOM';
  String get wasteLogsTitle => isArabic ? 'سجل الهالك' : 'Waste Logs';
  String get staffTimesheetTitle => isArabic ? 'ساعات الموظفين والأجور' : 'Staff Timesheet';
  String get purchaseOrdersTitle => isArabic ? 'أوامر الشراء والموردين' : 'Purchase Orders';
  String get securityAuditTitle => isArabic ? 'سجل التدقيق الأمني' : 'Security Audit';
  String get guestFeedbackTitle => isArabic ? 'تقييمات وشكاوى العملاء' : 'Guest Feedback';
  String get salesTargetTitle => isArabic ? 'تارجت المبيعات والسرعة' : 'Sales Target';

  // ── Navigation Targets ─────────────────────────────────────────────────────
  String get navKds => isArabic ? 'شاشة المطبخ' : 'Kitchen Screen';
  String get navWaiterPos => isArabic ? 'شاشة الصالة ونقطة البيع' : 'Hall & POS Screen';
  String get navDriver => isArabic ? 'شاشة السائق والتوصيل' : 'Driver & Delivery Screen';
  String get alertsCenter => isArabic ? 'مركز التنبيهات' : 'Alerts Center';
  String get manageMenuTooltip => isArabic ? 'إدارة وتعديل قائمة الطعام' : 'Manage & edit food menu';

  // ── Cashier POS Hub ────────────────────────────────────────────────────────
  String get posQuickOperations => isArabic ? 'العمليات السريعة ونقطة البيع' : 'POS Quick Operations';
  String get fastPosTitle => isArabic ? 'نقطة البيع السريعة' : 'Fast POS Counter';
  String get fastPosSubtitle => isArabic ? 'محاسبة التيك أواي وحاسبة الباقي' : 'Quick Takeaway & Tender';
  String get pettyCashTitle => isArabic ? 'حركات الدرج والمصروفات' : 'Petty Cash & In/Out';
  String get pettyCashSubtitle => isArabic ? 'تسجيل سحب أو إيداع نقدية' : 'Record Pay-In / Pay-Out';
  String get heldOrdersTitle => isArabic ? 'الطلبات المعلقة' : 'Held / Parked Orders';
  String heldOrdersSubtitle(int count) => isArabic ? '$count طلبات معلقة بالانتظار' : '$count Parked Orders';
  String occupiedTablesSubtitle(int count) => isArabic ? '$count طاولة مشغولة' : '$count Occupied';
  String invoicesCountSubtitle(int count) => isArabic ? '$count فاتورة مسجلة' : '$count Invoices';
  String pastShiftsSubtitle(int count) => isArabic ? '$count وردية مقفلة' : '$count Past Shifts';
  String get shiftsHistoryTitle => isArabic ? 'سجل الورديات و Z-Report' : 'Shifts & Z-Reports';
  String get refundInvoice => isArabic ? 'استرجاع الفاتورة' : 'Refund Invoice';
  String get paidOrdersSuffix => isArabic ? 'طلب' : 'Orders';
  String dineInOrderNumber(String id) => isArabic ? 'طلب صالة #$id' : 'Dine-In Order #$id';
  String customerOrderNumber(String id) => isArabic ? 'طلب #$id' : 'Order #$id';
  String receiptSentWithOrderId(String id) => isArabic ? 'تم إرسال إيصال الطلب #$id للطابعة' : 'Order receipt #$id sent to printer';

  // ── Language & Theme ───────────────────────────────────────────────────────
  String get switchedToEnglish => isArabic ? 'Switched to English 🇺🇸' : 'Switched to English 🇺🇸';
  String get switchedToArabic => isArabic ? 'تم التحويل إلى العربية 🇸🇦' : 'تم التحويل إلى العربية 🇸🇦';
  String get languageToggleToEnglish => isArabic ? 'EN' : 'EN';
  String get languageToggleToArabic => isArabic ? 'عربي' : 'عربي';
  String get languageToggleLongToEnglish => isArabic ? 'English (EN)' : 'English (EN)';
  String get languageToggleLongToArabic => isArabic ? 'العربية (AR)' : 'العربية (AR)';
  String get switchToLight => isArabic ? 'التبديل إلى الوضع الفاتح' : 'Switch to Light';
  String get switchToDark => isArabic ? 'التبديل إلى الوضع الداكن' : 'Switch to Dark';

  // ── Units & Generic ────────────────────────────────────────────────────────
  String get sincePrefix => isArabic ? 'منذ' : 'ago';
  String get distanceLabel => isArabic ? 'المسافة' : 'Distance';
  String get unitKm => isArabic ? 'كم' : 'km';
  String get unitMeter => isArabic ? 'م' : 'm';
  String get statusLabel => isArabic ? 'الحالة' : 'Status';
  String get backToMenu => isArabic ? 'العودة إلى القائمة' : 'Back to Menu';
  String get requiredField => isArabic ? 'هذا الحقل مطلوب' : 'This field is required';

  // ── Payments ───────────────────────────────────────────────────────────────
  String get paymentMethodLabel => isArabic ? 'طريقة الدفع' : 'Payment Method';
  String get paymentCash => isArabic ? 'نقداً' : 'Cash';
  String get paymentCard => isArabic ? 'بطاقة' : 'Card';
  String get paymentWallet => isArabic ? 'محفظة رقمية' : 'Digital Wallet';
  String get paymentOnline => isArabic ? 'دفع أونلاين' : 'Online Payment';
  String get paymentMethodDisplayLabel => isArabic ? 'الدفع' : 'Payment';
  String get paymentUnknown => isArabic ? 'غير محدد' : 'Unknown';
  String get deliveryEtaLabel => isArabic ? 'الوقت المتوقع للوصول' : 'Estimated Arrival Time';
  String get deliveryLocationLabel => isArabic ? 'العنوان' : 'Address';
  String get customerPhoneLabel => isArabic ? 'رقم العميل' : 'Customer Phone';
  String get deliveryFeeLabel => isArabic ? 'رسوم التوصيل' : 'Delivery Fee';

  // ── KDS Extras ─────────────────────────────────────────────────────────────
  String get kdsNewBadge => isArabic ? 'جديد' : 'New';
  String get kdsEmptyColumn => isArabic ? 'المطبخ هادئ الآن — أحسنتم العمل' : 'Kitchen is calm now — great work';
  String get kdsCompleting => isArabic ? 'استكمال' : 'Completing';
  String get kdsRevertTooltip => isArabic ? 'التراجع عن الحالة' : 'Revert status';
  String get kdsRevertConfirmAction => isArabic ? 'تأكيد التراجع' : 'Confirm Revert';
  String revertToStatus(String status) => isArabic ? 'تراجع إلى $status؟' : 'Revert to $status?';
  String get confirmRevert => isArabic ? 'تأكيد التراجع' : 'Confirm Revert';

  // ── Metrics Extras ─────────────────────────────────────────────────────────
  String get metricsByCategory => isArabic ? 'الإيرادات حسب الفئة' : 'Revenue by Category';
  String get metricsByPayment => isArabic ? 'الإيرادات حسب طريقة الدفع' : 'Revenue by Payment Method';
  String get metricsOrdersByStatus => isArabic ? 'الطلبات حسب الحالة' : 'Orders by Status';
  String get metricsOverview => isArabic ? 'نظرة عامة' : 'Overview';
  String get metricsItemsSold => isArabic ? 'الأصناف الأكثر مبيعاً' : 'Top Selling Items';
  String get metricsNoData => isArabic ? 'لا توجد بيانات بعد اليوم — أول طلب سيبدأ من هنا' : 'No sales yet today — your first order starts here';

  // ── Waiter ─────────────────────────────────────────────────────────────────
  String get waiterOrdersSummary => isArabic ? 'الطلبات النشطة' : 'Active Orders';
  String get waiterPendingCount => isArabic ? 'قيد الانتظار' : 'Pending';
  String get waiterPreparingCount => isArabic ? 'قيد التحضير' : 'Preparing';
  String get waiterReadyCount => isArabic ? 'جاهزة للتسليم' : 'Ready for Pickup';
  String get waiterReadyForPickupBadge => isArabic ? 'جاهز للاستلام' : 'Ready for Pickup';
  String get waiterPickupAlertMessage => isArabic ? 'طلب جاهز للاستلام من المطبخ' : 'Order ready for pickup from kitchen';

  // ── Tables Extras ──────────────────────────────────────────────────────────
  String get addMoreItems => isArabic ? 'إضافة أصناف إضافية للطلب' : 'Add more items to order';
  String get splitBill => isArabic ? 'تقسيم الشيك (Split Bill)' : 'Split Bill';
  String get orderTablePrefix => isArabic ? 'طاولة' : 'Table';
  String get orderMoveTo => isArabic ? 'نقل إلى:' : 'Move to:';
  String get tableActionReserve => isArabic ? 'حجز' : 'Reserve';

  // ── Discounts Page ─────────────────────────────────────────────────────────
  String get discountsPageTitle => isArabic ? 'الخصومات والعروض' : 'Discounts & Offers';
  String get newDiscount => isArabic ? 'خصم جديد' : 'New Discount';
  String get noDiscountsYet => isArabic ? 'لا توجد خصومات بعد' : 'No discounts yet';
  String get addDiscountTitle => isArabic ? 'إضافة خصم جديد' : 'Add New Discount';
  String get discountPercent => isArabic ? 'نسبة مئوية' : 'Percentage';
  String get discountFixed => isArabic ? 'مبلغ ثابت' : 'Fixed Amount';
  String get discountCouponType => isArabic ? 'كوبون' : 'Coupon';

  // ── Inventory Page ─────────────────────────────────────────────────────────
  String get inventoryManagementTitle => isArabic ? 'إدارة المخزون والتوريد' : 'Inventory & Supply Management';
  String get exportInventoryCsv => isArabic ? 'تصدير تقرير المخزون CSV' : 'Export inventory CSV report';
  String get noInventoryToExport => isArabic ? 'لا توجد عناصر في المخزون لتصديرها' : 'No inventory items to export';
  String inventoryExportedSuccess(int count) => isArabic ? 'تم تصدير تقرير $count صنف بنجاح!' : 'Exported $count items successfully!';
  String get filterByStatus => isArabic ? 'تصفية حسب الحالة' : 'Filter by status';
  String get addNewInventoryItem => isArabic ? 'إضافة صنف جديد' : 'Add New Item';
  String get addNewInventoryItemTitle => isArabic ? 'إضافة صنف مخزون جديد' : 'Add New Inventory Item';
  String get fillRequiredFields => isArabic ? 'يرجى ملء جميع الحقول المطلوبة' : 'Please fill all required fields';
  String restockTitle(String name) => isArabic ? 'إعادة تخزين: $name' : 'Restock: $name';
  String currentQuantity(String qty, String unit) => isArabic ? 'الكمية الحالية: $qty $unit' : 'Current quantity: $qty $unit';
  String get confirmRestock => isArabic ? 'تأكيد الإضافة' : 'Confirm Restock';
  String editItemTitle(String name) => isArabic ? 'تعديل: $name' : 'Edit: $name';
  String get itemUpdatedSuccess => isArabic ? 'تم تحديث بيانات الصنف بنجاح' : 'Item updated successfully';
  String get saveChanges => isArabic ? 'حفظ التعديلات' : 'Save Changes';
  String get deleteInventoryItemTitle => isArabic ? 'حذف الصنف من المخزون' : 'Delete Inventory Item';
  String deleteItemConfirm(String name) => isArabic ? 'هل أنت متأكد من رغبتك في حذف "$name" نهائياً؟' : 'Are you sure you want to delete "$name" permanently?';
  String itemDeletedSuccess(String name) => isArabic ? 'تم حذف "$name"' : 'Deleted "$name"';
  String get editItemAction => isArabic ? 'تعديل الصنف' : 'Edit Item';
  String get restockAction => isArabic ? 'إعادة التخزين' : 'Restock';

  // ── Orders Extras ──────────────────────────────────────────────────────────
  String get cartEmptySend => isArabic ? 'أضف أصنافاً أولاً' : 'Add items first';
  String get reorderSkipped => isArabic ? 'تم تخطي' : 'Skipped';
  String get orderAuditTrailTitle => isArabic ? 'سجل الحالة' : 'Status History';
  String get orderAuditTrailEmpty => isArabic ? 'لا يوجد سجل لهذا الطلب بعد — سيظهر هنا فور تحديثه' : 'No history yet — it will appear here once updated';
  String get orderAuditTrailReasonPrefix => isArabic ? 'السبب:' : 'Reason:';
  String get orderAuditTrailActorPrefix => isArabic ? 'بواسطة:' : 'By:';
  String get orderAuditTrailRevertBadge => isArabic ? 'تراجع' : 'Reverted';
  String get orderAuditTrailLoadFailed => isArabic ? 'تعذّر تحميل سجل الحالة — حاول مجدداً' : 'Could not load history — please try again';

  // ── Dispatch Health ────────────────────────────────────────────────────────
  String get dispatchHealthLoading => isArabic ? 'جارٍ تحميل حالة التوصيل…' : 'Loading dispatch status…';
  String get dispatchHealthUnavailable => isArabic ? 'تعذّر تحميل حالة التوصيل — تحقق من الاتصال وحاول مجدداً' : 'Could not load dispatch status — check connection and retry';

  // ── Driver / Delivery ──────────────────────────────────────────────────────
  String get driverTitle => isArabic ? 'شاشة السائق' : 'Driver Screen';
  String get deliveryPending => isArabic ? 'بانتظار التوكيل' : 'Pending Assignment';
  String get deliveryAccepted => isArabic ? 'مقبول' : 'Accepted';
  String get deliveryInTransit => isArabic ? 'قيد التوصيل للعميل' : 'On the Way to Customer';
  String get deliveryDelivered => isArabic ? 'تم التوصيل بنجاح' : 'Delivered Successfully';
  String get deliveryFailed => isArabic ? 'فشل التسليم' : 'Delivery Failed';
  String get deliveryPickedUp => isArabic ? 'استلمها المندوب من المطبخ' : 'Picked Up from Kitchen';
  String get actionAccept => isArabic ? 'قبول التوصيل' : 'Accept Delivery';
  String get actionStartDelivery => isArabic ? 'بدء التوصيل' : 'Start Delivery';
  String get actionCompleteDelivery => isArabic ? 'تسليم الطلب' : 'Complete Delivery';
  String get noDeliveryJobs => isArabic ? 'لا توجد مهام حالياً — استرح قليلاً، والجديد سيصلك فور توفره' : 'No tasks right now — rest a little, new jobs will reach you soon';
  String get driverNewAssignmentAlert => isArabic ? 'مهمة توصيل جديدة' : 'New delivery assignment';
  String driverNewAssignmentOrderPrefix(String id) => isArabic ? 'طلب $id' : 'Order $id';
  String get unreadChatMessagesLabel => isArabic ? 'رسائل غير مقروءة' : 'Unread messages';
  String get unknownDriverName => isArabic ? 'سائق غير معروف' : 'Unknown driver';
  String get rateDriverAction => isArabic ? 'قيّم السائق' : 'Rate Driver';
  String get rateDriverDialogTitle => isArabic ? 'تقييم السائق' : 'Rate Driver';
  String get rateDriverDialogSubtitle => isArabic ? 'ما رأيك في خدمة التوصيل؟' : 'How was the delivery service?';

  // ── Auth Extras ────────────────────────────────────────────────────────────
  String get logoutMessage => isArabic ? 'تم تسجيل الخروج بنجاح' : 'Logged out successfully';

  // ── Validation & Errors ────────────────────────────────────────────────────
  String get errorConnection => isArabic ? 'خطأ في الاتصال' : 'Connection error';
  String get errorServer => isArabic ? 'حدث خطأ في الخادم' : 'Server error occurred';
  String get errorGeneric => isArabic ? 'حدث خطأ غير متوقع' : 'An unexpected error occurred';
  String get errorInvalidCredentials => isArabic ? 'بيانات الدخول غير صحيحة' : 'Invalid login credentials';
  String get errorSessionExpired => isArabic ? 'انتهت الجلسة، سجّل الدخول مرة أخرى' : 'Session expired, please sign in again';
  String get errorCartEmpty => isArabic ? 'العربة فارغة' : 'Cart is empty';
  String get errorNoNetwork => isArabic ? 'لا يوجد اتصال بالإنترنت' : 'No internet connection';
  String get errorCache => isArabic ? 'تعذر حفظ البيانات محلياً' : 'Failed to save data locally';
  String get errorDemoUnavailable => isArabic ? 'غير متاح في وضع العرض' : 'Not available in demo mode';
  String get errorInvalidToken => isArabic ? 'رمز غير صالح' : 'Invalid token';
  String get errorInvalidResponse => isArabic ? 'استجابة غير صالحة' : 'Invalid response';
  String get errorLoadingData => isArabic ? 'تعذر تحميل البيانات' : 'Failed to load data';
  String errorWithDetail(Object err) => isArabic ? 'خطأ: $err' : 'Error: $err';

  // ── Misc Pages ─────────────────────────────────────────────────────────────
  String get qrTableTitle => isArabic ? 'رموز QR الطاولات' : 'Table QR Codes';
  String get printAll => isArabic ? 'طباعة الكل' : 'Print All';
  String get preparingPrint => isArabic ? 'جاري تجهيز الطباعة...' : 'Preparing print...';
  String get noTablesAddedYet => isArabic ? 'لا توجد طاولات مضافة بعد' : 'No tables added yet';
  String tableIdCopied(String id) => isArabic ? 'تم نسخ ID الطاولة: $id' : 'Table ID copied: $id';
  String get financialReportsPageTitle => isArabic ? 'التقارير المالية والأرباح (P&L)' : 'Financial Reports & Profits (P&L)';
  String get exportFinancialCsv => isArabic ? 'تصدير تقرير مالي CSV' : 'Export financial CSV report';
  String get refreshData => isArabic ? 'تحديث البيانات' : 'Refresh data';
  String get noSalesInPeriod => isArabic ? 'لا توجد بيانات مبيعات في هذه الفترة' : 'No sales data in this period';
  String get dispatchBoardTitle => isArabic ? 'لوحة التوصيل' : 'Dispatch Board';
  String get refreshAction => isArabic ? 'تحديث' : 'Refresh';
  String get noDriversAvailable => isArabic ? 'لا يوجد سائقون متاحون حالياً' : 'No drivers available right now';
  String activeAssignmentsCount(int count) => isArabic ? '$count نشطة' : '$count active';
  String get assignDriverAction => isArabic ? 'تعيين سواق' : 'Assign Driver';
  String get markAllRead => isArabic ? 'تحديد الكل كمقروء' : 'Mark all as read';
  String get dismissAction => isArabic ? 'تجاهل' : 'Dismiss';
  String get copyOwnerReport => isArabic ? 'تم نسخ التقرير للمالك' : 'Owner report copied';
  String get shiftOpenedSuccess => isArabic ? 'تم فتح الوردية وتعيين العهدة النقدية بنجاح! 🟢' : 'Shift opened and cash float set! 🟢';
  String get openShiftNow => isArabic ? 'فتح الوردية الآن' : 'Open Shift Now';
  String get confirmCloseShift => isArabic ? 'تأكيد الإقفال وسحب Z-Report' : 'Confirm Close & Pull Z-Report';
  String get zReportSentToPrinter => isArabic ? 'تم إرسال تقرير Z-Report إلى الطابعة الحرارية 🖨️' : 'Z-Report sent to thermal printer 🖨️';
  String get printReceiptAction => isArabic ? 'طباعة الإيصال' : 'Print Receipt';
  String get printAction => isArabic ? 'طباعة' : 'Print';
  String get receiptReprintedSuccess => isArabic ? 'تمت إعادة طباعة الإيصال بنجاح 🖨️' : 'Receipt reprinted successfully 🖨️';
  String get showAllAction => isArabic ? 'عرض الكل' : 'Show All';

  // ── Shift Dialogs ──────────────────────────────────────────────────────────
  String get openingFloatRow => isArabic ? 'العهدة الافتتاحية:' : 'Opening Float:';
  String get cashSalesRow => isArabic ? 'المبيعات النقدية (كاش):' : 'Cash sales:';
  String get cardSalesRow => isArabic ? 'مبيعات مدى / بطاقات:' : 'Card sales:';
  String get walletSalesRow => isArabic ? 'مبيعات المحافظ الإلكترونية:' : 'Wallet sales:';
  String cashSurplusWithAmount(String amount) => isArabic ? 'يوجد فائض بالدرج بمقدار: +$amount' : 'Cash surplus: +$amount';
  String cashDeficitWithAmount(String amount) => isArabic ? 'يوجد عجز بالدرج بمقدار: $amount' : 'Cash deficit: $amount';
  String get additionalNotes => isArabic ? 'ملاحظات إضافية (اختياري):' : 'Additional notes (optional):';
  String get shiftNotesHint => isArabic ? 'أي ملاحظات خاصة بالوردية أو المصروفات النثرية...' : 'Any shift or petty-cash notes...';
  String get closeAndPrintZReport => isArabic ? 'إقفال وطباعة Z-Report' : 'Close & Print Z-Report';
  String get shiftResponsibleLabel => isArabic ? 'المسؤول عن الوردية' : 'Shift Cashier';
  String shiftInfoLine(String id, String cashier) => isArabic ? 'رقم الوردية: #$id • مسؤول الكاشير: $cashier' : 'Shift #$id • Cashier: $cashier';
  String get noReceiptsHint => isArabic ? 'عند إتمام وتحصيل أي طلب سيظهر هنا مع إمكانية طباعة الإيصال فوراً' : 'Receipts will appear here as soon as orders are paid';
  String get menuManagementCardTitle => isArabic ? 'إدارة وتعديل قائمة الطعام (Menu Management)' : 'Menu Management';
  String get menuManagementCardSubtitle => isArabic ? 'إضافة أصناف جديدة، تعديل الأسعار، المكونات، وتوافر الوجبات بالمطعم' : 'Add items, edit prices, ingredients & meal availability';
  String get stockSufficient => isArabic ? 'كافٍ' : 'Sufficient';
  String get stockLow => isArabic ? 'منخفض' : 'Low';
  String get stockOutOfStock => isArabic ? 'منتهي' : 'Out of Stock';
  String get tableTransferAction => isArabic ? 'نقل / دمج الطاولة' : 'Transfer / Merge Table';
  String exceptionalDiscountLabel(String symbol) => isArabic ? 'خصم استثنائي ($symbol) - اختياري' : 'Exceptional discount ($symbol) - optional';
  String get paymentCashChip => isArabic ? 'نقدي (Cash)' : 'Cash';
  String get paymentCardChip => isArabic ? 'بطاقة / شبكة (Card)' : 'Card';
  String get paymentWalletChip => isArabic ? 'محفظة (Wallet)' : 'Wallet';
  String get splitCashOption => isArabic ? '💵 كاش' : '💵 Cash';
  String get splitCardOption => isArabic ? '💳 بطاقة / فيزا' : '💳 Card / Visa';
  String get sharePaid => isArabic ? 'تم الدفع ✅' : 'Paid ✅';
  String get payShare => isArabic ? 'سداد الحصة' : 'Pay Share';
  String get discountNameLabel => isArabic ? 'اسم الخصم' : 'Discount Name';
  String get discountTypeLabel => isArabic ? 'نوع الخصم' : 'Discount Type';
  String get discountValuePercent => isArabic ? 'النسبة (%)' : 'Percentage (%)';
  String get discountValueAmount => isArabic ? 'المبلغ (ج.م)' : 'Amount (EGP)';
  String get discountNameRequired => isArabic ? 'الاسم مطلوب' : 'Name is required';
  String get discountValueRequired => isArabic ? 'القيمة مطلوبة' : 'Value is required';
  String get couponCodeRequired => isArabic ? 'الكود مطلوب' : 'Code is required';
  String get stationAll => isArabic ? 'الكل' : 'All';
  String get stationGrill => isArabic ? 'الشواية واللحوم' : 'Grill & Meats';
  String get stationBakery => isArabic ? 'الفرن والمخبوزات' : 'Oven & Bakery';
  String get stationBar => isArabic ? 'المشروبات والبار' : 'Drinks & Bar';
  String get stationExpo => isArabic ? 'شاشة التجميع (Expo)' : 'Expo Screen';
  String get handoverToDriver => isArabic ? 'تسليم للمندوب' : 'Hand to Driver';
  String get handedToDriver => isArabic ? 'تم التسليم للمندوب' : 'Handed to Driver';
  String get takeawayShort => isArabic ? 'سفري' : 'Takeaway';
  String get driverAssignedChip => isArabic ? 'المندوب معيّن 🛵' : 'Driver Assigned 🛵';
  String get assignDriverChip => isArabic ? 'تعيين مندوب' : 'Assign Driver';
  String get selectKitchenStation => isArabic ? 'اختيار محطة المطبخ' : 'Select kitchen station';
  String get recentCompletedOrdersTitle => isArabic ? 'الطلبات المسلّمة حديثاً' : 'Recently delivered orders';
  String stationTooltip(String station) => isArabic ? 'محطة: $station' : 'Station: $station';
  String itemCountLine(int count) => isArabic ? 'عدد الأصناف: $count' : 'Items: $count';
  String onTimeMinutes(int minutes) => isArabic ? 'في الوقت ($minutes د)' : 'On time (${minutes}m)';
  String warningMinutes(int minutes) => isArabic ? 'تنبيه ($minutes د)' : 'Warning (${minutes}m)';
  String lateMinutes(int minutes) => isArabic ? 'متأخر! ($minutes د)' : 'Late! (${minutes}m)';
  String recentDeliveredWithCount(int count) => isArabic ? 'الطلبات المسلّمة حديثاً ($count)' : 'Recently delivered orders ($count)';
  String get revertHint => isArabic ? 'إذا قمت بتسليم طلب بالخطأ، يمكنك إعادته للمطبخ بضغطة زر (الطلبات المغلقة نهائياً لا يمكن إرجاعها):' : 'If you delivered an order by mistake, send it back to the kitchen with one tap (final closed orders cannot be reverted):';
  String get noRecentDelivered => isArabic ? 'لا توجد طلبات مسلّمة مؤخراً' : 'No recently delivered orders';
  String orderWithType(String id, String type) => isArabic ? 'طلب #$id • $type' : 'Order #$id • $type';
  String itemsWithStatus(int count, String status) => isArabic ? '$count أصناف • الحالة: $status' : '$count items • Status: $status';
  String get backToKitchen => isArabic ? 'إعادة للمطبخ' : 'Back to Kitchen';
  String orderBackToReady(String id) => isArabic ? 'تمت إعادة الطلب #$id إلى قائمة "جاهز" بنجاح ✅' : 'Order #$id moved back to "Ready" ✅';
  String get orderFinalNoRevert => isArabic ? 'نهائي — لا يمكن الإرجاع' : 'Final — cannot revert';
  String orderRevertFailed(String id) => isArabic
      ? 'تعذّر إرجاع الطلب #$id — الطلب مغلق نهائياً أو تجاوز حد التراجع (مرتان)'
      : 'Could not revert order #$id — it is final or the revert limit (2) was reached';
  // ── Warm Human Copy (mirrors HumanCopy AR lines + EN) ────────────────────
  String get warmSearchHint => isArabic ? 'دوّر على كبسة، برجر، مشويات...؟' : 'Craving kabsa, burgers, grills...?';
  String get warmNoItemsTitle => isArabic ? 'لم نجد طبقاً مطابقاً' : 'No matching dish found';
  String get warmNoItemsSubtitle => isArabic ? 'جرّب كلمة مختلفة، أو امسح البحث وتصفح القائمة كاملة — أكيد ستجد ما يعجبك' : 'Try a different word, or clear the search and browse the full menu — you will find something you love';
  String get warmClearSearch => isArabic ? 'مسح البحث' : 'Clear Search';
  String get warmBrowseMenu => isArabic ? 'تصفح القائمة' : 'Browse Menu';
  String get warmAddedToCart => isArabic ? 'أضفناه إلى سلتك — بالهناء والشفاء' : 'Added to your cart — enjoy your meal';
  String get warmViewCart => isArabic ? 'عرض السلة' : 'View Cart';
  String get warmDineInWelcome => isArabic ? 'أهلاً بك على طاولتك! النادل معك، وطلبك بأيدٍ أمينة' : 'Welcome to your table! Your waiter is with you, and your order is in safe hands';
  String get warmDineInFollowing => isArabic ? 'طلبك قيد المتابعة في المطبخ' : 'Your order is being followed up in the kitchen';
  String get warmWaiterCalled => isArabic ? 'نادينا النادل إلى طاولتك — سيكون معك خلال لحظات' : 'We called the waiter to your table — they will be with you in moments';
  String get warmBillRequested => isArabic ? 'طلبنا الفاتورة من النادل — لحظات وتكون عندك' : 'We requested the bill from the waiter — it will be with you shortly';
  String get warmCartEmptyTitle => isArabic ? 'سلتك فارغة حالياً' : 'Your cart is empty right now';
  String get warmCartEmptySubtitle => isArabic ? 'ما رأيك بتصفح أطباقنا الشهية؟ وجبتك المفضلة بانتظارك' : 'How about browsing our delicious dishes? Your favorite meal is waiting';
  String get warmTableCallingTitle => isArabic ? 'تناديك بكل ود' : 'Is calling you warmly';
  String get warmImComing => isArabic ? 'أنا قادم إليها' : 'I am on my way there';
  String get warmCallAcknowledged => isArabic ? 'أحسنت! سجلنا أنك في الطريق إلى الطاولة' : 'Well done! We logged that you are on your way to the table';
  String get warmNoTablesTitle => isArabic ? 'لا توجد طاولات مطابقة' : 'No matching tables';
  String get warmNoTablesSubtitle => isArabic ? 'جرّب مسح الفلتر الحالي لعرض جميع الطاولات' : 'Try clearing the current filter to show all tables';
  String get warmClearFilter => isArabic ? 'مسح الفلتر' : 'Clear Filter';
  String get warmTableReleased => isArabic ? 'تم تجهيز الطاولة لاستقبال ضيوف جدد — شكراً لك' : 'Table is ready for new guests — thank you';
  String get warmTableReserved => isArabic ? 'تم حجز الطاولة بنجاح — أهلاً بضيوفنا' : 'Table reserved successfully — welcome to our guests';
  String get warmKitchenCalmTitle => isArabic ? 'المطبخ هادئ الآن' : 'Kitchen is calm now';
  String get warmKitchenCalmSubtitle => isArabic ? 'أحسنتم العمل! خذ نفساً عميقاً — الطلبات الجديدة ستظهر هنا فور وصولها' : 'Great work! Take a deep breath — new orders will appear here as soon as they arrive';
  String get warmStartCooking => isArabic ? 'بدأت تحضيرها' : 'Started preparing it';
  String get warmReadyToServe => isArabic ? 'أصبحت جاهزة للتقديم' : 'It is ready to serve';
  String get warmClaimed => isArabic ? 'أصبح الطلب بين يديك — بالتوفيق يا شيف' : 'The order is in your hands — good luck, chef';
  String get warmAdvanced => isArabic ? 'انتقل الطلب للمرحلة التالية — عمل رائع' : 'Order moved to the next stage — great work';
  String get warmAlertsReviewed => isArabic ? 'راجعت تنبيهات الطلبات الجديدة — يوم موفق' : 'You reviewed the new order alerts — have a great day';
  String get warmDelayedEmpathy => isArabic ? 'هذا الطلب تأخر قليلاً — شكراً لصبركم وإتقانكم' : 'This order is slightly delayed — thank you for your patience and care';
  String get warmGreetingMorning => isArabic ? 'صباح الخير! يوم جديد مليء بالفرص' : 'Good morning! A new day full of opportunities';
  String get warmGreetingEvening => isArabic ? 'مساء الخير! لنلقِ نظرة على يومك' : 'Good evening! Let us look at your day';
  String get warmNoSalesTitle => isArabic ? 'لا توجد مبيعات بعد اليوم' : 'No sales yet today';
  String get warmNoSalesSubtitle => isArabic ? 'أول طلب سيبدأ من هنا — الأمور طيبة وفريقك جاهز' : 'The first order will start here — all is well and your team is ready';
  String get warmBranchSwitched => isArabic ? 'انتقلنا إلى الفرع الجديد — بالتوفيق' : 'Switched to the new branch — good luck';
  String get warmNoJobsTitle => isArabic ? 'لا توجد مهام حالياً' : 'No jobs right now';
  String get warmNoJobsSubtitle => isArabic ? 'استرح قليلاً — المهمات الجديدة ستصلك فور توفرها' : 'Rest a little — new jobs will reach you as soon as they are available';
  String get warmDeliveredCelebration => isArabic ? 'تم التوصيل بنجاح! سُجّل المبلغ في محفظتك — شكراً لجهدك' : 'Delivered successfully! The amount is logged in your wallet — thank you for your effort';
  String get warmDeliveryFailed => isArabic ? 'لا تقلق — سجّلنا المحاولة وأبلغنا المطبخ، شكراً لحرصك' : 'Do not worry — we logged the attempt and notified the kitchen, thank you for your care';
  String get warmNewAssignment => isArabic ? 'مهمة توصيل جديدة بانتظارك — بالتوفيق في الطريق' : 'A new delivery job is waiting — good luck on the road';
  String get warmAccepted => isArabic ? 'قبلت المهمة — العميل بانتظارك بكل شوق' : 'You accepted the job — the customer is eagerly waiting';
  String get warmStarted => isArabic ? 'انطلقت في الطريق — درب السلامة' : 'You are on the way — safe travels';
  String get warmCopied => isArabic ? 'نسخناها لك — شكراً لصبرك' : 'Copied for you — thank you for your patience';
  String get warmMapsFallback => isArabic ? 'تعذّر فتح الخرائط — نسخنا لك رابط الاتجاهات' : 'Could not open maps — we copied the directions link for you';
  String get warmCallFallback => isArabic ? 'تعذّر فتح الاتصال — نسخنا لك الرقم' : 'Could not start the call — we copied the number for you';
  String get warmWhatsappFallback => isArabic ? 'تعذّر فتح واتساب — نسخنا لك الرسالة' : 'Could not open WhatsApp — we copied the message for you';
  String get warmLoading => isArabic ? 'لحظات ونجهز لك كل شيء' : 'A moment while we get everything ready';
  String get warmErrorTitle => isArabic ? 'حدث تعثر بسيط' : 'A small hiccup occurred';
  String get warmErrorSubtitle => isArabic ? 'تحقق من الاتصال وحاول مجدداً — نحن معك خطوة بخطوة' : 'Check your connection and try again — we are with you step by step';
  String get warmRetry => isArabic ? 'لنحاول مجدداً' : 'Let us try again';
  String get warmOrderBackToKitchen => isArabic ? 'أعدنا الطلب إلى المطبخ — لا عليك' : 'We sent the order back to the kitchen — no worries';
  String get checkoutAndRelease => isArabic ? 'محاسبة وإخلاء الطاولة (Checkout)' : 'Checkout & Release Table';
  String tableCleanedMessage(int tableNumber) => isArabic ? 'تم تنظيف طاولة $tableNumber وأصبحت متاحة للزبائن' : 'Table $tableNumber cleaned and ready for guests';
  String get confirmTableClean => isArabic ? 'تأكيد نظافة الطاولة وجاهزيتها' : 'Confirm Table Cleaned & Ready';
  String get cancelReservation => isArabic ? 'إلغاء الحجز' : 'Cancel Reservation';
  String checkoutTableTitle(int tableNumber) => isArabic ? 'محاسبة طاولة $tableNumber' : 'Checkout Table $tableNumber';
  String checkoutSuccess(String amount, int tableNumber) => isArabic ? 'تمت المحاسبة بنجاح بمبلغ $amount لطاولة $tableNumber!' : 'Checked out successfully: $amount for table $tableNumber!';
  String get taxAddedRow => isArabic ? 'الضريبة المضافة (15%):' : 'Added VAT (15%):';
  String get totalDue => isArabic ? 'الإجمالي المستحق:' : 'Total Due:';
  String get printTaxInvoice => isArabic ? 'طباعة الفاتورة الضريبية للعميل' : 'Print Tax Invoice for Customer';
  String get confirmPaymentAndRelease => isArabic ? 'تأكيد الدفع والإخلاء' : 'Confirm Payment & Release';
  String confirmFullSettlement(String amount) => isArabic ? 'تأكيد السداد الكامل ($amount)' : 'Confirm Full Payment ($amount)';
  String get saveAndConfirmSplit => isArabic ? 'حفظ وتأكيد التقسيم' : 'Save & Confirm Split';
  String splitBillTitle(int tableNumber) => isArabic ? 'تقسيم شيك طاولة $tableNumber' : 'Split Table $tableNumber Bill';
  String get originalBillTotal => isArabic ? 'إجمالي الفاتورة الأصلية:' : 'Original Bill Total:';
  String get equalSplit => isArabic ? 'تقسيم متساوي' : 'Equal Split';
  String get bySeatSplit => isArabic ? 'حسب المقاعد والأصناف' : 'By Seat & Items';
  String get couponSuffix => isArabic ? '(كوبون)' : '(Coupon)';
  String get cashShort => isArabic ? 'كاش' : 'Cash';
  String get cardShort => isArabic ? 'بطاقة' : 'Card';
  String get walletShort => isArabic ? 'محفظة' : 'Wallet';

  // ── Order Types & Statuses ─────────────────────────────────────────────────
  String get orderTypeDineIn => isArabic ? 'في المطعم' : 'Dine-In';
  String get orderTypeTakeaway => isArabic ? 'طلب سفري' : 'Takeaway';
  String get orderTypeDelivery => isArabic ? 'توصيل' : 'Delivery';
  String get orderStatusPending => isArabic ? 'قيد الانتظار' : 'Pending';
  String get orderStatusConfirmed => isArabic ? 'مؤكد' : 'Confirmed';
  String get orderStatusPreparing => isArabic ? 'قيد التحضير' : 'Preparing';
  String get orderStatusReady => isArabic ? 'جاهز' : 'Ready';
  String get orderStatusServed => isArabic ? 'تم التقديم' : 'Served';
  String get orderStatusCompleted => isArabic ? 'مكتمل' : 'Completed';
  String get orderStatusCancelled => isArabic ? 'ملغي' : 'Cancelled';

  // ── KDS & Orders Extensions ────────────────────────────────────────────────
  String kdsRevertPrompt(String status) => isArabic ? 'تراجع إلى $status؟' : 'Revert to $status?';
  String get orderAuditTrailRetryAction => isArabic ? 'لنحاول مجدداً' : 'Try Again';

  // ── Dispatch Health ────────────────────────────────────────────────────────
  String get dispatchHealthPendingOrders => isArabic ? 'طلبات بانتظار سائق' : 'Orders Awaiting Driver';
  String get dispatchHealthFailedAssignments => isArabic ? 'تكليفات تحتاج متابعة' : 'Assignments Needing Follow-up';
  String get dispatchHealthAvailableDrivers => isArabic ? 'سائقون متاحون' : 'Available Drivers';

  // ── Dietary ────────────────────────────────────────────────────────────────
  String get dietAll => isArabic ? 'الكل' : 'All';
  String get dietVegetarian => isArabic ? 'نباتي' : 'Vegetarian';
  String get dietSpicy => isArabic ? 'حار' : 'Spicy';

  // ── Restaurant Settings & Forms ────────────────────────────────────────────
  String get restaurantSettingsTitle => isArabic ? 'بيانات المطعم' : 'Restaurant Settings';
  String get restaurantSettingsSubtitle => isArabic
      ? 'إدارة الهوية، أوقات العمل، السعة والتواصل'
      : 'Manage identity, business hours, capacity & contact';
  String get discountTypePercentage => isArabic ? 'نسبة مئوية' : 'Percentage';
  String get discountTypeFixedAmount => isArabic ? 'مبلغ ثابت' : 'Fixed Amount';
  String get discountTypeCoupon => isArabic ? 'كوبون' : 'Coupon';
  String get exportInventoryCsvTooltip => isArabic ? 'تصدير تقرير المخزون CSV' : 'Export Inventory CSV';
  String inventoryExportSuccess(int count) => isArabic ? 'تم تصدير تقرير $count صنف بنجاح!' : 'Exported report of $count items successfully!';
  String get filterByStatusTooltip => isArabic ? 'تصفية حسب الحالة' : 'Filter by Status';
  String joinRestaurant(String name) => isArabic ? 'انضم إلى $name' : 'Join $name';
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeControllerProvider);
  Formatters.setLocale(locale.languageCode);
  return AppStrings(locale);
});
