import 'package:flutter_test/flutter_test.dart';
import 'package:steermate/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SteerMateApp());

    // Verify that the app shows login screen
    expect(find.text('SteerMate'), findsOneWidget);
  });
}
