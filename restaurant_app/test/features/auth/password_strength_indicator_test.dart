import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/core/theme/status_colors.dart';
import 'package:restaurant_app/features/auth/presentation/pages/login_page.dart';
import 'package:restaurant_app/features/auth/presentation/pages/register_page.dart';
import 'package:restaurant_app/features/auth/presentation/widgets/password_strength_indicator.dart';

void main() {
  // MaterialApp defaults to light brightness; resolve the audited palette
  // tones through the same API the widget uses so the test can't drift.
  final warningTone = StatusColors.tone(SemanticTone.warning, Brightness.light);
  final successTone = StatusColors.tone(SemanticTone.success, Brightness.light);

  /// Colors of the meter's pill segments, in no guaranteed order.
  List<Color> segmentColors(WidgetTester tester) {
    return tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(PasswordStrengthIndicator),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Container &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration! as BoxDecoration).color != null,
            ),
          ),
        )
        .map((container) => (container.decoration! as BoxDecoration).color!)
        .toList();
  }

  /// Locates the editable [TextField] rendered by the form field labelled
  /// [label]. Autofill/capitalization props are exposed on [TextField], not
  /// on its [TextFormField] wrapper.
  TextField editableFieldOf(WidgetTester tester, String label) {
    return tester.widget<TextField>(
      find
          .descendant(
            of: find.widgetWithText(TextFormField, label),
            matching: find.byType(TextField),
          )
          .first,
    );
  }

  ThemeData themeOfMeter(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(PasswordStrengthIndicator)));

  Future<void> pumpIndicator(WidgetTester tester, String password) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PasswordStrengthIndicator(password: password)),
      ),
    );
  }

  group('PasswordStrengthIndicator', () {
    test('evaluate mirrors the shared Validators scoring', () {
      expect(PasswordStrengthIndicator.evaluate(null), PasswordStrength.weak);
      expect(PasswordStrengthIndicator.evaluate(''), PasswordStrength.weak);
      // Short, no digit → only the letter criterion is met.
      expect(
        PasswordStrengthIndicator.evaluate('abcde'),
        PasswordStrength.weak,
      );
      // Long enough but missing a digit.
      expect(
        PasswordStrengthIndicator.evaluate('abcdefghij'),
        PasswordStrength.good,
      );
      // Letter + digit but too short.
      expect(PasswordStrengthIndicator.evaluate('a1'), PasswordStrength.good);
      // Every criterion passes.
      expect(
        PasswordStrengthIndicator.evaluate('Abcdef12'),
        PasswordStrength.strong,
      );
    });

    testWidgets('hidden entirely while the password is empty', (tester) async {
      await pumpIndicator(tester, '');

      expect(find.text('ضعيفة'), findsNothing);
      expect(find.text('متوسطة'), findsNothing);
      expect(find.text('قوية'), findsNothing);
      expect(segmentColors(tester), isEmpty);
    });

    testWidgets('short/no-digit password renders weak in error color', (
      tester,
    ) async {
      await pumpIndicator(tester, 'abc');

      expect(find.text('ضعيفة'), findsOneWidget);

      final theme = themeOfMeter(tester);
      final colors = segmentColors(tester);
      expect(colors, hasLength(3));
      expect(colors.where((c) => c == theme.colorScheme.error), hasLength(1));
      expect(
        colors.where((c) => c == theme.colorScheme.surfaceContainerHighest),
        hasLength(2),
      );

      final label = tester.widget<Text>(find.text('ضعيفة'));
      expect(label.style?.color, theme.colorScheme.error);
    });

    testWidgets('medium password renders good in warning tone', (tester) async {
      await pumpIndicator(tester, 'abcdefghij');

      expect(find.text('متوسطة'), findsOneWidget);

      final theme = themeOfMeter(tester);
      final colors = segmentColors(tester);
      expect(colors, hasLength(3));
      expect(colors.where((c) => c == warningTone), hasLength(2));
      expect(
        colors.where((c) => c == theme.colorScheme.surfaceContainerHighest),
        hasLength(1),
      );

      final label = tester.widget<Text>(find.text('متوسطة'));
      expect(label.style?.color, warningTone);
    });

    testWidgets('strong password renders strong in success tone', (
      tester,
    ) async {
      await pumpIndicator(tester, 'Abcdef12');

      expect(find.text('قوية'), findsOneWidget);

      final colors = segmentColors(tester);
      expect(colors, hasLength(3));
      expect(colors.where((c) => c == successTone), hasLength(3));

      final label = tester.widget<Text>(find.text('قوية'));
      expect(label.style?.color, successTone);
    });
  });

  group('auth forms autofill support', () {
    testWidgets('login page exposes email and password hints', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginPage())),
      );

      expect(find.byType(AutofillGroup), findsWidgets);

      final emailField = editableFieldOf(tester, AppConstants.emailLabel);
      expect(emailField.autofillHints, contains(AutofillHints.email));

      final passwordField = editableFieldOf(tester, AppConstants.passwordLabel);
      expect(passwordField.autofillHints, contains(AutofillHints.password));
    });

    testWidgets('register page exposes name/email/phone/new-password hints', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RegisterPage())),
      );

      expect(find.byType(AutofillGroup), findsWidgets);

      final nameField = editableFieldOf(tester, 'الاسم بالكامل');
      expect(nameField.autofillHints, contains(AutofillHints.name));
      expect(nameField.textCapitalization, TextCapitalization.words);

      final emailField = editableFieldOf(tester, AppConstants.emailLabel);
      expect(emailField.autofillHints, contains(AutofillHints.email));

      final phoneField = editableFieldOf(tester, 'رقم الهاتف');
      expect(phoneField.autofillHints, contains(AutofillHints.telephoneNumber));

      // Both password fields advertise new-password autofill.
      final newPasswordFields = tester
          .widgetList<TextField>(find.byType(TextField))
          .where(
            (field) =>
                field.autofillHints?.contains(AutofillHints.newPassword) ??
                false,
          )
          .length;
      expect(newPasswordFields, 2);
    });

    testWidgets('register page updates strength meter while typing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RegisterPage())),
      );

      final passwordField = find.widgetWithText(
        TextFormField,
        AppConstants.passwordLabel,
      );
      await tester.ensureVisible(passwordField);

      // Hidden before any input.
      expect(find.text('ضعيفة'), findsNothing);

      await tester.enterText(passwordField, 'abc');
      await tester.pump();
      expect(find.text('ضعيفة'), findsOneWidget);

      await tester.enterText(passwordField, 'Abcdef12');
      await tester.pump();
      expect(find.text('قوية'), findsOneWidget);

      // Clearing the field hides the meter again.
      await tester.enterText(passwordField, '');
      await tester.pump();
      expect(find.text('قوية'), findsNothing);
      expect(find.text('ضعيفة'), findsNothing);
    });
  });
}
