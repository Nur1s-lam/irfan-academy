import 'package:flutter_test/flutter_test.dart';
import 'package:irfan_academy/main.dart';
import 'package:irfan_academy/theme/theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows Irfan Academy splash screen', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const IrfanAcademyApp(),
      ),
    );

    expect(find.text('Irfan Academy'), findsOneWidget);
    expect(find.text('Начать обучение'), findsOneWidget);
    expect(find.text('Бишкек · Кыргызстан'), findsOneWidget);
  });
}
