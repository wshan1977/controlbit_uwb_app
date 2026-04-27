import 'package:flutter/material.dart';

import '../models/ranging_sample.dart';

class DistanceSparkline extends StatelessWidget {
  const DistanceSparkline({
    super.key,
    required this.samples,
    this.height = 80,
  });

  final List<RangingSample> samples;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          samples: samples,
          color: Theme.of(context).colorScheme.primary,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.samples, required this.color});

  final List<RangingSample> samples;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;

    var minD = samples.first.distanceM;
    var maxD = minD;
    for (final s in samples) {
      if (s.distanceM < minD) minD = s.distanceM;
      if (s.distanceM > maxD) maxD = s.distanceM;
    }
    final range = (maxD - minD).abs() < 1e-3 ? 1.0 : (maxD - minD);

    final tStart = samples.first.timestampMs;
    final tEnd = samples.last.timestampMs;
    final tRange = (tEnd - tStart) <= 0 ? 1 : (tEnd - tStart);

    final path = Path();
    for (int i = 0; i < samples.length; i++) {
      final s = samples[i];
      final x = ((s.timestampMs - tStart) / tRange) * size.width;
      final y =
          size.height - ((s.distanceM - minD) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.samples != samples || old.color != color;
}
