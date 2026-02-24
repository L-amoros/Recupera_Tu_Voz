import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../models/voz_emocion.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class TextScreen extends StatefulWidget {
  final AppSettings settings;
  final AppUser? user;
  const TextScreen({super.key, required this.settings, this.user});

  @override
  State<TextScreen> createState() => _TextScreenState();
}

class _TextScreenState extends State<TextScreen> {
  final TextEditingController _controller = TextEditingController();
  late final TtsService _tts;

  bool _isSpeaking = false;
  bool _isLoading = false;
  bool _showControls = false;
  VozEmocion _emocion = VozEmocion.neutral;
  late double _velocidad;
  late double _volumen;

  @override
  void initState() {
    super.initState();
    _velocidad = widget.settings.velocidad;
    _volumen = widget.settings.volumen;
    _tts = TtsService();
    _tts.onDone = () { if (mounted) setState(() => _isSpeaking = false); };
    _tts.onError = (msg) {
      if (!mounted) return;
      setState(() { _isSpeaking = false; _isLoading = false; });
      _showSnack(msg, isError: true);
    };
    _initTts();
  }

  @override
  void didUpdateWidget(TextScreen old) {
    super.didUpdateWidget(old);
    if (old.settings != widget.settings) {
      _velocidad = widget.settings.velocidad;
      _volumen = widget.settings.volumen;
    }
  }

  Future<void> _initTts() async {
    setState(() => _isLoading = true);
    await _tts.init();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _speak() async {
    final text = _controller.text.trim();
    if (text.isEmpty) { _showSnack('Escribe algo primero'); return; }
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }
    setState(() => _isSpeaking = true);
    await _tts.speak(
      text: text,
      settings: widget.settings.copyWith(velocidad: _velocidad, volumen: _volumen),
      userToken: widget.user?.token,
      hasVoice: widget.user?.hasVoice ?? false,
      emocion: _emocion,
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.warn.withValues(alpha: 0.9) : AppColors.surface,
    ));
  }

  @override
  void dispose() { _tts.dispose(); _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final usingClonedVoice = (widget.user?.hasVoice ?? false) && widget.user != null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Texto a voz'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _VoiceEngineBadge(usingClonedVoice: usingClonedVoice),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Lo que quieres decir'),
              const SizedBox(height: 8),
              Container(
                height: 170,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.5),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                    hintText: 'Escribe aquí...',
                    hintStyle: TextStyle(color: AppColors.textDim, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _ControlsToggle(
                open: _showControls,
                emocion: _emocion,
                onTap: () => setState(() => _showControls = !_showControls),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _showControls
                    ? _ControlPanel(
                  velocidad: _velocidad,
                  volumen: _volumen,
                  emocion: _emocion,
                  showVelocidad: !usingClonedVoice,
                  onVelocidadChanged: (v) => setState(() => _velocidad = v),
                  onVolumenChanged: (v) => setState(() => _volumen = v),
                  onEmocionChanged: (e) => setState(() => _emocion = e),
                )
                    : const SizedBox.shrink(),
              ),
              const Spacer(),
              // Mensaje de progreso cuando hay voz clonada (puede tardar)
              if (_isSpeaking && usingClonedVoice)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.accent.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sintetizando con tu voz... puede tardar hasta 60s',
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              Center(
                child: SpeakButton(
                  isSpeaking: _isSpeaking,
                  isLoading: _isLoading,
                  onTap: _speak,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Controls toggle ──────────────────────────────────────────────
class _ControlsToggle extends StatelessWidget {
  final bool open;
  final VozEmocion emocion;
  final VoidCallback onTap;
  const _ControlsToggle({required this.open, required this.emocion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, size: 16, color: AppColors.textMid),
            const SizedBox(width: 8),
            Text('Controles · ${emocion.label}',
                style: const TextStyle(color: AppColors.textMid, fontSize: 13)),
            const Spacer(),
            Icon(open ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textDim, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Control panel ────────────────────────────────────────────────
class _ControlPanel extends StatelessWidget {
  final double velocidad, volumen;
  final VozEmocion emocion;
  final bool showVelocidad;
  final ValueChanged<double> onVelocidadChanged, onVolumenChanged;
  final ValueChanged<VozEmocion> onEmocionChanged;

  const _ControlPanel({
    required this.velocidad, required this.volumen, required this.emocion,
    required this.showVelocidad,
    required this.onVelocidadChanged, required this.onVolumenChanged,
    required this.onEmocionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showVelocidad) ...[
            _SliderRow(
              label: 'Velocidad',
              value: velocidad,
              onChanged: onVelocidadChanged,
            ),
            const SizedBox(height: 4),
          ],
          _SliderRow(label: 'Volumen', value: volumen, onChanged: onVolumenChanged),
          const SizedBox(height: 10),
          const Text('Emoción',
              style: TextStyle(color: AppColors.textMid, fontSize: 12)),
          const SizedBox(height: 6),
          const SizedBox(height: 6),
          ChipRow(
            options: VozEmocion.values.map((e) => e.label).toList(),
            selected: emocion.label,
            onSelect: (label) {
              final e = VozEmocion.values.firstWhere((e) => e.label == label);
              onEmocionChanged(e);
            },
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  const _SliderRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label,
              style: const TextStyle(color: AppColors.textMid, fontSize: 12)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0.1, max: 1.0,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.border,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ── Voice engine badge ───────────────────────────────────────────
class _VoiceEngineBadge extends StatelessWidget {
  final bool usingClonedVoice;
  const _VoiceEngineBadge({required this.usingClonedVoice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: usingClonedVoice
            ? AppColors.teal.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: usingClonedVoice ? AppColors.teal : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            usingClonedVoice ? Icons.graphic_eq_rounded : Icons.speaker_phone_outlined,
            size: 13,
            color: usingClonedVoice ? AppColors.teal : AppColors.textDim,
          ),
          const SizedBox(width: 5),
          Text(
            usingClonedVoice ? 'Mi voz' : 'Sistema',
            style: TextStyle(
              color: usingClonedVoice ? AppColors.teal : AppColors.textDim,
              fontSize: 11, fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}