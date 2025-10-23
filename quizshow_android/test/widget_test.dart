// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quizshow_android/main.dart';

void main() {
  testWidgets('Quiz show app team buttons test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that all team buttons are present
    expect(find.text('TEAM RED'), findsOneWidget);
    expect(find.text('TEAM BLUE'), findsOneWidget);
    expect(find.text('TEAM YELLOW'), findsOneWidget);
    expect(find.text('TEAM GREEN'), findsOneWidget);
    expect(find.text('MASTER'), findsOneWidget);
  });
}
