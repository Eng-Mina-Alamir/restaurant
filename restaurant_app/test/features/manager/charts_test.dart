import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/widgets/peak_hours_chart.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/widgets/sales_line_chart.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/widgets/top_items_bar_chart.dart';

void main() {
  group('SalesLineChart', () {
    testWidgets('renders empty placeholder when no sales data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SalesLineChart(salesData: {}),
          ),
        ),
      );

      expect(find.text('لا توجد بيانات مبيعات كافية للرسم البياني'), findsOneWidget);
    });

    testWidgets('renders line chart with title when data is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SalesLineChart(
              salesData: {
                'السبت': 1200,
                'الأحد': 1500,
                'الإثنين': 1800,
              },
            ),
          ),
        ),
      );

      expect(find.text('منحنى المبيعات'), findsOneWidget);
      expect(find.text('مباشر'), findsOneWidget);
      expect(find.text('السبت'), findsOneWidget);
    });
  });

  group('TopItemsBarChart', () {
    testWidgets('renders empty placeholder when no items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TopItemsBarChart(itemsSold: {}),
          ),
        ),
      );

      expect(find.text('لا توجد بيانات مبيعات أصناف بعد'), findsOneWidget);
    });

    testWidgets('renders top items bar chart with items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TopItemsBarChart(
              itemsSold: {
                'برجر كلاسيك': 45,
                'بيتزا مارجريتا': 38,
                'شاورما دجاج': 29,
              },
            ),
          ),
        ),
      );

      expect(find.text('الأصناف الأكثر طلباً'), findsOneWidget);
    });
  });

  group('PeakHoursChart', () {
    testWidgets('renders peak hours chart with highlighted peak badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PeakHoursChart(
              hourlyDistribution: {
                14: 15,
                20: 50,
                21: 40,
              },
              peakHour: 20,
            ),
          ),
        ),
      );

      expect(find.text('توزيع الطلبات بالساعات (أوقات الذروة)'), findsOneWidget);
      expect(find.text('الذروة: 20:00'), findsOneWidget);
    });
  });
}
