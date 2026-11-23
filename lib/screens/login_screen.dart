import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/comunes.dart';
import 'register_screen.dart';

String mensajeAuth(FirebaseAuthException e) => switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' =>
        'Correo o contraseña incorrectos.',
      'invalid-email' => 'El correo no es válido.',
      'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
      'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
      'too-many-requests' => 'Demasiados intentos. Espera un momento.',
      'network-request-failed' => 'Sin conexión a internet.',
      _ => e.message ?? 'Error de autenticación (${e.code}).',
    };

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _cargando = false;
  bool _ver = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );
      // AuthGate cambia a HomeScreen automáticamente.
    } on FirebaseAuthException catch (e) {
      if (mounted) avisar(context, mensajeAuth(e), error: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _recuperar() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      avisar(context, 'Escribe tu correo para enviarte el enlace.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) avisar(context, 'Te enviamos un correo para restablecer la contraseña.');
    } on FirebaseAuthException catch (e) {
      if (mounted) avisar(context, mensajeAuth(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(children: [
        // Fondo azul superior
        Container(
          height: alto * 0.45,
          decoration: const BoxDecoration(
            gradient: AppColors.gradiente,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(children: [
                  // Logo de la app
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset('assets/icon/logo.png', width: 96, height: 96),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Lapticon',
                      style: TextStyle(
                          color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Envía con quien ya viaja',
                      style: TextStyle(color: Colors.white70, fontSize: 15)),
                  const SizedBox(height: 28),
                  // Tarjeta del formulario
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.azulOscuro.withValues(alpha: 0.10),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Iniciar sesión',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.tinta)),
                          const SizedBox(height: 4),
                          Text('Ingresa con tu correo y contraseña',
                              style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                                labelText: 'Correo',
                                prefixIcon: Icon(Icons.email_outlined)),
                            validator: (v) =>
                                (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _pass,
                            obscureText: !_ver,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_ver ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _ver = !_ver),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Requerida' : null,
                            onFieldSubmitted: (_) => _entrar(),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                                onPressed: _recuperar,
                                child: const Text('¿Olvidaste tu contraseña?')),
                          ),
                          const SizedBox(height: 4),
                          FilledButton(
                            onPressed: _cargando ? null : _entrar,
                            child: _cargando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Entrar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('¿No tienes cuenta?', style: TextStyle(color: Colors.grey.shade700)),
                    TextButton(
                      onPressed: _cargando
                          ? null
                          : () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text('Crear una cuenta',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
