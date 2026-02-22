import "package:flutter/material.dart";
import "../models/app_user.dart";
import '../models/app_settings.dart';
import '../models/frase_item.dart';
import '../services/settings_service.dart';
import '../services/tts_service.dart';
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

  @override
  void initState() {
    super.initState();
    _tts = TtsService();
    _tts.onError = (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.warn.withOpacity(0.9),
          ));
        }
      };
    _tts.init();
    _loadFrases();
  }

  Future<void> _loadFrases() async {
    final list = await _settingsSvc.loadFrasesPersonales();
    if (mounted) setState(() => _frasesPersonales = list);
  }

  Future<void> _hablar(String texto) async {
    await _tts.speak(
      text: texto,
      settings: widget.settings,
      userToken: widget.user?.token,
      hasVoice: widget.user?.hasVoice ?? false,
    );
  }

  List<FraseItem> get _frasesVisibles {
    final todas = [...frasesDefault, ..._frasesPersonales];
    if (_categoriaActiva == 'Todas') return todas;
    if (_categoriaActiva == 'Mis frases') return _frasesPersonales;
    return todas
        .where((f) => f.categoria == _categoriaActiva)
        .toList();
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
              // Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
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
                      texto: texto,
                      categoria: catSel,
                      esPersonal: true);
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
              final updated = _frasesPersonales
                  .where((f) => f != frase)
                  .toList();
              setState(() => _frasesPersonales = updated);
              _settingsSvc.saveFrasesPersonales(updated);
              Navigator.pop(context);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.warn)),
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
      appBar: AppBar(title: const Text('Frases rápidas')),
      body: Column(
        children: [
          // ── Category selector ─────────────────────────
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

          // ── Grid ──────────────────────────────────────
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
                      return _FraseTile(
                        frase: frase,
                        onTap: () => _hablar(frase.texto),
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

// ── Frase tile ────────────────────────────────────────────────────
class _FraseTile extends StatefulWidget {
  final FraseItem frase;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _FraseTile({
    required this.frase,
    required this.onTap,
    this.onLongPress,
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
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _accent.withOpacity(0.3), width: 1),
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
              // Personal star
              if (widget.frase.esPersonal)
                Positioned(
                  top: 8, right: 8,
                  child: Icon(Icons.star_rounded,
                      size: 12,
                      color: _accent.withOpacity(0.6)),
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
                    style: const TextStyle(
                      color: AppColors.textPrimary,
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
    );
  }
}
