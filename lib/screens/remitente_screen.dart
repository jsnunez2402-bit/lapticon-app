import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/encomienda.dart';
import '../services/api_client.dart';
import '../widgets/comunes.dart';
import '../widgets/encomienda_card.dart';
import 'chat_screen.dart';
import 'crear_encomienda_screen.dart';

/// Rol REMITENTE: mis encomiendas agrupadas por estado.
class RemitenteScreen extends StatefulWidget {
  const RemitenteScreen({super.key});

  @override
  State<RemitenteScreen> createState() => _RemitenteScreenState();
}

class _RemitenteScreenState extends State<RemitenteScreen> {
  List<Encomienda>? _items;
  String? _error;
  bool _cargando = true;

  static const _orden = ['entregada', 'tomada', 'disponible', 'recibida', 'vencida'];
  static const _titulos = {
    'entregada': 'Entregadas: confirma que las recibiste',
    'tomada': 'En camino (tomadas por un viajero)',
    'disponible': 'Esperando viajero',
    'recibida': 'Recibidas',
    'vencida': 'Vencidas o retiradas',
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final l = await ApiClient.instance.misEncomiendas();
      if (mounted) setState(() => _items = l);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _nueva() async {
    final creada = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const CrearEncomiendaScreen()));
    if (creada == true) _cargar();
  }

  Future<void> _confirmarRecibida(Encomienda e) async {
    final ok = await confirmar(context, 'Confirmar recepción',
        '¿Ya recibiste la encomienda ${e.ruta} en destino?');
    if (!ok || !mounted) return;
    try {
      await ApiClient.instance.cambiarEstadoEncomienda(e.id, 'recibida');
      if (mounted) avisar(context, 'Encomienda marcada como recibida.');
      _cargar();
    } catch (err) {
      if (mounted) avisar(context, '$err', error: true);
    }
  }

  /// La API no tiene DELETE ni estado "cancelada": para retirar una
  /// publicación se marca como "vencida" (los viajeros dejan de verla).
  /// Solo se permite mientras ningún viajero la haya tomado.
  Future<void> _retirar(Encomienda e) async {
    final ok = await confirmar(context, 'Retirar encomienda',
        '¿Retirar la encomienda ${e.ruta}? Quedará como vencida y dejará de aparecer para los viajeros.');
    if (!ok || !mounted) return;
    try {
      await ApiClient.instance.cambiarEstadoEncomienda(e.id, 'vencida');
      if (mounted) avisar(context, 'Encomienda retirada.');
      _cargar();
    } catch (err) {
      if (mounted) avisar(context, 'No se pudo retirar: $err', error: true);
    }
  }

  void _chat(Encomienda e) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otroUid: e.viajeroId!,
          titulo: 'Chat con el viajero',
          subtitulo: e.ruta,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items ?? [];
    int contar(bool Function(Encomienda) f) => items.where(f).length;
    final nombre =
        (FirebaseAuth.instance.currentUser?.displayName ?? '').trim().split(' ').first;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nueva,
        icon: const Icon(Icons.add),
        label: const Text('Nueva encomienda', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        CabeceraGradiente(
          subtitulo: nombre.isEmpty ? 'Hola 👋' : 'Hola, $nombre 👋',
          titulo: 'Mis envíos',
          acciones: [
            IconButton(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh_rounded),
              color: Colors.white,
            ),
          ],
          abajo: Row(children: [
            Expanded(
              child: StatBox(
                  etiqueta: 'Disponibles',
                  valor: contar((e) => e.estado == 'disponible'),
                  icono: Icons.schedule),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatBox(
                  etiqueta: 'En camino',
                  valor: contar((e) => e.estado == 'tomada' || e.estado == 'entregada'),
                  icono: Icons.local_shipping_outlined),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatBox(
                  etiqueta: 'Recibidas',
                  valor: contar((e) => e.estado == 'recibida'),
                  icono: Icons.check_circle_outline),
            ),
          ]),
        ),
        Expanded(child: _cuerpo()),
      ]),
    );
  }

  Widget _cuerpo() {
    if (_cargando && _items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items == null) {
      return ErrorView(mensaje: _error!, onReintentar: _cargar);
    }
    final items = _items ?? [];

    final grupos = <String, List<Encomienda>>{};
    for (final e in items) {
      grupos.putIfAbsent(e.estado, () => []).add(e);
    }
    final estados = [
      ..._orden.where(grupos.containsKey),
      ...grupos.keys.where((k) => !_orden.contains(k)),
    ];

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 100),
        children: [
          if (_cargando) const LinearProgressIndicator(minHeight: 2),
          if (items.isEmpty)
            VacioView(
              icono: Icons.inventory_2_outlined,
              texto:
                  'Aún no has publicado encomiendas.\nCrea una y un viajero que vaya a ese destino podrá llevarla.',
              accion: FilledButton.icon(
                  onPressed: _nueva,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear encomienda')),
            ),
          for (final estado in estados) ...[
            SeccionTitulo('${_titulos[estado] ?? estado} · ${grupos[estado]!.length}'),
            for (final e in grupos[estado]!) _tarjeta(e),
          ],
        ],
      ),
    );
  }

  Widget _tarjeta(Encomienda e) {
    final tomada =
        (e.estado == 'tomada' || e.estado == 'entregada') && e.viajeroId != null;

    Widget? acciones;
    if (e.estado == 'disponible') {
      acciones = Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => _retirar(e),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Retirar'),
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
        ),
      );
    } else if (tomada) {
      acciones = Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _chat(e),
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Chat'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _confirmarRecibida(e),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Recibida'),
          ),
        ),
      ]);
    }

    return EncomiendaCard(
      e: e,
      acciones: acciones,
      nota: e.estado == 'disponible' ? 'Esperando que un viajero la tome' : null,
    );
  }
}
