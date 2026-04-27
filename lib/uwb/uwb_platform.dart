import 'dart:async';

import 'package:flutter/services.dart';

import 'uwb_models.dart';

class UwbPlatform {
  UwbPlatform._();
  static final UwbPlatform instance = UwbPlatform._();

  static const _method = MethodChannel('com.controlbit.app_uwb/uwb');
  static const _event = EventChannel('com.controlbit.app_uwb/uwb/ranging');

  Stream<RangingEvent>? _events;

  Future<bool> isUwbAvailable() async {
    final v = await _method.invokeMethod<bool>('isUwbAvailable');
    return v ?? false;
  }

  Future<UwbCapabilities> getRangingCapabilities() async {
    final raw = await _method.invokeMapMethod<String, dynamic>(
      'getRangingCapabilities',
    );
    return UwbCapabilities.fromMap(raw ?? const <String, dynamic>{});
  }

  Future<Uint8List> getLocalAddress() async {
    final v = await _method.invokeMethod<Uint8List>('getLocalAddress');
    if (v == null || v.length != 2) {
      throw StateError('Unexpected local address length: ${v?.length}');
    }
    return v;
  }

  Future<void> startRanging(UwbStartArgs args) async {
    await _method.invokeMethod<void>('startRanging', args.toMap());
  }

  Future<void> stopRanging() async {
    await _method.invokeMethod<void>('stopRanging');
  }

  Stream<RangingEvent> rangingEvents() {
    return _events ??= _event
        .receiveBroadcastStream()
        .map((dynamic e) => RangingEvent.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .asBroadcastStream();
  }
}
