// lib/screens/panel/logopeda_videos_screen.dart
import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class LogopedaVideosScreen extends StatelessWidget {
  final AppUser user;
  const LogopedaVideosScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vídeos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_rounded),
            tooltip: 'Subir vídeo',
            onPressed: () {
              // TODO: NavegaR a SubirVideoScreen
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Vídeos subidos aparecerán aquí.',
            style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
