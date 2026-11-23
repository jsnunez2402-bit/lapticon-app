import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../utils.dart';
import '../widgets/city_field.dart';
import '../widgets/comunes.dart';

/// POST /api/viajes. Regla de negocio: solo un viaje "disponible" a la vez.
class RegistrarViajeScreen extends StatefulWidget {
  const RegistrarViajeScreen({super.key});

  @override
  State<RegistrarViajeScreen> createState() => _RegistrarViajeScreenState();
}

class _RegistrarViajeScreenState extends State<RegistrarViajeScreen> {
  final _form = GlobalKey<FormState>();
  final _vuelo = TextEditingController();
  final _origen = TextEditingController();
  final _destino = TextEditingController();
  DateTime? _fecha;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_vuelo, _origen, _destino]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha ?? hoy,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: hoy.add(const Duration(days: 365)),
      helpText: 'Fecha del vuelo',
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _guardar() async {
    final valido = _form.currentState!.validate();
    if (_fecha == null) {
      avisar(context, 'Elige la fecha del vuelo.', error: true);
      return;
    }
    if (!valido) return;
    if (normalizar(_origen.text) == normalizar(_destino.text)) {
      avisar(context, 'El origen y el destino deben ser distintos.', error: true);
      return;
    }
    setState(() => _guardando = true);
    try {
      await ApiClient.instance.crearViaje(
        numeroVuelo: _vuelo.text.trim().toUpperCase().replaceAll(' ', ''),
        ciudadOrigen: _origen.text.trim(),
        ciudadDestino: _destino.text.trim(),
        fechaViaje: fechaIso(_fecha!),
      );
      if (!mounted) return;
      avisar(context, 'Viaje registrado.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) avisar(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar viaje')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _vuelo,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Número de vuelo',
                  hintText: 'Ej.: AV10, AA123',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                ),
                validator: (v) {
                  final s = (v ?? '').trim().replaceAll(' ', '');
                  if (!RegExp(r'^[A-Za-z0-9]{2,3}\d{1,4}$').hasMatch(s)) {
                    return 'Formato inválido (aerolínea + número)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CityField(
                  controller: _origen, label: 'Ciudad de origen', icon: Icons.flight_takeoff),
              const SizedBox(height: 16),
              CityField(
                  controller: _destino, label: 'Ciudad de destino', icon: Icons.flight_land),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: const Text('Fecha del vuelo'),
                subtitle: Text(_fecha == null
                    ? 'Toca para elegir'
                    : fmtFecha(DateTime.utc(_fecha!.year, _fecha!.month, _fecha!.day))),
                trailing: const Icon(Icons.chevron_right),
                onTap: _elegirFecha,
              ),
              const SizedBox(height: 8),
              Text(
                'El backend puede validar el vuelo contra AeroDataBox. Si el vuelo no existe para esa fecha, verás el error aquí.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: _guardando
                    ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.flight),
                label: const Text('Registrar viaje'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
