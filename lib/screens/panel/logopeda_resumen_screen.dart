// lib/screens/panel/logopeda_resumen_screen.dart

import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/roles_service.dart';
import '../../theme/app_theme.dart';

class LogopedaResumenScreen extends StatefulWidget {
  final AppUser user;
  const LogopedaResumenScreen({super.key, required this.user});

  @override
  State<LogopedaResumenScreen> createState() => _LogopedaResumenScreenState();
}

class _LogopedaResumenScreenState extends State<LogopedaResumenScreen> {
  AdaptiveColors get c => AdaptiveColors.of(context);

  List<PacienteInfo> _pacientes = [];
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
      final data = await RolesService(widget.user.token).getMisPacientes();
      if (mounted) setState(() { _pacientes = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Resumen'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: c.textDim),
            const SizedBox(height: 12),
            Text('Error al cargar', style: TextStyle(color: c.textPrimary)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_pacientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 64, color: c.textDim),
            const SizedBox(height: 16),
            Text('Sin datos todavía',
                style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Aquí verás el progreso de tus pacientes.',
                style: TextStyle(color: c.textDim, fontSize: 14)),
          ],
        ),
      );
    }

    // ── Estadísticas globales ─────────────────────────────────────
    final total       = _pacientes.length;
    final conVoz      = _pacientes.where((p) => p.hasVoice).length;
    final mediaRacha  = _pacientes.isEmpty ? 0.0
        : _pacientes.map((p) => p.streakDays).reduce((a, b) => a + b) / total;
    final mediaLevel  = _pacientes.isEmpty ? 0.0
        : _pacientes.map((p) => p.currentLevel).reduce((a, b) => a + b) / total;
    final sinTipoVoz  = _pacientes.where((p) => p.voiceType == null).length;

    return RefreshIndicator(
      onRefresh: _load,
      color: c.accent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Cards de resumen ──────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: [
              _StatCard(
                icon: Icons.people_rounded,
                label: 'Pacientes',
                value: '$total',
                color: c.accent,
              ),
              _StatCard(
                icon: Icons.graphic_eq_rounded,
                label: 'Con voz clonada',
                value: '$conVoz / $total',
                color: c.teal,
              ),
              _StatCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Racha media',
                value: '${mediaRacha.toStringAsFixed(1)}d',
                color: c.gold,
              ),
              _StatCard(
                icon: Icons.bar_chart_rounded,
                label: 'Nivel medio',
                value: mediaLevel.toStringAsFixed(1),
                color: c.purple,
              ),
            ],
          ),

          if (sinTipoVoz > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: c.gold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$sinTipoVoz paciente${sinTipoVoz != 1 ? 's' : ''} sin tipo de voz asignado.',
                      style: TextStyle(color: c.gold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Lista individual ──────────────────────────────────
          Text('Detalle por paciente',
              style: TextStyle(color: c.textMid, fontSize: 12,
                  fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          const SizedBox(height: 10),

          ..._pacientes.map((p) => _PacienteRow(p: p)),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
              Text(label, style: TextStyle(color: c.textDim, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PacienteRow extends StatelessWidget {
  final PacienteInfo p;
  const _PacienteRow({required this.p});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final inicial = p.name.isNotEmpty ? p.name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: p.picture != null ? NetworkImage(p.picture!) : null,
            backgroundColor: c.accent.withValues(alpha: 0.15),
            child: p.picture == null
                ? Text(inicial, style: TextStyle(color: c.accent, fontSize: 14, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name.isNotEmpty ? p.name : p.email,
                    style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                if (p.voiceType != null)
                  Text(
                    p.voiceType == 'esofagico' ? 'Esofágica' : 'Electrolaringe',
                    style: TextStyle(color: c.textDim, fontSize: 11),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Mini('Nv. ${p.currentLevel}', c.accent),
              const SizedBox(height: 3),
              _Mini('${p.streakDays}d 🔥', c.gold),
              if (p.hasVoice) ...[
                const SizedBox(height: 3),
                _Mini('Voz ✓', c.teal),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final Color color;
  const _Mini(this.label, this.color);

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
  );
}