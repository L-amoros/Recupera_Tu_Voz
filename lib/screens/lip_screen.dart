// lib/screens/lip_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/app_user.dart';
import '../theme/app_theme.dart';

class LipScreen extends StatefulWidget {
  final AppUser? user;
  const LipScreen({super.key, this.user});

  @override
  State<LipScreen> createState() => _LipScreenState();
}

class _LipScreenState extends State<LipScreen> with WidgetsBindingObserver {
  AdaptiveColors get c => AdaptiveColors.of(context);

  // ── Cámara ─────────────────────────────────────────────────────
  CameraController? _camCtrl;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;
  bool _recording = false;

  // ── Estado UI ──────────────────────────────────────────────────
  _LipState _state = _LipState.idle;
  String? _errorMsg;

  int _recSeconds = 0;
  static const int _maxSeconds = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camCtrl?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _camCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  // ── Cámara ─────────────────────────────────────────────────────
  Future<void> _initCamera() async {
    final camStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!camStatus.isGranted || !micStatus.isGranted) {
      if (mounted) {
        setState(() => _errorMsg = 'Se necesitan permisos de cámara y micrófono.');
      }
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _errorMsg = 'No se encontraron cámaras.');
        return;
      }

      final front = _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      final ctrl = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await ctrl.initialize();
      if (!mounted) return;

      setState(() {
        _camCtrl = ctrl;
        _cameraReady = true;
      });
    } catch (e) {
      if (mounted) setState(() => _errorMsg = 'Error al iniciar cámara: $e');
    }
  }

  // ── Grabación ──────────────────────────────────────────────────
  Future<void> _startRecording() async {
    if (_camCtrl == null || !_cameraReady || _recording) return;

    setState(() {
      _recording = true;
      _recSeconds = 0;
      _state = _LipState.recording;
      _errorMsg = null;
    });

    await _camCtrl!.startVideoRecording();
    _tickSeconds();
  }

  void _tickSeconds() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !_recording) return;
      setState(() => _recSeconds++);
      if (_recSeconds >= _maxSeconds) {
        _stopAndDiscard();
      } else {
        _tickSeconds();
      }
    });
  }

  Future<void> _stopAndDiscard() async {
    if (!_recording) return;
    setState(() => _recording = false);

    XFile? videoFile;
    try {
      videoFile = await _camCtrl!.stopVideoRecording();
    } catch (_) {
      setState(() => _state = _LipState.idle);
      return;
    }

    // Eliminar el fichero y volver a idle — sin llamada al backend
    try {
      await File(videoFile.path).delete();
    } catch (_) {}

    if (mounted) setState(() => _state = _LipState.idle);
  }

  void _reset() {
    setState(() {
      _state = _LipState.idle;
      _errorMsg = null;
      _recSeconds = 0;
    });
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        title: Text('Lectura de labios', style: TextStyle(color: c.textPrimary)),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (!_cameraReady) {
      return _errorMsg != null
          ? _centeredMessage(icon: Icons.videocam_off, text: _errorMsg!)
          : const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildCameraPreview(),
        const Spacer(),
        _buildControls(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCameraPreview() {
    return AspectRatio(
      aspectRatio: _camCtrl!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CameraPreview(_camCtrl!),
          ),

          // Guía oval
          Positioned(
            bottom: 40,
            child: Container(
              width: 120,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _recording
                      ? c.warn.withValues(alpha: 0.8)
                      : c.accent.withValues(alpha: 0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(60),
              ),
            ),
          ),

          // Badge grabación
          if (_recording)
            Positioned(
              top: 12,
              right: 12,
              child: _RecordingBadge(seconds: _recSeconds, max: _maxSeconds),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return GestureDetector(
      onTapDown: (_) => _startRecording(),
      onTapUp: (_) { if (_recording) _stopAndDiscard(); },
      onTapCancel: () { if (_recording) _stopAndDiscard(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _recording ? 72 : 80,
        height: _recording ? 72 : 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _recording ? c.warn : c.accent,
          boxShadow: [
            BoxShadow(
              color: (_recording ? c.warn : c.accent).withValues(alpha: 0.4),
              blurRadius: _recording ? 20 : 12,
              spreadRadius: _recording ? 4 : 0,
            ),
          ],
        ),
        child: Icon(
          _recording ? Icons.stop : Icons.videocam,
          color: Colors.black,
          size: 32,
        ),
      ),
    );
  }

  Widget _centeredMessage({required IconData icon, required String text}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: c.textDim),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center,
                style: TextStyle(color: c.textMid, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────

enum _LipState { idle, recording }

class _RecordingBadge extends StatelessWidget {
  final int seconds;
  final int max;
  const _RecordingBadge({required this.seconds, required this.max});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, color: Colors.red, size: 8),
          const SizedBox(width: 6),
          Text('$seconds / $max s',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}