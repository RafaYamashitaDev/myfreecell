import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myfreecell/main.dart';

void main() {
  testWidgets('application shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
