import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/encomienda.dart';
import '../models/viaje.dart';
import '../services/api_client.dart';
import '../utils.dart';
import '../widgets/comunes.dart';
import '../widgets/encomienda_card.dart';
import '../widgets/ruta_visual.dart';
import 'chat_screen.dart';
import 'registrar_viaje_screen.dart';

/// Rol VIAJERO: mi viaje activo y las encomiendas de esa ruta.
class ViajeroScreen extends StatefulWidget {
  const ViajeroScreen({super.key});

  @override
  State<ViajeroScreen> createState() => _ViajeroScreenState();
}

class _ViajeroScreenState extends State<ViajeroScreen> {
  final _api = ApiClient.instance;
  final _miUid = FirebaseAuth.instance.currentUser!.uid;

  Viaje? _viaje;
  List<Encomienda> _disponibles = [];
  List<Encomienda> _tomadas = [];
  bool _cargando = true;
  bool _cargadoUnaVez = false;
  String? _error;
  String? _procesandoId;

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
      final viaje = await _api.miViajeDisponible();
      var disp = <Encomienda>[];
      var tom = <Encomienda>[];
      if (viaje != null) {
        final r = await _api.buscarEncomiendas(viaje.ciudadOrigen, viaje.ciudadDestino);
        // No mostrar mis propias encomiendas (si también soy remitente).
        disp = r.disponibles.where((e) => e.uid != _miUid).toList();
        tom = r.tomadas;
      }
      if (!mounted) return;
      setState(() {
        _viaje = viaje;
        _disponibles = disp;
        _tomadas = tom;
        _cargadoUnaVez = true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _registrarViaje() async {
    final ok = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const RegistrarViajeScreen()));
    if (ok == true) _cargar();
  }

  Future<void> _cerrarViaje(String estado) async {
    final v = _viaje;
    if (v == null) return;
    final texto = estado == 'completado'
        ? '¿Marcar el viaje ${v.numeroVuelo} como completado?'
        : '¿Cancelar el viaje ${v.numeroVuelo}?';
    if (!await confirmar(context, 'Viaje', texto) || !mounted) return;
    try {
      await _api.cambiarEstadoViaje(v.id, estado);
      if (mounted) avisar(context, 'Viaje $estado.');
      _cargar();
    } catch (e) {
      if (mounted) avisar(context, '$e', error: true);
    }
  }

  Future<void> _tomar(Encomienda e) async {
    final ok = await confirmar(context, 'Tomar encomienda',
        'Te comprometes a llevar "${e.observaciones}" de ${e.ruta} por ${e.valorTexto}.');
    if (!ok || !mounted) return;
    setState(() => _procesandoId = e.id);
    try {
      await _api.tomarEncomienda(e.id);
      if (mounted) avisar(context, '¡Encomienda tomada! Coordina la entrega por chat.');
      await _cargar();
    } catch (err) {
      if (mounted) avisar(context, '$err', error: true);
    } finally {
      if (mounted) setState(() => _procesandoId = null);
    }
  }

  Future<void> _marcarEntregada(Encomienda e) async {
    final ok = await confirmar(
        context, 'Marcar como entregada', '¿Ya entregaste la encomienda ${e.ruta}?');
    if (!ok || !mounted) return;
    setState(() => _procesandoId = e.id);
    try {
      await _api.cambiarEstadoEncomienda(e.id, 'entregada');
      if (mounted) {
        avisar(context, 'Marcada como entregada. El remitente debe confirmar la recepción.');
      }
      await _cargar();
    } catch (err) {
      if (mounted) avisar(context, '$err', error: true);
    } finally {
      if (mounted) setState(() => _procesandoId = null);
    }
  }

  void _chat(Encomienda e) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otroUid: e.uid,
          titulo: e.nombreRemitente != null
              ? 'Chat con ${e.nombreRemitente}'
              : 'Chat con el remitente',
          subtitulo: e.ruta,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = _viaje;
    return Scaffold(
      body: Column(children: [
        CabeceraGradiente(
          subtitulo: 'Modo viajero',
          titulo: v == null ? 'Mi viaje' : 'Vuelo ${v.numeroVuelo}',
          acciones: [
            IconButton(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh_rounded),
              color: Colors.white,
            ),
            if (v != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: _cerrarViaje,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'completado', child: Text('Marcar viaje completado')),
                  PopupMenuItem(value: 'cancelado', child: Text('Cancelar viaje')),
                ],
              ),
          ],
          abajo: v == null ? null : _paseAbordar(v),
        ),
        Expanded(child: _cuerpo()),
      ]),
    );
  }

  /// Tarjeta del viaje dentro de la cabecera azul, estilo pase de abordar.
  Widget _paseAbordar(Viaje v) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(children: [
          RutaVisual(origen: v.ciudadOrigen, destino: v.ciudadDestino, claro: true),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.event_outlined, size: 16, color: Colors.white70),
            const SizedBox(width: 6),
            Text(fmtFecha(v.fechaViaje), style: const TextStyle(color: Colors.white)),
            const Spacer(),
            const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.white70),
            const SizedBox(width: 6),
            Text('Llevas ${_tomadas.length}', style: const TextStyle(color: Colors.white)),
          ]),
        ]),
      );

  Widget _cuerpo() {
    if (_cargando && !_cargadoUnaVez) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && !_cargadoUnaVez) {
      return ErrorView(mensaje: _error!, onReintentar: _cargar);
    }

    Widget mensaje(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(t, style: TextStyle(color: Colors.grey.shade600)),
        );

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 32),
        children: [
          if (_cargando) const LinearProgressIndicator(minHeight: 2),
          if (_viaje == null)
            VacioView(
              icono: Icons.flight_takeoff,
              texto:
                  'No tienes un viaje activo.\nRegistra tu vuelo para ver las encomiendas que puedes llevar.',
              accion: FilledButton.icon(
                onPressed: _registrarViaje,
                icon: const Icon(Icons.add),
                label: const Text('Registrar viaje'),
              ),
            )
          else ...[
            SeccionTitulo('Encomiendas que llevo · ${_tomadas.length}'),
            if (_tomadas.isEmpty) mensaje('Todavía no has tomado encomiendas.'),
            for (final e in _tomadas) _tarjetaEncomienda(e, tomada: true),
            SeccionTitulo('Disponibles en tu ruta · ${_disponibles.length}'),
            if (_disponibles.isEmpty)
              mensaje('No hay encomiendas disponibles para esta ruta por ahora.'),
            for (final e in _disponibles) _tarjetaEncomienda(e, tomada: false),
          ],
        ],
      ),
    );
  }

  Widget _tarjetaEncomienda(Encomienda e, {required bool tomada}) {
    final procesando = _procesandoId == e.id;

    final Widget acciones;
    String? nota;
    if (procesando) {
      acciones = const LinearProgressIndicator();
    } else if (tomada && e.estado != 'tomada') {
      nota = e.estado == 'entregada'
          ? 'Entregada. Esperando que el remitente confirme.'
          : null;
      acciones = SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _chat(e),
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: const Text('Chat con el remitente'),
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
            onPressed: () => _marcarEntregada(e),
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Entregada'),
          ),
        ),
      ]);
    } else {
      acciones = SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _tomar(e),
          icon: const Icon(Icons.back_hand_outlined, size: 18),
          label: const Text('Tomar encomienda'),
        ),
      );
    }

    return EncomiendaCard(
      e: e,
      mostrarEstado: tomada,
      mostrarRemitente: true,
      nota: nota,
      acciones: acciones,
    );
  }
}
