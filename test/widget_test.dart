// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:expenses_tracking/main.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    // Initialize the ffi factory for tests
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Expense Tracker app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExpenseTrackerApp());
    
    // Wait for the first frame
    await tester.pump();

    // Verify that our app starts with the expense tracker screen.
    expect(find.text('Suivi des Dépenses'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    
    // Check for drawer menu icon (hamburger menu)
    expect(find.byType(DrawerButton), findsOneWidget);
  });
}
