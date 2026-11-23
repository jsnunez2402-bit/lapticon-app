import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/comunes.dart';
import 'editar_perfil_screen.dart';

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

  Future<void> _editar(Map<String, dynamic> perfil) async {
    final cambio = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditarPerfilScreen(perfil: perfil)),
    );
    if (cambio == true) _recargar();
  }

  Future<void> _salir() async {
    if (await confirmar(context, 'Cerrar sesión', '¿Quieres salir de tu cuenta?')) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          final inicial = nombre.isNotEmpty
              ? nombre[0]
              : ((_user.email ?? '').isNotEmpty ? _user.email![0] : '?');
          String dato(String k) {
            final v = p[k]?.toString() ?? '';
            return v.isEmpty ? '—' : v;
          }

          Widget fila(IconData i, String titulo, String valor, {Widget? trailing}) =>
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.azul.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(i, color: AppColors.azul, size: 20),
                ),
                title: Text(titulo,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                subtitle: Text(valor,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.tinta)),
                trailing: trailing,
              );

          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                // Cabecera con avatar
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.gradiente,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.white24, shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.white,
                            child: Text(inicial.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.azul)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(nombre.isEmpty ? 'Sin nombre' : nombre,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(_user.email ?? '',
                            style: const TextStyle(color: Colors.white70)),
                      ]),
                    ),
                  ),
                ),
                const SeccionTitulo('Mis datos'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Column(children: [
                      fila(Icons.phone_outlined, 'Teléfono', dato('telefono')),
                      const Divider(indent: 16, endIndent: 16),
                      fila(Icons.flag_outlined, 'Nacionalidad', dato('nacionalidad')),
                      const Divider(indent: 16, endIndent: 16),
                      fila(
                        Icons.fingerprint,
                        'UID',
                        _user.uid,
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _user.uid));
                            avisar(context, 'UID copiado');
                          },
                        ),
                      ),
                    ]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _editar(p),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar perfil'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _salir,
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar sesión'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
