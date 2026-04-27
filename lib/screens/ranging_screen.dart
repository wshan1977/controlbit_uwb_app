import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ranging_sample.dart';
import '../models/session_state.dart';
import '../state/providers.dart';
import '../widgets/aoa_compass.dart';
import '../widgets/distance_gauge.dart';
import '../widgets/distance_sparkline.dart';

class RangingScreen extends ConsumerStatefulWidget {
  const RangingScreen({super.key});

  @override
  ConsumerState<RangingScreen> createState() => _RangingScreenState();
}

class _RangingScreenState extends ConsumerState<RangingScreen> {
  static const _windowSize = 50;
  static const _sparklineDuration = Duration(seconds: 60);

  final List<RangingSample> _window = [];
  final List<RangingSample> _sparkBuffer = [];

  void _onSample(RangingSample s) {
    _window.add(s);
    if (_window.length > _windowSize) {
      _window.removeAt(0);
    }
    _sparkBuffer.add(s);
    final cutoff =
        s.timestampMs - _sparklineDuration.inMilliseconds;
    while (_sparkBuffer.isNotEmpty &&
        _sparkBuffer.first.timestampMs < cutoff) {
      _sparkBuffer.removeAt(0);
    }
    setState(() {});
  }

  Future<void> _stop() async {
    await ref.read(orchestratorProvider.notifier).stop();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<RangingSample>>(
      orchestratorSamplesProvider,
      (_, next) => next.whenData(_onSample),
    );
    final status = ref.watch(orchestratorProvider);
    final latest = _window.isEmpty ? null : _window.last;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UWB Ranging'),
        actions: [
          IconButton(
            tooltip: '중지',
            icon: const Icon(Icons.stop_circle_outlined),
            onPressed: _stop,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusPill(state: status.state, error: status.errorMessage),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: DistanceGauge(latest: latest, recent: _window),
                ),
              ),
              if (latest?.azimuthDeg != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: AoaCompass(
                    azimuthDeg: latest!.azimuthDeg!,
                    elevationDeg: latest.elevationDeg,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              DistanceSparkline(samples: _sparkBuffer),
              const SizedBox(height: 12),
              Text(
                'samples=${_window.length}'
                '${latest?.rssiDbm != null ? "  rssi=${latest!.rssiDbm} dBm" : ""}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.state, this.error});
  final SessionState state;
  final String? error;

  Color _bg(ColorScheme c) => switch (state) {
        SessionState.ranging => c.primaryContainer,
        SessionState.armed => c.secondaryContainer,
        SessionState.error => c.errorContainer,
        SessionState.idle => c.surfaceContainerHighest,
        _ => c.tertiaryContainer,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _bg(theme.colorScheme),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(state == SessionState.error
              ? Icons.error_outline
              : Icons.bolt),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error == null ? state.label : '${state.label}: $error',
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
