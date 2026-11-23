import 'package:flutter/material.dart';

import '../models/encomienda.dart';
import '../services/api_client.dart';
import '../utils.dart';
import '../widgets/comunes.dart';
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

  static const _orden = ['tomada', 'disponible', 'recibida', 'vencida'];
  static const _titulos = {
    'tomada': 'En camino (tomadas por un viajero)',
    'disponible': 'Esperando viajero',
    'recibida': 'Recibidas',
    'vencida': 'Vencidas',
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
        '¿La encomienda ${e.ruta} ya fue entregada en destino?');
    if (!ok || !mounted) return;
    try {
      await ApiClient.instance.cambiarEstadoEncomienda(e.id, 'recibida');
      if (mounted) avisar(context, 'Encomienda marcada como recibida.');
      _cargar();
    } catch (err) {
      if (mounted) avisar(context, '$err', error: true);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis encomiendas'),
        actions: [IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nueva,
        icon: const Icon(Icons.add),
        label: const Text('Nueva encomienda'),
      ),
      body: _cuerpo(),
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
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          if (_cargando) const LinearProgressIndicator(),
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
            SeccionTitulo('${_titulos[estado] ?? estado} (${grupos[estado]!.length})'),
            for (final e in grupos[estado]!) _tarjeta(e),
          ],
        ],
      ),
    );
  }

  Widget _tarjeta(Encomienda e) {
    final tomada = e.estado == 'tomada' && e.viajeroId != null;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(e.ruta,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              EstadoChip(e.estado),
            ]),
            const SizedBox(height: 6),
            if (e.observaciones.isNotEmpty) Text(e.observaciones),
            const SizedBox(height: 6),
            Wrap(spacing: 16, runSpacing: 4, children: [
              _dato(Icons.payments_outlined, e.valorTexto),
              if (e.fechaVencimiento != null)
                _dato(Icons.event_outlined, 'Vence ${fmtFecha(e.fechaVencimiento)}'),
            ]),
            if (tomada) ...[
              const Divider(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _chat(e),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat viajero'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _confirmarRecibida(e),
                    icon: const Icon(Icons.check),
                    label: const Text('Recibida'),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dato(IconData i, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(i, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(t, style: TextStyle(color: Colors.grey.shade800)),
      ]);
}
