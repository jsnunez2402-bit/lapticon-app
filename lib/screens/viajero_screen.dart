import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/encomienda.dart';
import '../models/viaje.dart';
import '../services/api_client.dart';
import '../utils.dart';
import '../widgets/comunes.dart';
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
      await _api.cambiarEstadoEncomienda(e.id, 'recibida');
      if (mounted) avisar(context, 'Encomienda marcada como entregada.');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi viaje'),
        actions: [
          IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh)),
          if (_viaje != null)
            PopupMenuButton<String>(
              onSelected: _cerrarViaje,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'completado', child: Text('Marcar viaje completado')),
                PopupMenuItem(value: 'cancelado', child: Text('Cancelar viaje')),
              ],
            ),
        ],
      ),
      body: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    if (_cargando && !_cargadoUnaVez) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && !_cargadoUnaVez) {
      return ErrorView(mensaje: _error!, onReintentar: _cargar);
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (_cargando) const LinearProgressIndicator(),
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
            _tarjetaViaje(_viaje!),
            SeccionTitulo('Llevo (${_tomadas.length})'),
            if (_tomadas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Todavía no has tomado encomiendas.'),
              ),
            for (final e in _tomadas) _tarjetaEncomienda(e, tomada: true),
            SeccionTitulo('Disponibles en tu ruta (${_disponibles.length})'),
            if (_disponibles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('No hay encomiendas disponibles para esta ruta por ahora.'),
              ),
            for (final e in _disponibles) _tarjetaEncomienda(e, tomada: false),
          ],
        ],
      ),
    );
  }

  Widget _tarjetaViaje(Viaje v) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.flight, color: cs.onPrimaryContainer),
            const SizedBox(width: 8),
            Text('Vuelo ${v.numeroVuelo}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold)),
            const Spacer(),
            EstadoChip(v.estado),
          ]),
          const SizedBox(height: 10),
          Text(v.ruta,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: cs.onPrimaryContainer)),
          const SizedBox(height: 4),
          Text('Fecha: ${fmtFecha(v.fechaViaje)}',
              style: TextStyle(color: cs.onPrimaryContainer)),
        ]),
      ),
    );
  }

  Widget _tarjetaEncomienda(Encomienda e, {required bool tomada}) {
    final procesando = _procesandoId == e.id;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(e.observaciones.isEmpty ? 'Encomienda' : e.observaciones,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text(e.valorTexto,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
          ]),
          const SizedBox(height: 4),
          Text(e.ruta, style: TextStyle(color: Colors.grey.shade700)),
          if (e.nombreRemitente != null)
            Text('Remitente: ${e.nombreRemitente}',
                style: TextStyle(color: Colors.grey.shade700)),
          if (e.fechaVencimiento != null)
            Text('Entregar antes del ${fmtFecha(e.fechaVencimiento)}',
                style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 10),
          if (procesando)
            const LinearProgressIndicator()
          else if (tomada)
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _chat(e),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _marcarEntregada(e),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Entregada'),
                ),
              ),
            ])
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _tomar(e),
                icon: const Icon(Icons.back_hand_outlined),
                label: const Text('Tomar encomienda'),
              ),
            ),
        ]),
      ),
    );
  }
}
