import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:net_utility_toolkit/app/app.dart';

void main() {
  testWidgets('App smoke test — renders without crashing', (tester) async {
    await tester.pumpWidget(const NetUtilityApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
