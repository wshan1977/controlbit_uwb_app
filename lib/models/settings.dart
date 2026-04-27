import '../uwb/uwb_models.dart';

class AppSettings {
  const AppSettings({
    this.preferredChannels = const [9, 5],
    this.preambleIndexOverride,
    this.slotDurationMs = 2,
    this.rangingIntervalMs = 200,
    this.updateRate = RangingUpdateRate.automatic,
  });

  final List<int> preferredChannels;
  final int? preambleIndexOverride;
  final int slotDurationMs;
  final int rangingIntervalMs;
  final RangingUpdateRate updateRate;

  AppSettings copyWith({
    List<int>? preferredChannels,
    int? preambleIndexOverride,
    bool clearPreambleOverride = false,
    int? slotDurationMs,
    int? rangingIntervalMs,
    RangingUpdateRate? updateRate,
  }) =>
      AppSettings(
        preferredChannels: preferredChannels ?? this.preferredChannels,
        preambleIndexOverride: clearPreambleOverride
            ? null
            : (preambleIndexOverride ?? this.preambleIndexOverride),
        slotDurationMs: slotDurationMs ?? this.slotDurationMs,
        rangingIntervalMs: rangingIntervalMs ?? this.rangingIntervalMs,
        updateRate: updateRate ?? this.updateRate,
      );
}
