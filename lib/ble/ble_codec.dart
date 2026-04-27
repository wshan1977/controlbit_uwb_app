import 'dart:typed_data';

import '../models/anchor_info.dart';
import '../models/uwb_session_config.dart';
import '../uwb/uwb_models.dart';
import 'ble_uuids.dart';

class BleCodec {
  /// AnchorInfo: 16 bytes. Layout matches plan §4.
  static const anchorInfoLength = 16;
  static const sessionConfigLength = 32;
  static const sessionStateLength = 4;

  static AnchorInfo decodeAnchorInfo(Uint8List bytes) {
    if (bytes.length != anchorInfoLength) {
      throw FormatException(
        'AnchorInfo expected $anchorInfoLength bytes, got ${bytes.length}',
      );
    }
    final bd = ByteData.sublistView(bytes);
    return AnchorInfo(
      protocolVersion: bd.getUint8(0),
      role: bd.getUint8(1),
      anchorShortAddr: Uint8List.fromList([bytes[2], bytes[3]]),
      supportedChannelMask: bd.getUint16(4, Endian.little),
      supportedPreambleMin: bd.getUint8(6),
      supportedPreambleMax: bd.getUint8(7),
      mtuPreference: bd.getUint8(8),
      anchorVendorId: Uint8List.fromList(bytes.sublist(9, 16)),
    );
  }

  /// SessionConfig: 32 bytes, little-endian. Layout matches plan §4.
  static Uint8List encodeSessionConfig(UwbSessionConfig c) {
    final out = Uint8List(sessionConfigLength);
    final bd = ByteData.sublistView(out);
    bd.setUint8(0, BleUuids.protocolVersion);
    bd.setUint8(1, c.uwbConfigId);
    bd.setUint32(2, c.sessionId, Endian.little);
    out.setRange(6, 14, c.sessionKey);
    bd.setUint8(14, c.channel);
    bd.setUint8(15, c.preambleIndex);
    out.setRange(16, 18, c.controllerShortAddr);
    out.setRange(18, 20, c.controleeShortAddr);
    bd.setUint16(20, c.slotDurationMs, Endian.little);
    bd.setUint32(22, c.rangingIntervalMs, Endian.little);
    bd.setUint8(26, _updateRateWire(c.updateRateType));
    bd.setUint8(27, c.stsCfg);
    // 28..31 reserved, already zero
    return out;
  }

  static int _updateRateWire(RangingUpdateRate r) => switch (r) {
        RangingUpdateRate.automatic => 0,
        RangingUpdateRate.infrequent => 1,
        RangingUpdateRate.fast => 2,
      };

  /// SessionState notify: 4 bytes.
  static SessionStateNotify decodeSessionState(Uint8List bytes) {
    if (bytes.length != sessionStateLength) {
      throw FormatException(
        'SessionState expected $sessionStateLength bytes, got ${bytes.length}',
      );
    }
    final bd = ByteData.sublistView(bytes);
    return SessionStateNotify(
      state: AnchorSessionState.values[bd.getUint8(0).clamp(0, 3)],
      lastErrorCode: bd.getUint8(1),
      uptimeSeconds: bd.getUint16(2, Endian.little),
    );
  }
}

enum AnchorSessionState { idle, armed, active, error }

class SessionStateNotify {
  const SessionStateNotify({
    required this.state,
    required this.lastErrorCode,
    required this.uptimeSeconds,
  });

  final AnchorSessionState state;
  final int lastErrorCode;
  final int uptimeSeconds;
}
