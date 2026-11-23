import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../widgets/comunes.dart';

/// Editar mi perfil: PUT /api/users/{uid}.
/// El correo no se puede cambiar (es la cuenta de Firebase).
class EditarPerfilScreen extends StatefulWidget {
  final Map<String, dynamic> perfil;
  const EditarPerfilScreen({super.key, required this.perfil});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _apellido;
  late final TextEditingController _telefono;
  late final TextEditingController _nacionalidad;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    String v(String k) => widget.perfil[k]?.toString() ?? '';
    _nombre = TextEditingController(text: v('nombre'));
    _apellido = TextEditingController(text: v('apellido'));
    _telefono = TextEditingController(text: v('telefono'));
    _nacionalidad = TextEditingController(text: v('nacionalidad'));
  }

  @override
  void dispose() {
    for (final c in [_nombre, _apellido, _telefono, _nacionalidad]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _guardando = true);
    try {
      await ApiClient.instance.actualizarPerfil(user.uid, {
        'nombre': _nombre.text.trim(),
        'apellido': _apellido.text.trim(),
        'telefono': _telefono.text.trim(),
        'nacionalidad': _nacionalidad.text.trim(),
      });
      // Mantener también el nombre visible en Firebase Auth.
      await user.updateDisplayName('${_nombre.text.trim()} ${_apellido.text.trim()}');
      if (!mounted) return;
      avisar(context, 'Perfil actualizado.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) avisar(context, 'No se pudo guardar: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? requerido(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
                validator: requerido,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apellido,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Apellido', prefixIcon: Icon(Icons.badge_outlined)),
                validator: requerido,
              ),
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
                initialValue: email,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.email_outlined),
                  helperText: 'El correo no se puede cambiar',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: _guardando
                    ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
