import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nee_construction_app/providers/auth_provider.dart';
import 'package:nee_construction_app/screens/onboarding_location_screen.dart';

void main() {
  testWidgets('Validates name, preserves it on back, and requires a location', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: OnboardingLocationScreen()),
      ),
    );
    await tester.tap(find.text('Continue to location'));
    await tester.pump();
    expect(find.text('Please enter your name to continue.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Anu Bora');
    await tester.tap(find.text('Continue to location'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 2'), findsOneWidget);
    final finish = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Finish setup'),
    );
    expect(finish.onPressed, isNull);
    await tester.tap(find.byTooltip('Back to your name'));
    await tester.pumpAndSettle();
    expect(find.text('Anu Bora'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Small screen with keyboard keeps continue accessible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: OnboardingLocationScreen()),
      ),
    );
    expect(find.text('Continue to location').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
