import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../utils.dart';

/// Ciudades permitidas (comparadas sin tildes ni mayúsculas).
/// La lista real se carga del backend con GET /api/ciudades/ciudades y se
/// filtra a estas. Al backend se envía el nombre tal como lo devuelve el
/// servicio, así remitente y viajero siempre usan el mismo texto.
const _permitidasColombia = ['bogota', 'medellin', 'cali'];
const _permitidasExterior = ['miami', 'mexico city', 'new york'];

String bandera(String ciudad) => switch (normalizar(ciudad)) {
      'bogota' || 'medellin' || 'cali' => '🇨🇴',
      'miami' => '🇺🇸',
      'mexico city' => '🇲🇽',
      'new york' => '🇺🇸',
      _ => '📍',
    };

/// Selector de ruta: una ciudad de Colombia ↔ una ciudad del exterior (Miami, Mexico City, New York),
/// en cualquier sentido. Al elegir el origen, el destino solo ofrece las
/// ciudades del otro grupo.
class RutaSelector extends StatefulWidget {
  final TextEditingController origen;
  final TextEditingController destino;
  final IconData iconoOrigen;
  final IconData iconoDestino;

  const RutaSelector({
    super.key,
    required this.origen,
    required this.destino,
    this.iconoOrigen = Icons.trip_origin,
    this.iconoDestino = Icons.place,
  });

  @override
  State<RutaSelector> createState() => _RutaSelectorState();
}

class _RutaSelectorState extends State<RutaSelector> {
  List<String> _colombia = [];
  List<String> _exterior = [];
  bool _cargando = true;
  String? _error;

  String? _origen;
  String? _destino;

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
      final todas = await ApiClient.instance.ciudades();
      final col = <String>[];
      final ext = <String>[];
      // Se recorre en el orden de las permitidas para mostrarlas siempre igual.
      for (final p in _permitidasColombia) {
        final c = _buscar(todas, p);
        if (c != null) col.add(c);
      }
      for (final p in _permitidasExterior) {
        final c = _buscar(todas, p);
        if (c != null) ext.add(c);
      }
      if (!mounted) return;
      setState(() {
        _colombia = col;
        _exterior = ext;
        if (col.isEmpty || ext.isEmpty) {
          _error = 'El servicio de ciudades no devolvió las ciudades permitidas '
              '(Bogota, Medellin, Cali, Miami, Mexico City, New York).';
        }
        // Mantener lo que ya estuviera escrito en los controladores.
        final o = widget.origen.text;
        final d = widget.destino.text;
        _origen = _todas.contains(o) ? o : null;
        _destino = _destinosPara(_origen).contains(d) ? d : null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudieron cargar las ciudades: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Primera ciudad del servicio cuyo nombre normalizado coincide.
  String? _buscar(List<String> todas, String permitida) {
    for (final c in todas) {
      if (normalizar(c) == permitida) return c;
    }
    return null;
  }

  List<String> get _todas => [..._colombia, ..._exterior];

  List<String> _destinosPara(String? origen) {
    if (origen == null) return const [];
    return _colombia.contains(origen) ? _exterior : _colombia;
  }

  DropdownMenuItem<String> _item(String c) =>
      DropdownMenuItem(value: c, child: Text('${bandera(c)}  $c'));

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
              height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 12),
          Text('Cargando ciudades…'),
        ]),
      );
    }

    if (_error != null) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton.tonal(onPressed: _cargar, child: const Text('Reintentar')),
            // Campo oculto para que el formulario no se pueda enviar sin ciudades.
            FormField<String>(
              validator: (_) => 'Las ciudades no están disponibles',
              builder: (_) => const SizedBox.shrink(),
            ),
          ]),
        ),
      );
    }

    final destinos = _destinosPara(_origen);
    return Column(children: [
      DropdownButtonFormField<String>(
        initialValue: _origen,
        decoration: InputDecoration(
          labelText: 'Ciudad de origen',
          prefixIcon: Icon(widget.iconoOrigen),
        ),
        items: _todas.map(_item).toList(),
        onChanged: (v) => setState(() {
          _origen = v;
          widget.origen.text = v ?? '';
          if (_destino != null && !_destinosPara(v).contains(_destino)) {
            _destino = null;
            widget.destino.text = '';
          }
        }),
        validator: (v) => v == null ? 'Elige la ciudad de origen' : null,
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        // La key cambia con el grupo de destinos para reiniciar el campo.
        key: ValueKey('destinos-${destinos.join()}'),
        initialValue: _destino,
        decoration: InputDecoration(
          labelText: 'Ciudad de destino',
          prefixIcon: Icon(widget.iconoDestino),
          helperText: _origen == null ? 'Primero elige el origen' : null,
        ),
        items: destinos.map(_item).toList(),
        onChanged: _origen == null
            ? null
            : (v) => setState(() {
                  _destino = v;
                  widget.destino.text = v ?? '';
                }),
        validator: (v) => v == null ? 'Elige la ciudad de destino' : null,
      ),
    ]);
  }
}
