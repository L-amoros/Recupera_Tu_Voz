// lib/screens/panel/logopeda_resumen_screen.dart
import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class LogopedaResumenScreen extends StatelessWidget {
  final AppUser user;
  const LogopedaResumenScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen de pacientes')),
      body: const Center(
        child: Text('Progreso general de todos tus pacientes.',
            style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
