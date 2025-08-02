// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:to_do_list_app/main.dart'; // Assumes your project folder is named to_do_list_app

void main() {
  testWidgets('App builds and shows onboarding screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // The main app class is now TaskMasterApp
    await tester.pumpWidget(const TaskMasterApp());

    // Verify that the onboarding title is present.
    expect(find.text('Manage Your Everyday Tasks'), findsOneWidget);
    
    // Verify the "Get Started" button is present.
    expect(find.widgetWithText(ElevatedButton, 'Get Started'), findsOneWidget);
  });
}
