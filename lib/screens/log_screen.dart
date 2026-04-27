import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';

class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(logServiceProvider);
    final entries = log.entries.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'JSON 복사',
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: log.exportJson()),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('클립보드에 복사됨')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '비우기',
            onPressed: () {
              log.clear();
              ref.invalidate(logServiceProvider);
            },
          ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(child: Text('로그 없음'))
          : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = entries[i];
                final ts = DateTime.fromMillisecondsSinceEpoch(e.timestampMs);
                return ListTile(
                  dense: true,
                  title: Text('[${e.tag}] ${e.message}'),
                  subtitle: Text(
                    '${ts.hour.toString().padLeft(2, '0')}:'
                    '${ts.minute.toString().padLeft(2, '0')}:'
                    '${ts.second.toString().padLeft(2, '0')}.'
                    '${ts.millisecond.toString().padLeft(3, '0')}  ${e.level}',
                  ),
                );
              },
            ),
    );
  }
}
