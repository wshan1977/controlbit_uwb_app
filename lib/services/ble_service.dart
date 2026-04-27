import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../ble/ble_codec.dart';
import '../ble/ble_uuids.dart';
import '../models/anchor_device.dart';
import '../models/anchor_info.dart';
import '../models/uwb_session_config.dart';

class AnchorConnection {
  AnchorConnection({
    required this.device,
    required this.anchorInfoChar,
    required this.sessionConfigChar,
    required this.sessionStateChar,
    required this.phoneAddressChar,
  });

  final BluetoothDevice device;
  final BluetoothCharacteristic anchorInfoChar;
  final BluetoothCharacteristic sessionConfigChar;
  final BluetoothCharacteristic sessionStateChar;
  final BluetoothCharacteristic phoneAddressChar;
}

class BleService {
  StreamSubscription<List<ScanResult>>? _scanSub;
  final _scanController = StreamController<List<AnchorDevice>>.broadcast();
  final Map<String, AnchorDevice> _byId = {};

  Stream<List<AnchorDevice>> get scanResults => _scanController.stream;

  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    await stopScan();
    _byId.clear();
    _scanController.add(const []);
    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final advertised = r.advertisementData.serviceUuids.any(
          (g) => g.toString().toLowerCase() == BleUuids.service.toLowerCase(),
        );
        if (!advertised) continue;
        final id = r.device.remoteId.str;
        _byId[id] = AnchorDevice(
          id: id,
          name: r.advertisementData.advName.isNotEmpty
              ? r.advertisementData.advName
              : (r.device.platformName.isNotEmpty
                  ? r.device.platformName
                  : id),
          rssi: r.rssi,
        );
      }
      _scanController.add(_byId.values.toList(growable: false));
    });
    await FlutterBluePlus.startScan(
      withServices: [Guid(BleUuids.service)],
      timeout: timeout,
    );
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
  }

  Future<AnchorConnection> connect(AnchorDevice anchor) async {
    final dev = BluetoothDevice.fromId(anchor.id);
    await dev.connect(autoConnect: false, mtu: BleUuids.negotiateMtu);
    final services = await dev.discoverServices();
    final svc = services.firstWhere(
      (s) => s.uuid.toString().toLowerCase() ==
          BleUuids.service.toLowerCase(),
      orElse: () => throw StateError('Anchor service UUID not found'),
    );

    BluetoothCharacteristic find(String uuid) => svc.characteristics.firstWhere(
          (c) => c.uuid.toString().toLowerCase() == uuid.toLowerCase(),
          orElse: () => throw StateError('Characteristic $uuid not found'),
        );

    return AnchorConnection(
      device: dev,
      anchorInfoChar: find(BleUuids.charAnchorInfo),
      sessionConfigChar: find(BleUuids.charSessionConfig),
      sessionStateChar: find(BleUuids.charSessionState),
      phoneAddressChar: find(BleUuids.charPhoneAddress),
    );
  }

  Future<AnchorInfo> readAnchorInfo(AnchorConnection c) async {
    final raw = await c.anchorInfoChar.read();
    return BleCodec.decodeAnchorInfo(Uint8List.fromList(raw));
  }

  Future<void> writePhoneAddress(
    AnchorConnection c,
    Uint8List addr,
  ) async {
    if (addr.length != 2) throw ArgumentError('Phone address must be 2 bytes');
    await c.phoneAddressChar.write(addr, withoutResponse: false);
  }

  Future<void> writeSessionConfig(
    AnchorConnection c,
    UwbSessionConfig cfg,
  ) async {
    final bytes = BleCodec.encodeSessionConfig(cfg);
    await c.sessionConfigChar.write(bytes, withoutResponse: false);
  }

  Stream<SessionStateNotify> subscribeSessionState(AnchorConnection c) async* {
    await c.sessionStateChar.setNotifyValue(true);
    yield* c.sessionStateChar.lastValueStream
        .where((v) => v.length == BleCodec.sessionStateLength)
        .map((v) => BleCodec.decodeSessionState(Uint8List.fromList(v)));
  }

  Future<void> disconnect(AnchorConnection c) async {
    try {
      await c.sessionStateChar.setNotifyValue(false);
    } catch (_) {}
    await c.device.disconnect();
  }

  Future<void> dispose() async {
    await stopScan();
    await _scanController.close();
  }
}
