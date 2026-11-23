import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../widgets/comunes.dart';
import 'login_screen.dart' show mensajeAuth;

/// Registro en dos pasos:
/// 1. Crea la cuenta en Firebase Auth (correo y contraseña).
/// 2. Guarda el perfil en el backend con POST /api/users/register.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _telefono = TextEditingController();
  final _nacionalidad = TextEditingController(text: 'Colombia');
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    for (final c in [_nombre, _apellido, _telefono, _nacionalidad, _email, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _cargando = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final email = _email.text.trim();
    final api = ApiClient.instance;
    api.registroEnCurso = true;

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _pass.text,
      );
      await cred.user?.updateDisplayName('${_nombre.text.trim()} ${_apellido.text.trim()}');
    } on FirebaseAuthException catch (e) {
      api.registroEnCurso = false;
      if (mounted) {
        avisar(context, mensajeAuth(e), error: true);
        setState(() => _cargando = false);
      }
      return;
    }

    try {
      await api.registrarPerfil({
        'nombre': _nombre.text.trim(),
        'apellido': _apellido.text.trim(),
        'telefono': _telefono.text.trim(),
        'nacionalidad': _nacionalidad.text.trim(),
        'correo': email,
      });
      messenger.showSnackBar(const SnackBar(content: Text('¡Cuenta creada! Bienvenido.')));
    } catch (e) {
      // La cuenta de Firebase ya existe; el perfil se puede completar luego.
      messenger.showSnackBar(SnackBar(
          content: Text('Cuenta creada, pero no se pudo guardar el perfil: $e')));
    }
    api.registroEnCurso = false;
    // AuthGate ya muestra HomeScreen debajo; cerramos esta pantalla.
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    String? requerido(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _nombre,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: requerido,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _apellido,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Apellido'),
                    validator: requerido,
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefono,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Teléfono', prefixIcon: Icon(Icons.phone_outlined)),
                validator: requerido,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nacionalidad,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Nacionalidad', prefixIcon: Icon(Icons.flag_outlined)),
                validator: requerido,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Correo', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline)),
                validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pass2,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Repite la contraseña', prefixIcon: Icon(Icons.lock_outline)),
                validator: (v) => v != _pass.text ? 'Las contraseñas no coinciden' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _cargando ? null : _registrar,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: _cargando
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Registrarme'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
