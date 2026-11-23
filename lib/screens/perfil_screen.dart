import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_client.dart';
import '../widgets/comunes.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late Future<Map<String, dynamic>?> _perfil;
  final _user = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _perfil = ApiClient.instance.miPerfil(_user.uid);
  }

  void _recargar() => setState(() => _perfil = ApiClient.instance.miPerfil(_user.uid));

  Future<void> _salir() async {
    if (await confirmar(context, 'Cerrar sesión', '¿Quieres salir de tu cuenta?')) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _perfil,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorView(mensaje: '${snap.error}', onReintentar: _recargar);
          }
          final p = snap.data ?? {};
          final nombre = '${p['nombre'] ?? ''} ${p['apellido'] ?? ''}'.trim();
          String dato(String k) {
            final v = p[k]?.toString() ?? '';
            return v.isEmpty ? '—' : v;
          }

          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    child: Text(
                      (nombre.isNotEmpty ? nombre[0] : (_user.email ?? '?')[0]).toUpperCase(),
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(nombre.isEmpty ? 'Sin nombre' : nombre,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(children: [
                    ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Correo'),
                        subtitle: Text(_user.email ?? '—')),
                    ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: const Text('Teléfono'),
                        subtitle: Text(dato('telefono'))),
                    ListTile(
                        leading: const Icon(Icons.flag_outlined),
                        title: const Text('Nacionalidad'),
                        subtitle: Text(dato('nacionalidad'))),
                    ListTile(
                      leading: const Icon(Icons.fingerprint),
                      title: const Text('UID'),
                      subtitle: Text(_user.uid, style: const TextStyle(fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _user.uid));
                          avisar(context, 'UID copiado');
                        },
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _salir,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
