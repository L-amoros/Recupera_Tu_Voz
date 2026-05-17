// lib/screens/panel/logopeda_fichas_screen.dart
import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class LogopedaFichasScreen extends StatelessWidget {
  final AppUser user;
  const LogopedaFichasScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fichas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Nueva ficha',
            onPressed: () {
              // TODO: NavegaR a NuevaFichaScreen
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Fichas creadas aparecerán aquí.',
            style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
