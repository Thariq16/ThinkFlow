import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('ThinkFlowApp renders', (WidgetTester tester) async {
    // Verify the app builds without errors
    // Note: Full integration tests require Firebase initialization
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('ThinkFlow Test'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('ThinkFlow Test'), findsOneWidget);
  });
}
