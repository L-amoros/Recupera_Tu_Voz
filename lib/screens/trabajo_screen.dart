// lib/screens/trabajo_screen.dart
//
// Pestaña "Trabajo" del paciente: fichas asignadas por el logopeda.
// Al pulsar "Practicar" abre una sesión real de ejercicios word-by-word
// usando el router /exercises, y al terminar marca la ficha como completada.

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_user.dart';
import '../services/api_service.dart';
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await RolesService(widget.user.token).getMisFichas();
      if (mounted) setState(() {
        _fichas = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
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
              Text('Error al cargar',
                  style: TextStyle(color: c.textPrimary, fontSize: 16)),
              const SizedBox(height: 6),
              Text(_error!,
                  textAlign: TextAlign.center,
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
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
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

    final pendientes = _fichas.where((f) => !f.completada).toList();
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
            ...pendientes.map((f) => _FichaTile(
                ficha: f,
                onTap: () => _abrirFicha(f))),
            const SizedBox(height: 20),
          ],
          if (completadas.isNotEmpty) ...[
            _SectionHeader('Completadas (${completadas.length})', c),
            const SizedBox(height: 8),
            ...completadas.map((f) => _FichaTile(
                ficha: f,
                onTap: () => _abrirFicha(f))),
          ],
        ],
      ),
    );
  }

  void _abrirFicha(FichaAsignada ficha) async {
    final updated = await Navigator.of(context).push<FichaAsignada>(
      MaterialPageRoute(
        builder: (_) => _FichaDetalleScreen(
          ficha: ficha,
          token: widget.user.token,
        ),
      ),
    );
    // Si el paciente completó la ficha, actualizar la lista local
    if (updated != null && mounted) {
      setState(() {
        final idx = _fichas.indexWhere((f) => f.fichaId == updated.fichaId);
        if (idx != -1) _fichas[idx] = updated;
      });
    }
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                (completada ? c.teal : c.accent).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                completada
                    ? Icons.check_circle_rounded
                    : Icons.assignment_rounded,
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
                        fontWeight: FontWeight.w600),
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
                          ficha.bestScore! >= ficha.successThreshold
                              ? c.teal
                              : c.gold,
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
  final String token;
  const _FichaDetalleScreen({required this.ficha, required this.token});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(ficha.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Cabecera info
          Row(
            children: [
              _InfoChip(
                  icon: Icons.bar_chart_rounded,
                  label: 'Nivel ${ficha.level}',
                  color: c.accent),
              const SizedBox(width: 8),
              _InfoChip(
                  icon: Icons.list_alt_rounded,
                  label: '${ficha.words.length} palabras',
                  color: c.textMid),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.flag_rounded,
                label: '${(ficha.successThreshold * 100).round()}% mín.',
                color: c.gold,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Instrucciones
          if (ficha.instructions != null &&
              ficha.instructions!.isNotEmpty) ...[
            Text('Instrucciones',
                style: TextStyle(
                    color: c.textMid,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
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
                style:
                TextStyle(color: c.textPrimary, fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Palabras
          Text('Palabras a practicar',
              style: TextStyle(
                  color: c.textMid,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
            ficha.words.map((w) => _PalabraChip(word: w, c: c)).toList(),
          ),
          const SizedBox(height: 24),

          // Estado completada
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
                            style: TextStyle(
                                color: c.teal,
                                fontWeight: FontWeight.w700)),
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
            const SizedBox(height: 16),
            // Aunque esté completada, puede volver a practicar para mejorar score
            OutlinedButton.icon(
              onPressed: () => _iniciarPractica(context),
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: const Text('Practicar de nuevo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.accent,
                side: BorderSide(color: c.accent.withValues(alpha: 0.5)),
                minimumSize: const Size(double.infinity, 50),
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ] else ...[
            // Botón practicar — conectado al flujo real
            FilledButton.icon(
              onPressed: () => _iniciarPractica(context),
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Empezar a practicar'),
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.bg,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _iniciarPractica(BuildContext context) async {
    final result = await Navigator.of(context).push<FichaAsignada>(
      MaterialPageRoute(
        builder: (_) => _PracticarScreen(ficha: ficha, token: token),
      ),
    );
    if (result != null && context.mounted) {
      // Volver al listado con la ficha actualizada
      Navigator.of(context).pop(result);
    }
  }
}

// ── Pantalla de práctica ──────────────────────────────────────────
// Flujo: abre sesión → graba cada palabra → cierra sesión → marca ficha completada

class _PracticarScreen extends StatefulWidget {
  final FichaAsignada ficha;
  final String token;
  const _PracticarScreen({required this.ficha, required this.token});

  @override
  State<_PracticarScreen> createState() => _PracticarScreenState();
}

class _PracticarScreenState extends State<_PracticarScreen> {
  AdaptiveColors get c => AdaptiveColors.of(context);

  // Estado de la práctica
  int _wordIndex = 0;
  String? _sessionId;
  bool _recording = false;
  bool _loading = false;
  String? _feedback; // null = sin resultado aún, "ok" / "fallo"
  double? _lastScore;
  final List<double> _scores = [];
  String? _error;

  final AudioRecorder _recorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    _abrirSesion();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Map<String, String> get _h => {
    'Authorization': 'Bearer ${widget.token}',
    'Content-Type': 'application/json',
  };

  Future<void> _abrirSesion() async {
    setState(() => _loading = true);
    try {
      final r = await http
          .post(Uri.parse('$kServerUrl/exercises/sesiones'), headers: _h)
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200 || r.statusCode == 201) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        _sessionId = data['id'] as String;
      } else {
        setState(() => _error = 'No se pudo abrir la sesión (${r.statusCode})');
      }
    } catch (e) {
      setState(() => _error = 'Error de red: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _grabar() async {
    if (_sessionId == null || _recording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de micrófono denegado')),
        );
      }
      return;
    }

    setState(() {
      _recording = true;
      _feedback = null;
      _lastScore = null;
    });

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/intento_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: path);
  }

  Future<void> _detenerYEnviar() async {
    if (!_recording) return;
    setState(() => _recording = false);

    final path = await _recorder.stop();
    if (path == null) return;

    setState(() => _loading = true);
    try {
      // Buscar o crear un ejercicio temporal para esta palabra
      // Usamos el endpoint de intento directo sin exercise_id
      // enviando el audio al endpoint /exercises/sesiones/{id}/intentos
      // con form-data: audio + word
      final word = widget.ficha.words[_wordIndex];

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$kServerUrl/exercises/sesiones/$_sessionId/intentos'),
      )
        ..headers['Authorization'] = 'Bearer ${widget.token}'
        ..fields['word'] = word
        ..files.add(await http.MultipartFile.fromPath('audio', path));

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final score = (data['whisper_score'] as num?)?.toDouble() ?? 0.0;
        final passed = data['passed'] as bool? ?? false;
        _lastScore = score;
        _scores.add(score);
        setState(() => _feedback = passed ? 'ok' : 'fallo');
      } else {
        final err = jsonDecode(res.body);
        setState(() => _feedback = 'error: ${err['detail'] ?? res.statusCode}');
      }
    } catch (e) {
      setState(() => _feedback = 'error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _siguiente() async {
    if (_wordIndex < widget.ficha.words.length - 1) {
      setState(() {
        _wordIndex++;
        _feedback = null;
        _lastScore = null;
      });
    } else {
      await _terminar();
    }
  }

  Future<void> _terminar() async {
    if (_sessionId == null) return;
    setState(() => _loading = true);

    // 1. Cerrar sesión
    try {
      await http
          .patch(
          Uri.parse(
              '$kServerUrl/exercises/sesiones/$_sessionId/cerrar'),
          headers: _h)
          .timeout(const Duration(seconds: 10));
    } catch (_) {}

    // 2. Calcular best_score medio de esta sesión
    double? bestScore;
    if (_scores.isNotEmpty) {
      bestScore = _scores.reduce((a, b) => a + b) / _scores.length;
    }

    // 3. Marcar ficha completada
    FichaAsignada? updated;
    try {
      final res = await RolesService(widget.token)
          .completarFicha(widget.ficha.fichaId, bestScore: bestScore);
      updated = widget.ficha.copyWith(
        completedAt: DateTime.tryParse(res['completed_at'] as String? ?? ''),
        bestScore: (res['best_score'] as num?)?.toDouble(),
      );
    } catch (e) {
      // Si falla completar, igualmente cerramos la pantalla
    }

    if (mounted) {
      setState(() => _loading = false);
      Navigator.of(context).pop(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.ficha.words;
    final word = words[_wordIndex];
    final isLast = _wordIndex == words.length - 1;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Text('Practicando: ${widget.ficha.name}'),
        actions: [
          TextButton(
            onPressed: (_loading || _recording) ? null : _terminar,
            child: Text('Terminar',
                style: TextStyle(
                    color: c.warn, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _loading && _sessionId == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: c.warn, size: 48),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textPrimary)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _abrirSesion,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Progreso
            LinearProgressIndicator(
              value: (_wordIndex + 1) / words.length,
              backgroundColor: c.border,
              valueColor: AlwaysStoppedAnimation(c.accent),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              'Palabra ${_wordIndex + 1} de ${words.length}',
              style: TextStyle(color: c.textDim, fontSize: 12),
            ),
            const Spacer(),

            // Palabra actual
            Text(
              word,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 48,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),

            // Feedback
            if (_feedback != null && !_loading) ...[
              _FeedbackBadge(
                  feedback: _feedback!, score: _lastScore, c: c),
              const SizedBox(height: 24),
            ],

            // Botón grabar / detener
            if (!_loading) ...[
              GestureDetector(
                onTap: _recording ? _detenerYEnviar : _grabar,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _recording
                        ? c.warn.withValues(alpha: 0.15)
                        : c.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _recording ? c.warn : c.accent,
                      width: 2.5,
                    ),
                  ),
                  child: Icon(
                    _recording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: _recording ? c.warn : c.accent,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _recording
                    ? 'Grabando… toca para parar'
                    : _feedback != null
                    ? 'Graba de nuevo o continúa'
                    : 'Toca para grabar',
                style: TextStyle(color: c.textDim, fontSize: 13),
              ),
            ] else ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text('Evaluando…',
                  style: TextStyle(color: c.textDim, fontSize: 13)),
            ],

            const Spacer(),

            // Botón siguiente / terminar
            if (_feedback != null && !_loading)
              FilledButton(
                onPressed: _siguiente,
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.bg,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isLast ? 'Finalizar ficha' : 'Siguiente palabra',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBadge extends StatelessWidget {
  final String feedback;
  final double? score;
  final AdaptiveColors c;
  const _FeedbackBadge(
      {required this.feedback, required this.score, required this.c});

  @override
  Widget build(BuildContext context) {
    final ok = feedback == 'ok';
    final color = ok ? c.teal : c.warn;
    final icon =
    ok ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final label = ok
        ? '¡Correcto! ${score != null ? '${(score! * 100).round()}%' : ''}'
        : 'Inténtalo de nuevo ${score != null ? '(${(score! * 100).round()}%)' : ''}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Widgets compartidos ───────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  final AdaptiveColors c;
  const _SectionHeader(this.text, this.c);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
        color: c.textMid,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4),
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
    child: Text(label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
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
      style: TextStyle(
          color: c.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500),
    ),
  );
}