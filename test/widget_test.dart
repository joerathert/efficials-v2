import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efficials_v2/widgets/standard_button.dart';
import 'package:efficials_v2/widgets/form_section.dart';
import 'package:efficials_v2/services/base_service.dart';
import 'package:efficials_v2/services/game_service.dart';
import 'package:efficials_v2/services/official_service.dart';
import 'package:efficials_v2/utils/validation_utils.dart';
import 'package:efficials_v2/utils/error_utils.dart';

void main() {
  group('StandardButton Tests', () {
    testWidgets('StandardButton renders correctly with text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StandardButton(
              text: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('StandardButton calls onPressed when tapped',
        (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StandardButton(
              text: 'Test Button',
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasPressed, true);
    });

    testWidgets('StandardButton has correct height and width',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StandardButton(
                text: 'Test Button',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final container = button.child as SizedBox;
      expect(container.height, 50.0);
      expect(container.width, 400.0);
    });
  });

  group('FormSection Tests', () {
    testWidgets('FormSection displays title and children',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormSection(
              title: 'Test Section',
              children: [
                Text('Child 1'),
                Text('Child 2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Section'), findsOneWidget);
      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsOneWidget);
    });

    testWidgets('FormSection has correct structure',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormSection(
              title: 'Test Section',
              children: [Text('Content')],
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Padding), findsWidgets);
    });
  });

  group('ValidationUtils Tests', () {
    test('validateEmail returns null for valid email', () {
      expect(ValidationUtils.validateEmail('test@example.com'), null);
    });

    test('validateEmail returns error for invalid email', () {
      expect(ValidationUtils.validateEmail('invalid-email'), isNotNull);
      expect(ValidationUtils.validateEmail(''), isNotNull);
    });

    test('validatePassword enforces minimum length', () {
      expect(ValidationUtils.validatePassword('12345'), isNotNull);
      expect(ValidationUtils.validatePassword('MySecure123!'), null);
    });

    test('validateRequired returns error for empty string', () {
      expect(ValidationUtils.validateRequired('', 'Test Field'), isNotNull);
      expect(ValidationUtils.validateRequired('test', 'Test Field'), null);
    });

    test('validateLength enforces character limits', () {
      expect(
          ValidationUtils.validateLength('test', 'Test Field', 3), isNotNull);
      expect(ValidationUtils.validateLength('test', 'Test Field', 5), null);
    });
  });

  group('BaseService Tests', () {
    test('BaseService debugPrint method exists', () {
      final service = TestBaseService();
      expect(() => service.debugPrint('test'), returnsNormally);
    });

    test('BaseService getters work', () {
      final service = TestBaseService();
      expect(service.firestore, isNotNull);
      expect(service.auth, isNotNull);
    });
  });

  group('Service Singleton Tests', () {
    test('GameService follows singleton pattern', () {
      final service1 = GameService();
      final service2 = GameService();
      expect(identical(service1, service2), true);
    });

    test('OfficialService follows singleton pattern', () {
      final service1 = OfficialService();
      final service2 = OfficialService();
      expect(identical(service1, service2), true);
    });
  });

  group('ErrorUtils Tests', () {
    testWidgets('ErrorUtils shows error snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ErrorUtils.showErrorSnackBar(
                  context,
                  'Test error message',
                ),
                child: Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('ErrorUtils shows success snackbar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ErrorUtils.showSuccessSnackBar(
                  context,
                  'Test success message',
                ),
                child: Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Test success message'), findsOneWidget);
    });
  });
}

// Test helper class
class TestBaseService extends BaseService {}
