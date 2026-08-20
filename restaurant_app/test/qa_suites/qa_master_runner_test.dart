import 'package:flutter_test/flutter_test.dart';

import 'helpers/qa_test_helpers.dart';
import 'suite_01_auth_onboarding_test.dart' as suite1;
import 'suite_02_customer_experience_test.dart' as suite2;
import 'suite_03_waiter_table_management_test.dart' as suite3;
import 'suite_04_kds_system_test.dart' as suite4;
import 'suite_05_delivery_driver_test.dart' as suite5;
import 'suite_06_manager_dashboard_test.dart' as suite6;
import 'suite_07_loyalty_rewards_test.dart' as suite7;
import 'suite_08_realtime_notifications_test.dart' as suite8;
import 'suite_09_localization_theme_test.dart' as suite9;
import 'suite_10_edge_cases_performance_test.dart' as suite10;

/// QA Master Runner - Smart Restaurant Multi-Role System v1.0.0 (Release Candidate)
///
/// Runs all 10 QA Test Suites covering TC-AUTH-01 through TC-EDGE-05:
/// - Suite 1: Auth & Onboarding (TC-AUTH-01 -> TC-AUTH-06)
/// - Suite 2: Customer Experience Flow (TC-CUST-01 -> TC-CUST-08)
/// - Suite 3: Waiter & Table Management (TC-WAIT-01 -> TC-WAIT-05)
/// - Suite 4: Kitchen Display System KDS (TC-KDS-01 -> TC-KDS-05)
/// - Suite 5: Delivery Driver Flow (TC-DRV-01 -> TC-DRV-04)
/// - Suite 6: Manager Dashboard (TC-MGR-01 -> TC-MGR-07)
/// - Suite 7: Loyalty & Rewards (TC-LOY-01 -> TC-LOY-03)
/// - Suite 8: Realtime & Notifications (TC-NOTIF-01 -> TC-NOTIF-03)
/// - Suite 9: Localization & Themes (TC-LOC-01, TC-LOC-02, TC-THM-01)
/// - Suite 10: Edge Cases & Performance (TC-EDGE-01 -> TC-EDGE-05)
void main() {
  setUpAll(() {
    initQaTestEnvironment();
  });

  group('🎯 MASTER QA TEST SUITE: Smart Restaurant System v1.0.0 RC', () {
    suite1.main();
    suite2.main();
    suite3.main();
    suite4.main();
    suite5.main();
    suite6.main();
    suite7.main();
    suite8.main();
    suite9.main();
    suite10.main();
  });
}
