import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../uwb/uwb_models.dart';
import 'log_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _capabilitiesJson;
  bool _showAdvanced = false;

  Future<void> _runCapabilityCheck() async {
    try {
      final caps = await ref.read(uwbServiceProvider).getCapabilities();
      setState(() {
        _capabilitiesJson = const JsonEncoder.withIndent('  ').convert(
          caps.toJson(),
        );
      });
    } catch (e) {
      setState(() => _capabilitiesJson = 'error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: '로그',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LogScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Section(title: '채널 우선순위'),
          SegmentedButton<List<int>>(
            segments: const [
              ButtonSegment(value: [9, 5], label: Text('9 → 5')),
              ButtonSegment(value: [5, 9], label: Text('5 → 9')),
              ButtonSegment(value: [9], label: Text('9만')),
              ButtonSegment(value: [5], label: Text('5만')),
            ],
            selected: {_matchPreset(settings.preferredChannels)},
            onSelectionChanged: (sel) {
              notifier.update(
                (s) => s.copyWith(preferredChannels: sel.first),
              );
            },
          ),
          const SizedBox(height: 24),
          const _Section(title: 'Update Rate'),
          SegmentedButton<RangingUpdateRate>(
            segments: const [
              ButtonSegment(
                value: RangingUpdateRate.automatic,
                label: Text('Auto'),
              ),
              ButtonSegment(
                value: RangingUpdateRate.infrequent,
                label: Text('Infrequent'),
              ),
              ButtonSegment(
                value: RangingUpdateRate.fast,
                label: Text('Fast'),
              ),
            ],
            selected: {settings.updateRate},
            onSelectionChanged: (sel) {
              notifier.update((s) => s.copyWith(updateRate: sel.first));
            },
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            value: _showAdvanced,
            title: const Text('고급 설정 표시'),
            onChanged: (v) => setState(() => _showAdvanced = v),
          ),
          if (_showAdvanced) ...[
            _NumField(
              label: 'Slot duration (ms)',
              value: settings.slotDurationMs,
              min: 1,
              max: 12,
              onChanged: (v) =>
                  notifier.update((s) => s.copyWith(slotDurationMs: v)),
            ),
            _NumField(
              label: 'Ranging interval (ms)',
              value: settings.rangingIntervalMs,
              min: 50,
              max: 2000,
              step: 50,
              onChanged: (v) =>
                  notifier.update((s) => s.copyWith(rangingIntervalMs: v)),
            ),
            _NumField(
              label: 'Preamble index 강제',
              value: settings.preambleIndexOverride ?? 0,
              min: 0,
              max: 32,
              onChanged: (v) {
                notifier.update(
                  (s) => v == 0
                      ? s.copyWith(clearPreambleOverride: true)
                      : s.copyWith(preambleIndexOverride: v),
                );
              },
              helper: '0 = 자동 (anchor가 보고한 최소값 사용)',
            ),
          ],
          const SizedBox(height: 32),
          const _Section(title: 'UWB capability check'),
          FilledButton.tonal(
            onPressed: _runCapabilityCheck,
            child: const Text('Capability 확인'),
          ),
          if (_capabilitiesJson != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _capabilitiesJson!,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<int> _matchPreset(List<int> v) {
    const presets = [
      [9, 5],
      [5, 9],
      [9],
      [5],
    ];
    for (final p in presets) {
      if (p.length == v.length &&
          List.generate(p.length, (i) => p[i] == v[i])
              .every((b) => b)) {
        return p;
      }
    }
    return [9, 5];
  }
}

class _Section extends StatelessWidget {
  // ignore: unused_element_parameter
  const _Section({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.helper,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                if (helper != null)
                  Text(
                    helper!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value - step >= min
                ? () => onChanged(value - step)
                : null,
          ),
          SizedBox(
            width: 56,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: value + step <= max
                ? () => onChanged(value + step)
                : null,
          ),
        ],
      ),
    );
  }
}
