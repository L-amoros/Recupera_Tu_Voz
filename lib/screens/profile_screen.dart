import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final AppSettings settings;
  final AppUser user;
  final ValueChanged<AppSettings> onSettingsChanged;
  final VoidCallback onCloneVoice;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.settings,
    required this.user,
    required this.onSettingsChanged,
    required this.onCloneVoice,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AppSettings _settings;
  final SettingsService _svc = SettingsService();

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  void didUpdateWidget(ProfileScreen old) {
    super.didUpdateWidget(old);
    if (old.settings != widget.settings) setState(() => _settings = widget.settings);
  }

  void _update(AppSettings s) {
    setState(() => _settings = s);
    _svc.saveSettings(s);
    widget.onSettingsChanged(s);
  }

  void _showLanguageDialog() {
    const idiomas = ['Español', 'English', 'Français', 'Deutsch', 'Italiano'];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Idioma',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: idiomas
              .map((lang) => RadioListTile<String>(
                    value: lang,
                    groupValue: _settings.idioma,
                    activeColor: AppColors.accent,
                    title: Text(lang,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14)),
                    onChanged: (v) {
                      _update(_settings.copyWith(idioma: v));
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cerrar sesión',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('¿Seguro que quieres cerrar sesión?',
            style: TextStyle(color: AppColors.textMid)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textDim))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onLogout();
              },
              child: const Text('Cerrar sesión',
                  style: TextStyle(color: AppColors.warn))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── Cabecera usuario ──────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: AppColors.accent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name.isEmpty ? 'Sin nombre' : widget.user.name,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(widget.user.email,
                          style: const TextStyle(
                              color: AppColors.textMid, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Mi voz ───────────────────────────────────────────
          SectionLabel('Mi voz'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: widget.onCloneVoice,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.user.hasVoice
                    ? AppColors.teal.withOpacity(0.08)
                    : AppColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.user.hasVoice
                      ? AppColors.teal.withOpacity(0.35)
                      : AppColors.accent.withOpacity(0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.user.hasVoice
                        ? Icons.graphic_eq_rounded
                        : Icons.mic_none_rounded,
                    color: widget.user.hasVoice
                        ? AppColors.teal
                        : AppColors.accent,
                    size: 26,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.hasVoice
                              ? 'Voz clonada activa'
                              : 'Clonar mi voz',
                          style: TextStyle(
                            color: widget.user.hasVoice
                                ? AppColors.teal
                                : AppColors.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.user.hasVoice
                              ? 'Toca para gestionar tu voz'
                              : 'Sube un audio para que la app hable con tu voz',
                          style: const TextStyle(
                              color: AppColors.textMid, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textDim, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Ajustes ───────────────────────────────────────────
          SectionLabel('Ajustes'),
          const SizedBox(height: 8),
          _Tile(
            label: 'Idioma',
            value: _settings.idioma,
            onTap: _showLanguageDialog,
          ),
          const SizedBox(height: 6),
          _SliderTile(
            label: 'Velocidad de voz',
            value: _settings.velocidad,
            min: 0.1, max: 1.0,
            onChanged: (v) => _update(_settings.copyWith(velocidad: v)),
          ),
          const SizedBox(height: 6),
          _SliderTile(
            label: 'Volumen',
            value: _settings.volumen,
            min: 0.1, max: 1.0,
            onChanged: (v) => _update(_settings.copyWith(volumen: v)),
          ),
          const SizedBox(height: 20),

          // ── Sesión ────────────────────────────────────────────
          SectionLabel('Sesión'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _confirmLogout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.logout_rounded, color: AppColors.warn, size: 18),
                  SizedBox(width: 10),
                  Text('Cerrar sesión',
                      style: TextStyle(color: AppColors.warn, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────
class _Tile extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback? onTap;
  const _Tile({required this.label, this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14,
                      fontWeight: FontWeight.w500)),
                  if (value != null)
                    Text(value!, style: const TextStyle(
                        color: AppColors.textMid, fontSize: 12)),
                ]),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.textDim, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  const _SliderTile({required this.label, required this.value,
      required this.min, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 14,
            fontWeight: FontWeight.w500)),
        Slider(
          value: value, min: min, max: max,
          activeColor: AppColors.accent,
          inactiveColor: AppColors.border,
          onChanged: onChanged,
        ),
      ]),
    );
  }
}
