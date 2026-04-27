import 'package:app_uwb/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App launches into ScanScreen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: UwbTagApp()),
    );
    await tester.pump();
    expect(find.text('UWB Anchor 스캔'), findsOneWidget);
  });
}
