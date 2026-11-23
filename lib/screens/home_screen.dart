import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import 'perfil_screen.dart';
import 'remitente_screen.dart';
import 'viajero_screen.dart';

/// Pantalla principal. Un mismo usuario puede ser remitente y viajero,
/// así que ambos roles están disponibles como pestañas (no se pierde el rol
/// al cambiar de teléfono).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _asegurarPerfil();
  }

  /// Si el usuario existe en Firebase pero no en el backend (p. ej. el
  /// registro del perfil falló), lo crea con los datos mínimos.
  Future<void> _asegurarPerfil() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || ApiClient.instance.registroEnCurso) return;
    try {
      final perfil = await ApiClient.instance.miPerfil(user.uid);
      if (perfil == null) {
        await ApiClient.instance.registrarPerfil({'correo': user.email ?? ''});
      }
    } catch (_) {
      // Silencioso: no bloquea el uso de la app.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [RemitenteScreen(), ViajeroScreen(), PerfilScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Enviar'),
          NavigationDestination(
              icon: Icon(Icons.flight_outlined),
              selectedIcon: Icon(Icons.flight),
              label: 'Viajar'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil'),
        ],
      ),
    );
  }
}
