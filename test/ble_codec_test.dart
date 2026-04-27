import 'dart:typed_data';

import 'package:app_uwb/ble/ble_codec.dart';
import 'package:app_uwb/models/uwb_session_config.dart';
import 'package:app_uwb/uwb/uwb_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BleCodec.encodeSessionConfig', () {
    test('produces exactly 32 bytes per spec', () {
      final cfg = UwbSessionConfig(
        sessionId: 0x12345678,
        sessionKey: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
        channel: 9,
        preambleIndex: 11,
        controllerShortAddr: Uint8List.fromList([0xAA, 0xBB]),
        controleeShortAddr: Uint8List.fromList([0xCC, 0xDD]),
        slotDurationMs: 2,
        rangingIntervalMs: 200,
        updateRateType: RangingUpdateRate.automatic,
      );

      final bytes = BleCodec.encodeSessionConfig(cfg);

      expect(bytes.length, 32);
      // protocolVersion=1
      expect(bytes[0], 0x01);
      // uwbConfigId=1 (Static STS Unicast DS-TWR)
      expect(bytes[1], 0x01);
      // sessionId LE u32 at offset 2
      expect(bytes.sublist(2, 6), [0x78, 0x56, 0x34, 0x12]);
      // sessionKey 8 bytes at offset 6
      expect(bytes.sublist(6, 14), [1, 2, 3, 4, 5, 6, 7, 8]);
      expect(bytes[14], 9); // channel
      expect(bytes[15], 11); // preambleIndex
      expect(bytes.sublist(16, 18), [0xAA, 0xBB]);
      expect(bytes.sublist(18, 20), [0xCC, 0xDD]);
      // slotDurationMs LE u16 at 20
      expect(bytes.sublist(20, 22), [2, 0]);
      // rangingIntervalMs LE u32 at 22
      expect(bytes.sublist(22, 26), [200, 0, 0, 0]);
      expect(bytes[26], 0); // updateRateType=AUTOMATIC
      expect(bytes[27], 0); // stsCfg=STATIC_STS
      expect(bytes.sublist(28, 32), [0, 0, 0, 0]);
    });

    test('infrequent and fast update rates encode correctly', () {
      Uint8List enc(RangingUpdateRate r) => BleCodec.encodeSessionConfig(
            UwbSessionConfig(
              sessionId: 0,
              sessionKey: Uint8List(8),
              channel: 5,
              preambleIndex: 9,
              controllerShortAddr: Uint8List(2),
              controleeShortAddr: Uint8List(2),
              slotDurationMs: 0,
              rangingIntervalMs: 0,
              updateRateType: r,
            ),
          );
      expect(enc(RangingUpdateRate.infrequent)[26], 1);
      expect(enc(RangingUpdateRate.fast)[26], 2);
    });
  });

  group('BleCodec.decodeAnchorInfo', () {
    test('decodes a 16-byte fixture', () {
      // supportedChannelMask = u16 LE; bit5(ch5) + bit9(ch9) = 0x0220
      const mask = (1 << 5) | (1 << 9);
      final bytes = Uint8List.fromList([
        0x01, // protocolVersion
        0x00, // role: controller
        0x10, 0x20, // anchorShortAddr LE = 0x2010
        mask & 0xFF, (mask >> 8) & 0xFF, // supportedChannelMask LE
        9, // preamble min
        12, // preamble max
        100, // mtuPreference
        0x4D, 0x46, 0x42, 0x53, 0, 0, 0, // 7-byte vendorId "MFBS\0\0\0"
      ]);
      final info = BleCodec.decodeAnchorInfo(bytes);
      expect(info.protocolVersion, 1);
      expect(info.role, 0);
      expect(info.anchorShortAddr, [0x10, 0x20]);
      expect(info.supportsChannel(5), isTrue);
      expect(info.supportsChannel(9), isTrue);
      expect(info.supportsChannel(7), isFalse);
      expect(info.supportedPreambleMin, 9);
      expect(info.supportedPreambleMax, 12);
      expect(info.mtuPreference, 100);
      expect(info.anchorVendorId, [0x4D, 0x46, 0x42, 0x53, 0, 0, 0]);
    });

    test('throws on wrong length', () {
      expect(
        () => BleCodec.decodeAnchorInfo(Uint8List(15)),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('BleCodec.decodeSessionState', () {
    test('decodes the 4-byte payload', () {
      final n = BleCodec.decodeSessionState(
        Uint8List.fromList([1, 7, 0xD2, 0x04]),
      ); // state=ARMED, err=7, uptime=1234s LE
      expect(n.state, AnchorSessionState.armed);
      expect(n.lastErrorCode, 7);
      expect(n.uptimeSeconds, 1234);
    });
  });
}
