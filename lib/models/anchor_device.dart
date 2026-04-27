import 'anchor_info.dart';

class AnchorDevice {
  const AnchorDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.info,
  });

  final String id;
  final String name;
  final int rssi;
  final AnchorInfo? info;

  AnchorDevice copyWith({String? name, int? rssi, AnchorInfo? info}) =>
      AnchorDevice(
        id: id,
        name: name ?? this.name,
        rssi: rssi ?? this.rssi,
        info: info ?? this.info,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnchorDevice && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
