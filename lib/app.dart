import 'package:flutter/material.dart';

import 'screens/scan_screen.dart';

class UwbTagApp extends StatelessWidget {
  const UwbTagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UWB Tag',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ScanScreen(),
    );
  }
}
