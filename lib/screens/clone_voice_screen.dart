import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CloneVoiceScreen extends StatefulWidget {
  final String token;
  final bool alreadyHasVoice;
  final Future<void> Function(Uint8List bytes, String filename) onUpload;
  final Future<void> Function() onDelete;
  final VoidCallback onDone;

  const CloneVoiceScreen({
    super.key,
    required this.token,
    required this.alreadyHasVoice,
    required this.onUpload,
    required this.onDelete,
    required this.onDone,
  });

  @override
  State<CloneVoiceScreen> createState() => _CloneVoiceScreenState();
}

class _CloneVoiceScreenState extends State<CloneVoiceScreen> {
  late bool _hasVoice;
  bool _uploading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _hasVoice = widget.alreadyHasVoice;
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3', 'm4a', 'ogg'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    setState(() { _uploading = true; _error = null; _success = null; });

    try {
      await widget.onUpload(file.bytes!, file.name);
      setState(() { _hasVoice = true; _success = '✅ ¡Voz clonada correctamente!'; });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Eliminar voz',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('¿Seguro que quieres eliminar tu voz clonada?',
            style: TextStyle(color: AppColors.textMid)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textDim))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: AppColors.warn))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.onDelete();
      setState(() { _hasVoice = false; _success = 'Voz eliminada'; });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Mi voz clonada'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onDone,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_hasVoice ? AppColors.teal : AppColors.accent)
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (_hasVoice ? AppColors.teal : AppColors.accent)
                      .withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasVoice
                        ? Icons.check_circle_outline
                        : Icons.mic_none_rounded,
                    color: _hasVoice ? AppColors.teal : AppColors.accent,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _hasVoice
                          ? 'Tienes una voz clonada activa.\nSolo tú puedes usarla.'
                          : 'No tienes voz clonada aún.\nSube un audio para empezar.',
                      style: TextStyle(
                        color: _hasVoice ? AppColors.teal : AppColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text('Instrucciones',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            const Text(
              '• Graba o busca un audio tuyo hablando con claridad\n'
              '• Duración ideal: 30 segundos — 2 minutos\n'
              '• Sin música ni ruido de fondo\n'
              '• Formatos: WAV, MP3, M4A, OGG (máx. 20MB)',
              style: TextStyle(
                  color: AppColors.textMid, fontSize: 13, height: 1.8),
            ),
            const SizedBox(height: 28),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(_error!,
                    style: const TextStyle(
                        color: AppColors.warn, fontSize: 13)),
              ),
            if (_success != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(_success!,
                    style: const TextStyle(
                        color: AppColors.teal, fontSize: 13)),
              ),

            // Botón subir
            _BigButton(
              label: _hasVoice ? 'Reemplazar voz' : 'Seleccionar audio y clonar',
              icon: Icons.upload_file_rounded,
              color: AppColors.accent,
              loading: _uploading,
              onTap: _pickAndUpload,
            ),

            if (_hasVoice) ...[
              const SizedBox(height: 12),
              _BigButton(
                label: 'Eliminar voz clonada',
                icon: Icons.delete_outline_rounded,
                color: AppColors.warn,
                loading: false,
                onTap: _delete,
                outline: true,
              ),
            ],

            const Spacer(),
            if (_hasVoice)
              Center(
                child: TextButton(
                  onPressed: widget.onDone,
                  child: const Text('← Volver a la app',
                      style: TextStyle(color: AppColors.accent, fontSize: 15)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final bool outline;
  final VoidCallback onTap;

  const _BigButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: outline ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(12),
          border: outline ? Border.all(color: color.withOpacity(0.5)) : null,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: outline ? color : Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(label,
                        style: TextStyle(
                            color: outline ? color : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
        ),
      ),
    );
  }
}
