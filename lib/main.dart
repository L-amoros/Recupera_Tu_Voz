import 'package:flutter/material.dart';
import 'models/app_settings.dart';
import 'models/app_user.dart';
import 'screens/clone_voice_screen.dart';
import 'screens/frases_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/text_screen.dart';
import 'services/api_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RecuperaTuVozApp());
}

class RecuperaTuVozApp extends StatelessWidget {
  const RecuperaTuVozApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recupera tu voz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AppRoot(),
    );
  }
}

// ── AppRoot: gestiona sesión ───────────────────────────────────────
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final AuthService _auth = AuthService();
  final SettingsService _settingsSvc = SettingsService();
  final VoiceApiService _voiceApi = VoiceApiService();

  AppUser? _user;
  AppSettings _settings = const AppSettings();
  bool _loading = true;
  bool _showRegister = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final user = await _auth.loadUser();
    final settings = await _settingsSvc.loadSettings();

    // Si hay sesión activa, sincronizamos num_references con el servidor
    AppUser? syncedUser = user;
    if (user != null) {
      try {
        final status = await _voiceApi.checkVoiceStatusFull(user.token);
        syncedUser = user.copyWith(
          hasVoice: status['has_voice'] as bool? ?? user.hasVoice,
          numReferences: status['num_references'] as int? ?? user.numReferences,
        );
        await _auth.saveUser(syncedUser);
      } catch (_) {
        // Si falla la red, usamos los datos locales guardados
      }
    }

    if (mounted) {
      setState(() {
        _user = syncedUser;
        _settings = settings;
        _loading = false;
      });
    }
  }

  Future<void> _login(String email, String password) async {
    final user = await _auth.login(email: email, password: password);
    await _auth.saveUser(user);
    if (mounted) setState(() => _user = user);
  }

  Future<void> _register(String name, String email, String password) async {
    final user =
    await _auth.register(name: name, email: email, password: password);
    await _auth.saveUser(user);
    if (mounted) setState(() { _user = user; _showRegister = false; });
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (mounted) setState(() => _user = null);
  }

  void _onSettingsChanged(AppSettings s) => setState(() => _settings = s);

  void _onUserChanged(AppUser u) {
    setState(() => _user = u);
    _auth.saveUser(u); // persiste numReferences junto con todo lo demás
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_user == null) {
      if (_showRegister) {
        return RegisterScreen(
          onRegister: _register,
          onGoLogin: () => setState(() => _showRegister = false),
        );
      }
      return LoginScreen(
        onLogin: _login,
        onGoRegister: () => setState(() => _showRegister = true),
      );
    }

    return AppShell(
      user: _user!,
      settings: _settings,
      onSettingsChanged: _onSettingsChanged,
      onUserChanged: _onUserChanged,
      onLogout: _logout,
    );
  }
}

// ── AppShell: navegación principal ────────────────────────────────
class AppShell extends StatefulWidget {
  final AppUser user;
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final ValueChanged<AppUser> onUserChanged;
  final VoidCallback onLogout;

  const AppShell({
    super.key,
    required this.user,
    required this.settings,
    required this.onSettingsChanged,
    required this.onUserChanged,
    required this.onLogout,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tabIndex = 0;
  bool _showCloneVoice = false;

  final VoiceApiService _voiceApi = VoiceApiService();

  void _goToTab(int i) => setState(() => _tabIndex = i);

  @override
  Widget build(BuildContext context) {
    if (_showCloneVoice) {
      return CloneVoiceScreen(
        token: widget.user.token,
        alreadyHasVoice: widget.user.hasVoice,
        // Siempre viene del modelo persistido → nunca se pierde
        initialNumReferences: widget.user.numReferences,
        onUploadMultiple: (files) async {
          final saved = await _voiceApi.uploadMultipleAudios(
            token: widget.user.token,
            files: files,
          );
          // Guardamos el nuevo contador en el modelo
          widget.onUserChanged(
            widget.user.copyWith(hasVoice: true, numReferences: saved),
          );
          return saved;
        },
        onDelete: () async {
          await _voiceApi.deleteVoice(widget.user.token);
          widget.onUserChanged(
            widget.user.copyWith(hasVoice: false, numReferences: 0),
          );
        },
        onDone: () => setState(() => _showCloneVoice = false),
      );
    }

    final screens = [
      HomeScreen(onEmpezar: () => _goToTab(1)),
      TextScreen(settings: widget.settings, user: widget.user),
      FrasesScreen(settings: widget.settings, user: widget.user),
      ProfileScreen(
        settings: widget.settings,
        user: widget.user,
        onSettingsChanged: widget.onSettingsChanged,
        onCloneVoice: () => setState(() => _showCloneVoice = true),
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: _goToTab,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.keyboard_outlined),
              activeIcon: Icon(Icons.keyboard_rounded),
              label: 'Texto'),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Frases'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Perfil'),
        ],
      ),
    );
  }
}