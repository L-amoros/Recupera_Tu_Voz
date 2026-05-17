// lib/screens/trabajo_screen.dart
//
// Pestaña "Trabajo" del paciente: fichas asignadas por el logopeda.

import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/roles_service.dart';
import '../theme/app_theme.dart';

class TrabajoScreen extends StatefulWidget {
  final AppUser user;
  const TrabajoScreen({super.key, required this.user});

  @override
  State<TrabajoScreen> createState() => _TrabajoScreenState();
}

class _TrabajoScreenState extends State<TrabajoScreen> {
  AdaptiveColors get c => AdaptiveColors.of(context);

  List<FichaAsignada> _fichas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await RolesService(widget.user.token).getMisFichas();
      if (mounted) setState(() { _fichas = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Mi trabajo'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: c.textDim),
              const SizedBox(height: 12),
              Text('Error al cargar', style: TextStyle(color: c.textPrimary, fontSize: 16)),
              const SizedBox(height: 6),
              Text(_error!, textAlign: TextAlign.center,
                  style: TextStyle(color: c.textDim, fontSize: 12)),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    if (_fichas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_outlined, size: 64, color: c.textDim),
              const SizedBox(height: 16),
              Text('Sin fichas asignadas',
                  style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'Tu logopeda todavía no te ha asignado ninguna ficha de trabajo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textDim, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    // Separar pendientes y completadas
    final pendientes  = _fichas.where((f) => !f.completada).toList();
    final completadas = _fichas.where((f) => f.completada).toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: c.accent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pendientes.isNotEmpty) ...[
            _SectionHeader('Pendientes (${pendientes.length})', c),
            const SizedBox(height: 8),
            ...pendientes.map((f) => _FichaTile(ficha: f, onTap: () => _abrirFicha(f))),
            const SizedBox(height: 20),
          ],
          if (completadas.isNotEmpty) ...[
            _SectionHeader('Completadas (${completadas.length})', c),
            const SizedBox(height: 8),
            ...completadas.map((f) => _FichaTile(ficha: f, onTap: () => _abrirFicha(f))),
          ],
        ],
      ),
    );
  }

  void _abrirFicha(FichaAsignada ficha) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FichaDetalleScreen(ficha: ficha),
    ));
  }
}

// ── Ficha tile ────────────────────────────────────────────────────

class _FichaTile extends StatelessWidget {
  final FichaAsignada ficha;
  final VoidCallback onTap;
  const _FichaTile({required this.ficha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final completada = ficha.completada;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: completada ? c.teal.withValues(alpha: 0.4) : c.border,
          ),
        ),
        child: Row(
          children: [
            // Icono estado
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: (completada ? c.teal : c.accent).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                completada ? Icons.check_circle_rounded : Icons.assignment_rounded,
                color: completada ? c.teal : c.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ficha.name,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _MiniChip('Nv. ${ficha.level}', c.accent),
                      const SizedBox(width: 6),
                      _MiniChip('${ficha.words.length} palabras', c.textDim),
                      if (ficha.bestScore != null) ...[
                        const SizedBox(width: 6),
                        _MiniChip(
                          '${(ficha.bestScore! * 100).round()}%',
                          ficha.bestScore! >= ficha.successThreshold ? c.teal : c.gold,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Asignada el ${_fmt(ficha.assignedAt)}',
                    style: TextStyle(color: c.textDim, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textDim, size: 18),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
  }
}

// ── Detalle ficha ─────────────────────────────────────────────────

class _FichaDetalleScreen extends StatelessWidget {
  final FichaAsignada ficha;
  const _FichaDetalleScreen({required this.ficha});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(ficha.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Cabecera info ────────────────────────────────────
          Row(
            children: [
              _InfoChip(icon: Icons.bar_chart_rounded, label: 'Nivel ${ficha.level}', color: c.accent),
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.list_alt_rounded, label: '${ficha.words.length} palabras', color: c.textMid),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.flag_rounded,
                label: '${(ficha.successThreshold * 100).round()}% mín.',
                color: c.gold,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Instrucciones ────────────────────────────────────
          if (ficha.instructions != null && ficha.instructions!.isNotEmpty) ...[
            Text('Instrucciones',
                style: TextStyle(color: c.textMid, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.accent.withValues(alpha: 0.2)),
              ),
              child: Text(
                ficha.instructions!,
                style: TextStyle(color: c.textPrimary, fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Palabras ─────────────────────────────────────────
          Text('Palabras a practicar',
              style: TextStyle(color: c.textMid, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ficha.words.map((w) => _PalabraChip(word: w, c: c)).toList(),
          ),
          const SizedBox(height: 24),

          // ── Estado ───────────────────────────────────────────
          if (ficha.completada) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.teal.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: c.teal, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ficha completada',
                            style: TextStyle(color: c.teal, fontWeight: FontWeight.w700)),
                        if (ficha.bestScore != null)
                          Text(
                            'Mejor puntuación: ${(ficha.bestScore! * 100).round()}%',
                            style: TextStyle(color: c.teal, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Botón practicar (placeholder — conectar con ejercicios en el futuro)
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Modo ejercicio próximamente')),
                );
              },
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Empezar a practicar'),
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.bg,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  final AdaptiveColors c;
  const _SectionHeader(this.text, this.c);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: c.textMid, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4),
  );
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _PalabraChip extends StatelessWidget {
  final String word;
  final AdaptiveColors c;
  const _PalabraChip({required this.word, required this.c});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: c.border),
    ),
    child: Text(
      word,
      style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
    ),
  );
}