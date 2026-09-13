// Basic smoke test. The full app requires Firebase to be initialized first
// (see main.dart), so this test exercises a standalone widget instead of
// pumping CareConnectApp directly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:careconnect/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen shows the app name', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.text('CareConnect'), findsOneWidget);
  });
}
