import 'dart:typed_data';

class AnchorInfo {
  const AnchorInfo({
    required this.protocolVersion,
    required this.role,
    required this.anchorShortAddr,
    required this.supportedChannelMask,
    required this.supportedPreambleMin,
    required this.supportedPreambleMax,
    required this.mtuPreference,
    required this.anchorVendorId,
  });

  final int protocolVersion;
  final int role; // 0 = controller (anchor), 1 = controlee
  final Uint8List anchorShortAddr; // 2 bytes LE
  final int supportedChannelMask; // bit5 = ch5, bit9 = ch9
  final int supportedPreambleMin;
  final int supportedPreambleMax;
  final int mtuPreference;
  final Uint8List anchorVendorId; // 8 bytes

  bool supportsChannel(int channel) =>
      (supportedChannelMask & (1 << channel)) != 0;

  /// Returns the preferred channel from [preferredOrder] that the anchor supports,
  /// or null if none of the requested channels are supported.
  int? selectChannel(List<int> preferredOrder) {
    for (final c in preferredOrder) {
      if (supportsChannel(c)) return c;
    }
    return null;
  }
}
