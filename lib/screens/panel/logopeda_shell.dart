// TODO Implement this library.// lib/screens/panel/logopeda_shell.dart
//
// Shell principal del logopeda. Bottom navigation con 4 tabs:
//   0 - Pacientes    (lista de sus pacientes)
//   1 - Fichas       (gestión de fichas)
//   2 - Vídeos       (gestión de vídeos)
//   3 - Resumen      (progreso general)
//
// El acceso al código de vinculación está en el AppBar de Pacientes.

import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/app_settings.dart';
import 'logopeda_pacientes_screen.dart';
import 'logopeda_fichas_screen.dart';
import 'logopeda_videos_screen.dart';
import 'logopeda_resumen_screen.dart';

class LogopedaShell extends StatefulWidget {
  final AppUser user;
  final AppSettings settings;

  const LogopedaShell({super.key, required this.user, required this.settings});

  @override
  State<LogopedaShell> createState() => _LogopedaShellState();
}

class _LogopedaShellState extends State<LogopedaShell> {
  int _tab = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      LogopedaPacientesScreen(user: widget.user),
      LogopedaFichasScreen(user: widget.user),
      LogopedaVideosScreen(user: widget.user),
      LogopedaResumenScreen(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Pacientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Fichas',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library_rounded),
            label: 'Vídeos',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Resumen',
          ),
        ],
      ),
    );
  }
}
