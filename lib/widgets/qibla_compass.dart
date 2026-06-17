import 'dart:math' as math;

import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

class QiblaCompass extends StatefulWidget {
  const QiblaCompass({
    super.key,
    required this.qiblaDirection,
    required this.locationLabel,
  });

  final double qiblaDirection;
  final String locationLabel;

  @override
  State<QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<QiblaCompass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: AppTheme.motionCurve);
    _rotation = Tween<double>(begin: -0.08, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: AppTheme.motionCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return AppCard(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Направление киблы · ${widget.locationLabel}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 18),
          StreamBuilder<CompassEvent>(
            stream: FlutterCompass.events,
            builder: (context, snapshot) {
              final heading = snapshot.data?.heading;
              final relativeQibla = heading == null
                  ? widget.qiblaDirection
                  : _normalizeDegrees(widget.qiblaDirection - heading);

              return Column(
                children: [
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: FadeTransition(
                      opacity: _fade,
                      child: AnimatedBuilder(
                        animation: _rotation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotation.value,
                            child: child,
                          );
                        },
                        child: CustomPaint(
                          painter: _QiblaCompassPainter(
                            qiblaDegrees: relativeQibla,
                            palette: palette,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${widget.qiblaDirection.round()}° ${_directionLabel(widget.qiblaDirection)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: palette.primaryDeep,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    heading == null
                        ? 'Датчик компаса недоступен или ожидает калибровки'
                        : 'Курс телефона: ${heading.round()}° · поверните к золотой метке',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  double _normalizeDegrees(double degrees) {
    final normalized = degrees % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  String _directionLabel(double degrees) {
    final normalized = _normalizeDegrees(degrees);
    if (normalized >= 337.5 || normalized < 22.5) {
      return 'С';
    }
    if (normalized < 67.5) {
      return 'СВ';
    }
    if (normalized < 112.5) {
      return 'В';
    }
    if (normalized < 157.5) {
      return 'ЮВ';
    }
    if (normalized < 202.5) {
      return 'Ю';
    }
    if (normalized < 247.5) {
      return 'ЮЗ';
    }
    if (normalized < 292.5) {
      return 'З';
    }
    return 'СЗ';
  }
}

class _QiblaCompassPainter extends CustomPainter {
  const _QiblaCompassPainter({
    required this.qiblaDegrees,
    required this.palette,
  });

  final double qiblaDegrees;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    final circlePaint = Paint()
      ..color = palette.primarySoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius - 24, circlePaint);

    _drawTicks(canvas, center, radius);
    _drawDirections(canvas, center, radius);
    _drawNeedle(canvas, center, radius);

    canvas.drawCircle(
      center,
      6,
      Paint()
        ..color = palette.primary
        ..style = PaintingStyle.fill,
    );
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    for (var degrees = 0; degrees < 360; degrees += 5) {
      final isMajor = degrees % 45 == 0;
      final startRadius = radius - (isMajor ? 14 : 8);
      final endRadius = radius;
      final start = _point(center, startRadius, degrees.toDouble());
      final end = _point(center, endRadius, degrees.toDouble());
      final paint = Paint()
        ..color = isMajor ? palette.primaryDeep : palette.inkFaint
        ..strokeWidth = isMajor ? 2.1 : 1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawDirections(Canvas canvas, Offset center, double radius) {
    const labels = {
      0: 'С',
      45: 'СВ',
      90: 'В',
      135: 'ЮВ',
      180: 'Ю',
      225: 'ЮЗ',
      270: 'З',
      315: 'СЗ',
    };

    for (final entry in labels.entries) {
      final isNorth = entry.key == 0;
      final painter = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: TextStyle(
            color: isNorth ? palette.primaryDeep : palette.ink,
            fontSize: isNorth ? 17 : 13,
            fontWeight: isNorth ? FontWeight.w900 : FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final offset = _point(center, radius - 34, entry.key.toDouble());
      painter.paint(
        canvas,
        offset - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  void _drawNeedle(Canvas canvas, Offset center, double radius) {
    final tip = _point(center, radius - 58, qiblaDegrees);
    final tail = _point(center, radius - 64, qiblaDegrees + 180);
    final left = _point(center, 10, qiblaDegrees - 90);
    final right = _point(center, 10, qiblaDegrees + 90);

    final topPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(
      topPath,
      Paint()
        ..color = palette.primary
        ..style = PaintingStyle.fill,
    );

    final bottomPath = Path()
      ..moveTo(tail.dx, tail.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(
      bottomPath,
      Paint()
        ..color = palette.inkFaint
        ..style = PaintingStyle.fill,
    );

    _drawKaaba(canvas, tip);
  }

  void _drawKaaba(Canvas canvas, Offset tip) {
    final rect = Rect.fromCenter(center: tip, width: 12, height: 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()
        ..color = palette.ink
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()
        ..color = palette.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  Offset _point(Offset center, double radius, double degrees) {
    final radians = (degrees - 90) * math.pi / 180;
    return Offset(
      center.dx + math.cos(radians) * radius,
      center.dy + math.sin(radians) * radius,
    );
  }

  @override
  bool shouldRepaint(covariant _QiblaCompassPainter oldDelegate) {
    return oldDelegate.qiblaDegrees != qiblaDegrees ||
        oldDelegate.palette != palette;
  }
}
