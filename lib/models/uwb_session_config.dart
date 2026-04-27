import 'dart:math';
import 'dart:typed_data';

import '../uwb/uwb_models.dart';

class UwbSessionConfig {
  const UwbSessionConfig({
    required this.sessionId,
    required this.sessionKey,
    required this.channel,
    required this.preambleIndex,
    required this.controllerShortAddr,
    required this.controleeShortAddr,
    required this.slotDurationMs,
    required this.rangingIntervalMs,
    required this.updateRateType,
    this.uwbConfigId = 1,
    this.stsCfg = 0,
  })  : assert(sessionKey.length == 8),
        assert(controllerShortAddr.length == 2),
        assert(controleeShortAddr.length == 2);

  final int sessionId;
  final Uint8List sessionKey; // 8 bytes (Static STS)
  final int channel; // 5 or 9
  final int preambleIndex;
  final Uint8List controllerShortAddr; // anchor LE
  final Uint8List controleeShortAddr; // phone LE
  final int slotDurationMs;
  final int rangingIntervalMs;
  final RangingUpdateRate updateRateType;
  final int uwbConfigId;
  final int stsCfg;

  static UwbSessionConfig generate({
    required int channel,
    required int preambleIndex,
    required Uint8List controllerShortAddr,
    required Uint8List controleeShortAddr,
    int slotDurationMs = 2,
    int rangingIntervalMs = 200,
    RangingUpdateRate updateRateType = RangingUpdateRate.automatic,
    Random? rng,
  }) {
    final r = rng ?? Random.secure();
    final id = r.nextInt(0xFFFFFFFF);
    final key = Uint8List.fromList(
      List<int>.generate(8, (_) => r.nextInt(256)),
    );
    return UwbSessionConfig(
      sessionId: id,
      sessionKey: key,
      channel: channel,
      preambleIndex: preambleIndex,
      controllerShortAddr: controllerShortAddr,
      controleeShortAddr: controleeShortAddr,
      slotDurationMs: slotDurationMs,
      rangingIntervalMs: rangingIntervalMs,
      updateRateType: updateRateType,
    );
  }
}
