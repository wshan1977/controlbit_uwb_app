import 'package:flutter/material.dart';

class RssiBar extends StatelessWidget {
  const RssiBar({super.key, required this.rssi});

  final int rssi;

  /// Map RSSI dBm to a 0..1 strength.
  /// Strong: -45 dBm or better. Weak: -95 dBm or worse.
  double get _strength {
    final clamped = rssi.clamp(-95, -45);
    return (clamped + 95) / 50.0;
  }

  @override
  Widget build(BuildContext context) {
    final s = _strength;
    final color = Color.lerp(Colors.red, Colors.green, s)!;
    return SizedBox(
      width: 36,
      height: 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: s,
          backgroundColor: Colors.black12,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}
