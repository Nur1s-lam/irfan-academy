import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gold_button.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void _openRegister(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _openLogin(BuildContext context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _GeometricPattern(palette: palette)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: Column(
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'بِسْمِ اللّٰهِ',
                        textAlign: TextAlign.right,
                        style: AppTheme.arabicText(
                          fontSize: 30,
                          color: palette.primaryDeep,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  const _LogoMark(),
                  const SizedBox(height: 22),
                  Text(
                    'Irfan Academy',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Знание, поклонение и ежедневная практика',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: palette.inkSoft),
                  ),
                  const Spacer(flex: 3),
                  GoldButton(
                    label: 'Начать обучение',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => _openRegister(context),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _openLogin(context),
                    child: const Text('Уже учитесь? Войти'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Бишкек · Кыргызстан',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: palette.inkFaint),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = AppTheme.palette(context);

    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.primary, palette.primaryDeep],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: palette.primaryDeep.withValues(alpha: 0.24),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.onPrimary.withValues(alpha: 0.78),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.auto_stories_rounded,
            color: colorScheme.onPrimary,
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _GeometricPattern extends StatelessWidget {
  const _GeometricPattern({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PatternPainter(palette: palette),
      child: const SizedBox.expand(),
    );
  }
}

class _PatternPainter extends CustomPainter {
  const _PatternPainter({required this.palette});

  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = palette.background;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final linePaint = Paint()
      ..color = palette.primaryDeep.withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const step = 54.0;
    for (var y = -step; y < size.height + step; y += step) {
      for (var x = -step; x < size.width + step; x += step) {
        final center = Offset(x + step / 2, y + step / 2);
        final rect = Rect.fromCenter(center: center, width: 28, height: 28);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(math.pi / 4);
        canvas.translate(-center.dx, -center.dy);
        canvas.drawRect(rect, linePaint);
        canvas.restore();
        canvas.drawCircle(center, 3, linePaint);
      }
    }

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              palette.primarySoft.withValues(alpha: 0.9),
              palette.primarySoft.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.38),
              radius: size.width * 0.8,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.38),
      size.width * 0.8,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.palette != palette;
  }
}
