import 'package:flutter_test/flutter_test.dart';

import 'package:client/main.dart';
import 'package:client/presentation/screens/auth/walkthrough_screen.dart';

void main() {
  testWidgets('Splash navigates to walkthrough', (WidgetTester tester) async {
    await tester.pumpWidget(const EVCPointApp());

    expect(find.text('EVCPoint'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(WalkthroughScreen), findsOneWidget);
  });
}
