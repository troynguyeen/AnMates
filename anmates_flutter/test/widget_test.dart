import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:anmates/main.dart';
import 'package:anmates/theme/app_theme.dart';

void main() {
  testWidgets('AnMates app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeNotifier(),
        child: const AnMatesApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
