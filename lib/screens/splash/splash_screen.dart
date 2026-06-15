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
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _GeometricPattern()),
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
                          color: AppTheme.goldDeep,
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
                    ).textTheme.bodyLarge?.copyWith(color: AppTheme.inkSoft),
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
                    ).textTheme.labelMedium?.copyWith(color: AppTheme.inkFaint),
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
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.gold, AppTheme.goldDeep],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldDeep.withValues(alpha: 0.24),
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
              color: Colors.white.withValues(alpha: 0.78),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _GeometricPattern extends StatelessWidget {
  const _GeometricPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PatternPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppTheme.bg;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final linePaint = Paint()
      ..color = AppTheme.goldDeep.withValues(alpha: 0.055)
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
              AppTheme.goldSoft.withValues(alpha: 0.9),
              AppTheme.goldSoft.withValues(alpha: 0),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
