import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_codec.dart';
import '../models/anchor_device.dart';
import '../models/anchor_info.dart';
import '../models/ranging_sample.dart';
import '../models/session_state.dart';
import '../models/settings.dart';
import '../models/uwb_session_config.dart';
import '../state/providers.dart';
import '../uwb/uwb_models.dart';
import 'ble_service.dart';
import 'log_service.dart';
import 'uwb_service.dart';

class OrchestratorStatus {
  const OrchestratorStatus({
    required this.state,
    this.connectedAnchor,
    this.anchorInfo,
    this.activeSessionConfig,
    this.errorMessage,
  });

  final SessionState state;
  final AnchorDevice? connectedAnchor;
  final AnchorInfo? anchorInfo;
  final UwbSessionConfig? activeSessionConfig;
  final String? errorMessage;

  OrchestratorStatus copyWith({
    SessionState? state,
    AnchorDevice? connectedAnchor,
    AnchorInfo? anchorInfo,
    UwbSessionConfig? activeSessionConfig,
    String? errorMessage,
    bool clearError = false,
  }) =>
      OrchestratorStatus(
        state: state ?? this.state,
        connectedAnchor: connectedAnchor ?? this.connectedAnchor,
        anchorInfo: anchorInfo ?? this.anchorInfo,
        activeSessionConfig:
            activeSessionConfig ?? this.activeSessionConfig,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class SessionOrchestrator extends Notifier<OrchestratorStatus> {
  late final BleService _ble = ref.read(bleServiceProvider);
  late final UwbService _uwb = ref.read(uwbServiceProvider);
  late final LogService _log = ref.read(logServiceProvider);
  AppSettings _settings() => ref.read(settingsProvider);

  AnchorConnection? _conn;
  StreamSubscription<SessionStateNotify>? _stateSub;
  StreamSubscription<RangingSample>? _sampleSub;
  final _samples = StreamController<RangingSample>.broadcast();

  Stream<RangingSample> get samples => _samples.stream;

  @override
  OrchestratorStatus build() {
    ref.onDispose(_dispose);
    return const OrchestratorStatus(state: SessionState.idle);
  }

  Future<void> connectAndStart(AnchorDevice anchor) async {
    try {
      _setState(SessionState.connecting, anchor: anchor, clearError: true);
      _log.info('orch', 'Connecting to ${anchor.id}');
      _conn = await _ble.connect(anchor);

      _setState(SessionState.oobExchange);
      final info = await _ble.readAnchorInfo(_conn!);
      _log.info('orch',
          'AnchorInfo: addr=${_hex(info.anchorShortAddr)} '
          'channels=${info.supportedChannelMask.toRadixString(2)}');

      final settings = _settings();
      final channel = info.selectChannel(settings.preferredChannels);
      if (channel == null) {
        throw StateError(
          'Anchor does not support any of the preferred channels: '
          '${settings.preferredChannels}',
        );
      }
      final preamble =
          settings.preambleIndexOverride ?? info.supportedPreambleMin;

      // Push our short address before sending the session config.
      final localAddr = Uint8List.fromList(await _uwb.getLocalAddress());
      await _ble.writePhoneAddress(_conn!, localAddr);

      final config = UwbSessionConfig.generate(
        channel: channel,
        preambleIndex: preamble,
        controllerShortAddr: info.anchorShortAddr,
        controleeShortAddr: localAddr,
        slotDurationMs: settings.slotDurationMs,
        rangingIntervalMs: settings.rangingIntervalMs,
        updateRateType: settings.updateRate,
      );
      await _ble.writeSessionConfig(_conn!, config);

      _stateSub?.cancel();
      _stateSub = _ble.subscribeSessionState(_conn!).listen(_onAnchorState);

      _setState(
        SessionState.oobExchange,
        anchorInfo: info,
        activeSessionConfig: config,
      );
    } catch (e) {
      _log.error('orch', 'Connect/OOB failed: $e');
      _setState(SessionState.error, errorMessage: '$e');
      await _safeDisconnect();
    }
  }

  Future<void> _startUwbWithCurrentConfig() async {
    final cfg = state.activeSessionConfig;
    if (cfg == null) return;
    final args = UwbStartArgs(
      controllerAddress: cfg.controllerShortAddr,
      sessionId: cfg.sessionId,
      sessionKeyInfo: cfg.sessionKey,
      channel: cfg.channel,
      preambleIndex: cfg.preambleIndex,
      uwbConfigId: cfg.uwbConfigId,
      rangingUpdateRate: cfg.updateRateType,
      slotDurationMs: cfg.slotDurationMs,
    );

    _sampleSub?.cancel();
    _sampleSub = _uwb.samples().listen((s) {
      _log.recordSample(s);
      _samples.add(s);
    });

    await _uwb.start(args);
    _setState(SessionState.ranging);
    _log.info('orch',
        'UWB session started: id=${cfg.sessionId} '
        'ch=${cfg.channel} pi=${cfg.preambleIndex}');
  }

  void _onAnchorState(SessionStateNotify n) {
    _log.info('orch', 'Anchor state=${n.state} err=${n.lastErrorCode}');
    switch (n.state) {
      case AnchorSessionState.armed:
        if (state.state == SessionState.oobExchange) {
          _setState(SessionState.armed);
          _startUwbWithCurrentConfig();
        }
        break;
      case AnchorSessionState.active:
        if (state.state != SessionState.ranging) {
          _setState(SessionState.ranging);
        }
        break;
      case AnchorSessionState.error:
        _setState(SessionState.error,
            errorMessage: 'Anchor reported error ${n.lastErrorCode}');
        break;
      case AnchorSessionState.idle:
        if (state.state == SessionState.ranging) {
          stop();
        }
        break;
    }
  }

  Future<void> stop() async {
    _log.info('orch', 'Stopping session');
    await _sampleSub?.cancel();
    _sampleSub = null;
    try {
      await _uwb.stop();
    } catch (_) {}
    await _safeDisconnect();
    _setState(SessionState.idle, clearError: true);
  }

  Future<void> _safeDisconnect() async {
    final c = _conn;
    _conn = null;
    await _stateSub?.cancel();
    _stateSub = null;
    if (c != null) {
      try {
        await _ble.disconnect(c);
      } catch (_) {}
    }
  }

  void _setState(
    SessionState s, {
    AnchorDevice? anchor,
    AnchorInfo? anchorInfo,
    UwbSessionConfig? activeSessionConfig,
    String? errorMessage,
    bool clearError = false,
  }) {
    state = state.copyWith(
      state: s,
      connectedAnchor: anchor,
      anchorInfo: anchorInfo,
      activeSessionConfig: activeSessionConfig,
      errorMessage: errorMessage,
      clearError: clearError,
    );
  }

  Future<void> _dispose() async {
    await _safeDisconnect();
    await _samples.close();
  }
}

String _hex(Uint8List b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
