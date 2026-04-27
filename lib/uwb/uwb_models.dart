import 'dart:typed_data';

class UwbCapabilities {
  const UwbCapabilities({
    required this.isDistanceSupported,
    required this.isAzimuthalAngleSupported,
    required this.isElevationAngleSupported,
    required this.minRangingInterval,
    required this.supportedChannels,
    required this.supportedConfigIds,
    required this.supportedSlotDurations,
    required this.supportedRangingUpdateRates,
    required this.isBackgroundRangingSupported,
  });

  final bool isDistanceSupported;
  final bool isAzimuthalAngleSupported;
  final bool isElevationAngleSupported;
  final int minRangingInterval;
  final List<int> supportedChannels;
  final List<int> supportedConfigIds;
  final List<int> supportedSlotDurations;
  final List<int> supportedRangingUpdateRates;
  final bool isBackgroundRangingSupported;

  factory UwbCapabilities.fromMap(Map<String, dynamic> m) => UwbCapabilities(
        isDistanceSupported: (m['isDistanceSupported'] as bool?) ?? false,
        isAzimuthalAngleSupported:
            (m['isAzimuthalAngleSupported'] as bool?) ?? false,
        isElevationAngleSupported:
            (m['isElevationAngleSupported'] as bool?) ?? false,
        minRangingInterval: (m['minRangingInterval'] as num?)?.toInt() ?? 0,
        supportedChannels: _intList(m['supportedChannels']),
        supportedConfigIds: _intList(m['supportedConfigIds']),
        supportedSlotDurations: _intList(m['supportedSlotDurations']),
        supportedRangingUpdateRates:
            _intList(m['supportedRangingUpdateRates']),
        isBackgroundRangingSupported:
            (m['isBackgroundRangingSupported'] as bool?) ?? false,
      );

  static List<int> _intList(Object? v) {
    if (v is List) return v.map((e) => (e as num).toInt()).toList();
    return const <int>[];
  }

  Map<String, dynamic> toJson() => {
        'isDistanceSupported': isDistanceSupported,
        'isAzimuthalAngleSupported': isAzimuthalAngleSupported,
        'isElevationAngleSupported': isElevationAngleSupported,
        'minRangingInterval': minRangingInterval,
        'supportedChannels': supportedChannels,
        'supportedConfigIds': supportedConfigIds,
        'supportedSlotDurations': supportedSlotDurations,
        'supportedRangingUpdateRates': supportedRangingUpdateRates,
        'isBackgroundRangingSupported': isBackgroundRangingSupported,
      };
}

enum RangingUpdateRate { automatic, infrequent, fast }

extension RangingUpdateRateX on RangingUpdateRate {
  String get wire => switch (this) {
        RangingUpdateRate.automatic => 'AUTOMATIC',
        RangingUpdateRate.infrequent => 'INFREQUENT',
        RangingUpdateRate.fast => 'FAST',
      };
}

class UwbStartArgs {
  const UwbStartArgs({
    required this.controllerAddress,
    required this.sessionId,
    required this.sessionKeyInfo,
    required this.channel,
    required this.preambleIndex,
    this.uwbConfigId = 1,
    this.rangingUpdateRate = RangingUpdateRate.automatic,
    this.slotDurationMs,
  })  : assert(controllerAddress.length == 2,
            'controllerAddress must be 2 bytes (FiRa short addr)'),
        assert(sessionKeyInfo.length == 8,
            'sessionKeyInfo must be 8 bytes for Static STS');

  final Uint8List controllerAddress;
  final int sessionId;
  final Uint8List sessionKeyInfo;
  final int channel;
  final int preambleIndex;
  final int uwbConfigId;
  final RangingUpdateRate rangingUpdateRate;
  final int? slotDurationMs;

  Map<String, dynamic> toMap() => {
        'controllerAddress': controllerAddress,
        'sessionId': sessionId,
        'sessionKeyInfo': sessionKeyInfo,
        'channel': channel,
        'preambleIndex': preambleIndex,
        'uwbConfigId': uwbConfigId,
        'rangingUpdateRate': rangingUpdateRate.wire,
        if (slotDurationMs != null) 'slotDurationMs': slotDurationMs,
      };
}

enum RangingEventType { result, started, stopped, peerDisconnected, error, other }

class RangingEvent {
  const RangingEvent({
    required this.type,
    required this.timestampMs,
    this.distanceM,
    this.azimuthDeg,
    this.elevationDeg,
    this.rssiDbm,
    this.status,
    this.errorCode,
    this.message,
  });

  final RangingEventType type;
  final int timestampMs;
  final double? distanceM;
  final double? azimuthDeg;
  final double? elevationDeg;
  final int? rssiDbm;
  final int? status;
  final String? errorCode;
  final String? message;

  factory RangingEvent.fromMap(Map<String, dynamic> m) {
    final raw = (m['type'] as String?) ?? 'OTHER';
    return RangingEvent(
      type: switch (raw) {
        'RESULT' => RangingEventType.result,
        'STARTED' => RangingEventType.started,
        'STOPPED' => RangingEventType.stopped,
        'PEER_DISCONNECTED' => RangingEventType.peerDisconnected,
        'ERROR' => RangingEventType.error,
        _ => RangingEventType.other,
      },
      timestampMs: (m['timestamp'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      distanceM: (m['distanceM'] as num?)?.toDouble(),
      azimuthDeg: (m['azimuthDeg'] as num?)?.toDouble(),
      elevationDeg: (m['elevationDeg'] as num?)?.toDouble(),
      rssiDbm: (m['rssiDbm'] as num?)?.toInt(),
      status: (m['status'] as num?)?.toInt(),
      errorCode: m['errorCode'] as String?,
      message: m['message'] as String?,
    );
  }
}
