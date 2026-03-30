import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menstrual_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });
}