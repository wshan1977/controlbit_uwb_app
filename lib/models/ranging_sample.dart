class RangingSample {
  const RangingSample({
    required this.timestampMs,
    required this.distanceM,
    this.azimuthDeg,
    this.elevationDeg,
    this.rssiDbm,
    this.status = 0,
  });

  final int timestampMs;
  final double distanceM;
  final double? azimuthDeg;
  final double? elevationDeg;
  final int? rssiDbm;
  final int status;

  Map<String, dynamic> toJson() => {
        't': timestampMs,
        'd': distanceM,
        if (azimuthDeg != null) 'az': azimuthDeg,
        if (elevationDeg != null) 'el': elevationDeg,
        if (rssiDbm != null) 'rssi': rssiDbm,
        'st': status,
      };
}
