/// BLE OOB UUIDs for the maUWB_DW3000 anchor.
///
/// Custom 128-bit base: 8E7A0000-4F2D-4D1E-9F6F-1B7D5C9A0000.
/// The 16-bit field varies per characteristic. The anchor firmware MUST
/// register the same UUIDs.
class BleUuids {
  static const service = '8E7A0001-4F2D-4D1E-9F6F-1B7D5C9A0001';
  static const charAnchorInfo = '8E7A0002-4F2D-4D1E-9F6F-1B7D5C9A0002';
  static const charSessionConfig = '8E7A0003-4F2D-4D1E-9F6F-1B7D5C9A0003';
  static const charSessionState = '8E7A0004-4F2D-4D1E-9F6F-1B7D5C9A0004';
  static const charPhoneAddress = '8E7A0005-4F2D-4D1E-9F6F-1B7D5C9A0005';

  /// Negotiated MTU. SessionConfig is 32 bytes; default ATT MTU 23 isn't enough.
  static const negotiateMtu = 100;

  /// Protocol version we speak; firmware must match major version.
  static const protocolVersion = 0x01;
}
