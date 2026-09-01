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
  String get nameLabel => isArabic ? 'الاسم بالكامل' : 'Full Name';
  String get phoneLabel => isArabic ? 'رقم الهاتف' : 'Phone Number';
  String get loginButton => isArabic ? 'دخول' : 'Login';
  String get registerTitle => isArabic ? 'إنشاء حساب جديد' : 'Create Account';
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
  String get welcomeManager => isArabic ? 'مرحباً بك، مدير' : 'Welcome, Manager of';
  String get welcomeAdmin => isArabic ? 'مرحباً بك، مسؤول النظام (Admin)' : 'Welcome, System Admin';
  String get readyAndReceiving => isArabic ? 'المطعم في حالة جاهزية واستقبال للطلبات' : 'Kitchen & POS Ready to take orders';
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
  String get emptyOrders => isArabic ? 'لا توجد طلبات حالياً' : 'No orders found';
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
  String get searchMenuHint => isArabic ? 'ابحث عن صنف أو وجبة...' : 'Search meals & drinks...';
  String get noItemsFound => isArabic ? 'لا توجد أصناف مطابقة للبحث' : 'No items match your search';
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
  String get cartEmpty => isArabic ? 'السلة فارغة' : 'Your cart is empty';
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
  String get orderPlacedSuccess => isArabic ? 'تم استلام طلبك بنجاح! جاري تحضيره' : 'Order placed successfully! Preparing soon';
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
  String get kdsTitle => isArabic ? 'شاشة المطبخ (KDS)' : 'Kitchen Display (KDS)';
  String get kdsPending => isArabic ? 'بانتظار التحضير' : 'Pending';
  String get kdsPreparing => isArabic ? 'قيد التحضير' : 'Preparing';
  String get kdsReady => isArabic ? 'جاهز للتسليم' : 'Ready';
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
  String get acceptDelivery => isArabic ? 'قبول وتولي التوصيل' : 'Accept Delivery';
  String get pickupFromRestaurant => isArabic ? 'استلام الطلب من المطعم' : 'Pickup from Restaurant';
  String get startDeliveryRoute => isArabic ? 'الانطلاق للعميل' : 'Start Delivery';
  String get markDelivered => isArabic ? 'تم التسليم للعميل بنجاح' : 'Mark Delivered';
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
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeControllerProvider);
  Formatters.setLocale(locale.languageCode);
  return AppStrings(locale);
});
