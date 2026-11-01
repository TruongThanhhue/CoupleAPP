import 'package:couple_app/features/auth/presentation/auth_gate.dart';
import 'package:couple_app/core/theme/couple_theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CoupleApp());
}

class CoupleApp extends StatelessWidget {
  const CoupleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Couple App',
      debugShowCheckedModeBanner: false,
      theme: CoupleTheme.light(),
      darkTheme: CoupleTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}
