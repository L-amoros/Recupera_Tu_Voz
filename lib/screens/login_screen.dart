import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  final Future<void> Function(String email, String password) onLogin;
  final VoidCallback onGoRegister;
  const LoginScreen({super.key, required this.onLogin, required this.onGoRegister});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AdaptiveColors get c => AdaptiveColors.of(context);

  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Rellena todos los campos');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await widget.onLogin(_emailCtrl.text.trim(), _passCtrl.text);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/icon.png',
                    width: 64,
                    height: 64,
                  ),
                ),
                const SizedBox(height: 16),
                Center(child: Text('Recupera tu voz',
                    style: TextStyle(color: c.textPrimary,
                        fontSize: 26, fontWeight: FontWeight.w700))),
                const SizedBox(height: 6),
                Center(child: Text('Inicia sesión para continuar',
                    style: TextStyle(color: c.textDim, fontSize: 14))),
                const SizedBox(height: 40),
                AuthField(ctrl: _emailCtrl, label: 'Email',
                    hint: 'tu@email.com', type: TextInputType.emailAddress),
                const SizedBox(height: 14),
                AuthField(ctrl: _passCtrl, label: 'Contraseña',
                    hint: '••••••••', obscure: true, onSubmit: _submit),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: c.warn, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                AuthButton(label: 'Entrar', loading: _loading, onTap: _submit),
                const SizedBox(height: 18),
                Center(
                  child: GestureDetector(
                    onTap: widget.onGoRegister,
                    child: Text('¿No tienes cuenta? Regístrate',
                        style: TextStyle(color: c.accent, fontSize: 14)),
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