import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/anchor_device.dart';
import '../state/providers.dart';
import '../widgets/rssi_bar.dart';
import 'ranging_screen.dart';
import 'settings_screen.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  bool _busy = false;

  Future<void> _toggleScan() async {
    final ble = ref.read(bleServiceProvider);
    if (FlutterBluePlus.isScanningNow) {
      await ble.stopScan();
      setState(() {});
      return;
    }
    setState(() => _busy = true);
    try {
      final perm = ref.read(permissionServiceProvider);
      final granted = await perm.requestRuntimePermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('BLE 권한이 거부되어 스캔할 수 없습니다.')),
          );
        }
        return;
      }
      await ble.startScan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('스캔 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect(AnchorDevice anchor) async {
    final orch = ref.read(orchestratorProvider.notifier);
    await ref.read(bleServiceProvider).stopScan();
    await orch.connectAndStart(anchor);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RangingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncResults = ref.watch(scanResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('UWB Anchor 스캔'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: asyncResults.when(
        loading: () => const _Empty(text: '스캔 시작을 누르세요'),
        error: (e, _) => _Empty(text: '오류: $e'),
        data: (anchors) {
          if (anchors.isEmpty) {
            return const _Empty(text: 'Anchor가 발견되지 않았습니다');
          }
          return ListView.separated(
            itemCount: anchors.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final a = anchors[i];
              return ListTile(
                leading: const Icon(Icons.sensors),
                title: Text(a.name),
                subtitle: Text(a.id),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${a.rssi} dBm'),
                    const SizedBox(width: 8),
                    RssiBar(rssi: a.rssi),
                  ],
                ),
                onTap: () => _connect(a),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _toggleScan,
        icon: Icon(FlutterBluePlus.isScanningNow ? Icons.stop : Icons.search),
        label: Text(FlutterBluePlus.isScanningNow ? '중지' : '스캔 시작'),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
