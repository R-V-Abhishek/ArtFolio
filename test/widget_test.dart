// ArtFolio widget tests
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artfolio/main.dart';

void main() {
  testWidgets('ArtFolio app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the welcome text is displayed.
    expect(find.text('Welcome to ArtFolio'), findsOneWidget);
    expect(
      find.text(
        'A professional network where creatives\ncan showcase their project stories.',
      ),
      findsOneWidget,
    );

    // Verify that the palette icon is present.
    expect(find.byIcon(Icons.palette), findsOneWidget);

    // Verify that the app title is correct.
    expect(find.text('ArtFolio - Creative Network'), findsOneWidget);
  });

  testWidgets('Counter increments correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('Counter: 0'), findsOneWidget);
    expect(find.text('Counter: 1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('Counter: 0'), findsNothing);
    expect(find.text('Counter: 1'), findsOneWidget);
  });
}
