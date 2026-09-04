import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:irfan_academy/screens/splash/splash_screen.dart';

void main() {
  testWidgets('shows Irfan Academy splash screen', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen()),
    );

    expect(find.text('Irfan Academy'), findsOneWidget);
    expect(find.text('Начать обучение'), findsOneWidget);
    expect(find.text('Бишкек · Кыргызстан'), findsOneWidget);
  });
}
