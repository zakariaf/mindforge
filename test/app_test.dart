import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/app.dart';

void main() {
  testWidgets('MindForgeApp mounts without throwing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MindForgeApp()));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
