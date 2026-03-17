import 'package:flutter_test/flutter_test.dart';
import 'package:uv_exposure_demo/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const UVApp());

    // Verify that the Onboarding screen is present.
    expect(find.text('UV Tracker'), findsOneWidget);
    expect(find.text('Start Setup'), findsOneWidget);
  });
}
