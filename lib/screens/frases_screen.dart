import "package:flutter/material.dart";
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import "../models/app_user.dart";
import '../models/app_settings.dart';
import '../models/frase_item.dart';
import '../services/settings_service.dart';
import '../services/tts_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class FrasesScreen extends StatefulWidget {
  final AppSettings settings;
  final AppUser? user;
  const FrasesScreen({super.key, required this.settings, this.user});

  @override
  State<FrasesScreen> createState() => _FrasesScreenState();
}

class _FrasesScreenState extends State<FrasesScreen> {
  late final TtsService _tts;
  final SettingsService _settingsSvc = SettingsService();

  String _categoriaActiva = 'Todas';
  List<FraseItem> _frasesPersonales = [];

  // Índice de la frase que está siendo procesada/reproducida ahora mismo
  // null = ninguna activa
  int? _activeIndex;

  @override
  void initState() {
    super.initState();
    _tts = TtsService();
    _tts.onError = (msg) {
      if (mounted) {
        setState(() => _activeIndex = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.warn.withValues(alpha: 0.9),
        ));
      }
    };
    _tts.onDone = () {
      if (mounted) setState(() => _activeIndex = null);
    };
    _tts.init();
    _loadFrases();
  }

  Future<void> _loadFrases() async {
    final list = await _settingsSvc.loadFrasesPersonales();
    if (mounted) setState(() => _frasesPersonales = list);
  }

  // Índice de la frase que está siendo preparada para compartir
  int? _sharingIndex;

  Future<void> _compartirAudio(int index, String texto) async {
    // Solo si hay voz clonada disponible
    if (widget.user?.token == null || !(widget.user?.hasVoice ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Necesitas tener una voz clonada para compartir audio'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    if (_sharingIndex != null) return; // ya hay una compartición en curso

    setState(() => _sharingIndex = index);

    try {
      final api = VoiceApiService();
      final bytes = await api.synthesize(
        token: widget.user!.token!,
        text: texto,
        speed: (widget.settings.velocidad + 0.5).clamp(0.5, 2.0),
      );

      // Guardar en archivo temporal
      final dir = await getTemporaryDirectory();
      final safeNombre = texto
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim()
          .replaceAll(' ', '_')
          .substring(0, texto.length.clamp(0, 30));
      final file = File('${dir.path}/voz_$safeNombre.mp3');
      await file.writeAsBytes(bytes);

      if (!mounted) return;

      // Compartir con sheet nativo (permite elegir WhatsApp u otras apps)
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'audio/mpeg')],
        text: texto,
        subject: 'Audio generado por mi voz',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al generar audio: $e'),
          backgroundColor: AppColors.warn.withValues(alpha: 0.9),
        ));
      }
    } finally {
      if (mounted) setState(() => _sharingIndex = null);
    }
  }

  Future<void> _hablar(int index, String texto) async {
    // Si ya hay algo activo, ignorar el tap (el TtsService también lo bloquea)
    if (_activeIndex != null) return;

    setState(() => _activeIndex = index);

    final ok = await _tts.speak(
      text: texto,
      settings: widget.settings,
      userToken: widget.user?.token,
      hasVoice: widget.user?.hasVoice ?? false,
    );

    // Si speak devolvió false (bloqueado internamente), limpiamos igualmente
    if (!ok && mounted) setState(() => _activeIndex = null);
  }

  List<FraseItem> get _frasesVisibles {
    final todas = [...frasesDefault, ..._frasesPersonales];
    if (_categoriaActiva == 'Todas') return todas;
    if (_categoriaActiva == 'Mis frases') return _frasesPersonales;
    return todas.where((f) => f.categoria == _categoriaActiva).toList();
  }

  void _mostrarDialogoAdd() {
    final controller = TextEditingController();
    String catSel = 'Mis frases';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Nueva frase',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              AccentTextField(
                controller: controller,
                hint: 'Escribe la frase...',
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              const SectionLabel('Categoría',
                  padding: EdgeInsets.only(bottom: 10)),
              ChipRow(
                options: const [
                  'Mis frases', 'Saludos', 'Necesidades', 'Respuestas', 'Urgente'
                ],
                selected: catSel,
                onSelect: (c) => setModal(() => catSel = c),
                colorOf: AppColors.catColor,
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Guardar frase',
                onTap: () {
                  final texto = controller.text.trim();
                  if (texto.isEmpty) return;
                  final nueva = FraseItem(
                      texto: texto, categoria: catSel, esPersonal: true);
                  final updated = [..._frasesPersonales, nueva];
                  setState(() => _frasesPersonales = updated);
                  _settingsSvc.saveFrasesPersonales(updated);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarEliminar(FraseItem frase) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Eliminar frase',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '"${frase.texto}"',
          style: const TextStyle(color: AppColors.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () {
              final updated =
              _frasesPersonales.where((f) => f != frase).toList();
              setState(() => _frasesPersonales = updated);
              _settingsSvc.saveFrasesPersonales(updated);
              Navigator.pop(context);
            },
            child:
            const Text('Eliminar', style: TextStyle(color: AppColors.warn)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frases = _frasesVisibles;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Frases rápidas'),
        actions: [
          // Indicador global de que hay síntesis en curso
          if (_activeIndex != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sintetizando...',
                        style: TextStyle(
                            color: AppColors.accent.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      if (widget.user?.hasVoice ?? false)
                        Text(
                          'puede tardar hasta 60s',
                          style: TextStyle(
                              color: AppColors.textDim,
                              fontSize: 10),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ChipRow(
              options: categoriasAll,
              selected: _categoriaActiva,
              onSelect: (c) => setState(() => _categoriaActiva = c),
              colorOf: AppColors.catColor,
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          Expanded(
            child: frases.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      color: AppColors.textDim, size: 44),
                  SizedBox(height: 12),
                  Text('No hay frases en esta categoría',
                      style: TextStyle(
                          color: AppColors.textDim, fontSize: 14)),
                ],
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.65,
              ),
              itemCount: frases.length,
              itemBuilder: (_, i) {
                final frase = frases[i];
                final isActive = _activeIndex == i;
                final isBusy = _activeIndex != null && !isActive;
                return _FraseTile(
                  frase: frase,
                  isActive: isActive,
                  isBusy: isBusy,
                  isSharing: _sharingIndex == i,
                  onTap: () => _hablar(i, frase.texto),
                  onShare: (widget.user?.hasVoice ?? false)
                      ? () => _compartirAudio(i, frase.texto)
                      : null,
                  onLongPress: frase.esPersonal
                      ? () => _confirmarEliminar(frase)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoAdd,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bg,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

// ── Frase tile ────────────────────────────────────────────────────
class _FraseTile extends StatefulWidget {
  final FraseItem frase;
  final bool isActive; // esta tile está siendo sintetizada/reproducida
  final bool isBusy;  // otra tile está activa (esta queda bloqueada)
  final bool isSharing; // generando audio para compartir
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onShare; // null = sin voz clonada

  const _FraseTile({
    required this.frase,
    required this.isActive,
    required this.isBusy,
    required this.isSharing,
    required this.onTap,
    this.onLongPress,
    this.onShare,
  });

  @override
  State<_FraseTile> createState() => _FraseTileState();
}

class _FraseTileState extends State<_FraseTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
    _scale = Tween(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _accent => AppColors.catColor(widget.frase.categoria);

  @override
  Widget build(BuildContext context) {
    // Opacidad reducida si otra tile está activa
    final opacity = widget.isBusy ? 0.4 : 1.0;

    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTapDown: widget.isBusy ? null : (_) => _ctrl.forward(),
        onTapUp: widget.isBusy
            ? null
            : (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: widget.isBusy ? null : () => _ctrl.reverse(),
        onLongPress: widget.isBusy ? null : widget.onLongPress,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? _accent.withValues(alpha: 0.15)  // fondo iluminado cuando activa
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.isActive
                    ? _accent.withValues(alpha: 0.8)  // borde más vivo cuando activa
                    : _accent.withValues(alpha: 0.3),
                width: widget.isActive ? 1.5 : 1,
              ),
            ),
            child: Stack(
              children: [
                // Left accent bar
                Positioned(
                  left: 0, top: 8, bottom: 8,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // ── Icono compartir (avión) — esquina superior izquierda ──
                if (widget.onShare != null)
                  Positioned(
                    top: 5, left: 7,
                    child: GestureDetector(
                      onTap: widget.isBusy || widget.isSharing
                          ? null
                          : widget.onShare,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: widget.isSharing
                            ? SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: _accent.withValues(alpha: 0.7),
                          ),
                        )
                            : Icon(
                          Icons.send_rounded,
                          size: 13,
                          color: _accent.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ),
                // Spinner cuando esta tile es la activa
                if (widget.isActive)
                  Positioned(
                    top: 8, right: 8,
                    child: SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: _accent,
                      ),
                    ),
                  )
                // Estrella personal (solo si no está activa)
                else if (widget.frase.esPersonal)
                  Positioned(
                    top: 8, right: 8,
                    child: Icon(Icons.star_rounded,
                        size: 12, color: _accent.withValues(alpha: 0.6)),
                  ),
                // Text
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                  child: Center(
                    child: Text(
                      widget.frase.texto,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.isActive
                            ? AppColors.textPrimary
                            : AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}