import 'dart:math';

import 'package:flutter/material.dart';

class AoaCompass extends StatelessWidget {
  const AoaCompass({
    super.key,
    required this.azimuthDeg,
    this.elevationDeg,
    this.size = 160,
  });

  final double azimuthDeg;
  final double? elevationDeg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CompassPainter(
          azimuth: azimuthDeg,
          color: Theme.of(context).colorScheme.primary,
        ),
        child: Center(
          child: Text(
            '${azimuthDeg.toStringAsFixed(0)}°'
            '${elevationDeg == null ? '' : ' / ${elevationDeg!.toStringAsFixed(0)}°'}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({required this.azimuth, required this.color});

  final double azimuth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withValues(alpha: 0.4);
    canvas.drawCircle(center, radius, ring);

    // Tick marks every 30°.
    final tick = Paint()..color = color.withValues(alpha: 0.5);
    for (int deg = 0; deg < 360; deg += 30) {
      final r = (deg - 90) * pi / 180;
      final p1 = center + Offset(cos(r), sin(r)) * radius;
      final p2 = center + Offset(cos(r), sin(r)) * (radius - 6);
      canvas.drawLine(p1, p2, tick);
    }

    // Needle.
    final needle = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final r = (azimuth - 90) * pi / 180;
    final tip = center + Offset(cos(r), sin(r)) * (radius - 8);
    canvas.drawLine(center, tip, needle);
    canvas.drawCircle(center, 4, needle);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.azimuth != azimuth || old.color != color;
}
