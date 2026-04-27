import 'dart:async';

import '../models/ranging_sample.dart';
import '../uwb/uwb_models.dart';
import '../uwb/uwb_platform.dart';

class UwbService {
  UwbService([UwbPlatform? platform]) : _platform = platform ?? UwbPlatform.instance;

  final UwbPlatform _platform;

  Future<bool> isAvailable() => _platform.isUwbAvailable();
  Future<UwbCapabilities> getCapabilities() => _platform.getRangingCapabilities();
  Future<List<int>> getLocalAddress() async =>
      (await _platform.getLocalAddress()).toList();

  Future<void> start(UwbStartArgs args) => _platform.startRanging(args);
  Future<void> stop() => _platform.stopRanging();

  Stream<RangingEvent> events() => _platform.rangingEvents();

  /// Convenience: filter events to only RangingSample (i.e. RESULT events
  /// with non-null distance).
  Stream<RangingSample> samples() {
    return events()
        .where((e) =>
            e.type == RangingEventType.result && e.distanceM != null)
        .map((e) => RangingSample(
              timestampMs: e.timestampMs,
              distanceM: e.distanceM!,
              azimuthDeg: e.azimuthDeg,
              elevationDeg: e.elevationDeg,
              rssiDbm: e.rssiDbm,
              status: e.status ?? 0,
            ));
  }
}
