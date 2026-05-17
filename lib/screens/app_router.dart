// lib/screens/app_router.dart

import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/app_settings.dart';
import '../services/roles_service.dart';
import 'onboarding/role_selection_screen.dart';
import 'panel/logopeda_shell.dart';
import '../main.dart' show AppShell;

class AppRouter extends StatefulWidget {
  final AppUser user;
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final ValueChanged<AppUser> onUserChanged;
  final VoidCallback onLogout;

  const AppRouter({
    super.key,
    required this.user,
    required this.settings,
    required this.onSettingsChanged,
    required this.onUserChanged,
    required this.onLogout,
  });

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  late AppUser _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _fetchRole();
  }

  Future<void> _fetchRole() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final roleInfo = await RolesService(_user.token).getRoleInfo();
      if (!mounted) return;
      setState(() {
        _user = _user.copyWith(
          role:        roleInfo['role']         as String?,
          roleSet:     roleInfo['role_set']     as bool?,
          logopedaId:  roleInfo['logopeda_id']  as String?,
          logopedaName: roleInfo['logopeda_name'] as String?,
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  /// Llamado cuando el usuario acaba de elegir rol (logopeda o paciente).
  /// PatientCodeScreen NO hace pop antes de llamar esto — AppRouter decide
  /// qué mostrar solo con setState, sin tocar el Navigator.
  void _onRoleSet(AppUser updated) {
    if (!mounted) return;
    widget.onUserChanged(updated);
    setState(() => _user = updated);
    // Si hay pantallas de onboarding encima (RoleSelectionScreen /
    // PatientCodeScreen vía pushReplacement), las eliminamos ahora que
    // AppRouter ya sabe el rol y va a renderizar AppShell o LogopedaShell.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Error de conexión'),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _fetchRole, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    if (!_user.roleSet) {
      return RoleSelectionScreen(user: _user, onRoleSet: _onRoleSet);
    }

    if (_user.isLogopeda) {
      return LogopedaShell(
        user: _user,
        settings: widget.settings,
      );
    }

    return AppShell(
      user: _user,
      settings: widget.settings,
      onSettingsChanged: widget.onSettingsChanged,
      onUserChanged: widget.onUserChanged,
      onLogout: widget.onLogout,
    );
  }
}