import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/anchor_device.dart';
import '../models/ranging_sample.dart';
import '../models/settings.dart';
import '../services/ble_service.dart';
import '../services/log_service.dart';
import '../services/permission_service.dart';
import '../services/session_orchestrator.dart';
import '../services/uwb_service.dart';

final permissionServiceProvider = Provider((ref) => PermissionService());

final bleServiceProvider = Provider<BleService>((ref) {
  final svc = BleService();
  ref.onDispose(svc.dispose);
  return svc;
});

final uwbServiceProvider = Provider((ref) => UwbService());

final logServiceProvider = Provider((ref) => LogService());

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void update(AppSettings Function(AppSettings) mutator) {
    state = mutator(state);
  }
}

final scanResultsProvider = StreamProvider<List<AnchorDevice>>((ref) {
  return ref.watch(bleServiceProvider).scanResults;
});

final orchestratorProvider =
    NotifierProvider<SessionOrchestrator, OrchestratorStatus>(
  SessionOrchestrator.new,
);

final orchestratorSamplesProvider = StreamProvider<RangingSample>((ref) {
  final orch = ref.watch(orchestratorProvider.notifier);
  return orch.samples;
});
