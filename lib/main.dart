import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_shell.dart';
import 'app/theme.dart';

void main() {
  runApp(const ProviderScope(child: FajrToIshaApp()));
}

class FajrToIshaApp extends StatelessWidget {
  const FajrToIshaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FajrToIsha',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}