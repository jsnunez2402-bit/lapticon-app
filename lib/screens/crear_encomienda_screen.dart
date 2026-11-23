import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../utils.dart';
import '../widgets/city_field.dart';
import '../widgets/comunes.dart';

/// POST /api/encomiendas
class CrearEncomiendaScreen extends StatefulWidget {
  const CrearEncomiendaScreen({super.key});

  @override
  State<CrearEncomiendaScreen> createState() => _CrearEncomiendaScreenState();
}

class _CrearEncomiendaScreenState extends State<CrearEncomiendaScreen> {
  final _form = GlobalKey<FormState>();
  final _origen = TextEditingController();
  final _destino = TextEditingController();
  final _obs = TextEditingController();
  final _valor = TextEditingController();
  String _moneda = 'USD';
  DateTime? _vence;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_origen, _destino, _obs, _valor]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _vence ?? hoy.add(const Duration(days: 15)),
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
      helpText: 'Fecha límite de entrega',
    );
    if (f != null) setState(() => _vence = f);
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    if (normalizar(_origen.text) == normalizar(_destino.text)) {
      avisar(context, 'El origen y el destino deben ser distintos.', error: true);
      return;
    }
    setState(() => _guardando = true);
    try {
      await ApiClient.instance.crearEncomienda(
        ciudadOrigen: _origen.text.trim(),
        ciudadDestino: _destino.text.trim(),
        observaciones: _obs.text.trim(),
        moneda: _moneda,
        valor: num.parse(_valor.text.trim().replaceAll(',', '.')),
        fechaVencimiento: _vence == null
            ? null
            : DateTime.utc(_vence!.year, _vence!.month, _vence!.day, 23, 59),
      );
      if (!mounted) return;
      avisar(context, 'Encomienda publicada.');
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
      appBar: AppBar(title: const Text('Nueva encomienda')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CityField(
                  controller: _origen, label: 'Ciudad de origen', icon: Icons.trip_origin),
              const SizedBox(height: 16),
              CityField(controller: _destino, label: 'Ciudad de destino', icon: Icons.place),
              const SizedBox(height: 16),
              TextFormField(
                controller: _obs,
                maxLines: 3,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: '¿Qué envías?',
                  hintText: 'Ej.: Documentos en sobre sellado, 0,5 kg',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Describe el contenido' : null,
              ),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _valor,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Pago al viajero', prefixIcon: Icon(Icons.payments_outlined)),
                    validator: (v) {
                      final n = num.tryParse((v ?? '').trim().replaceAll(',', '.'));
                      if (n == null || n <= 0) return 'Valor inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _moneda,
                    decoration: const InputDecoration(labelText: 'Moneda'),
                    items: const [
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'COP', child: Text('COP')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                    ],
                    onChanged: (v) => setState(() => _moneda = v ?? 'USD'),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: const Text('Fecha límite (opcional)'),
                subtitle: Text(_vence == null
                    ? 'Si no eliges una, el servidor asigna la suya'
                    : fmtFecha(DateTime.utc(_vence!.year, _vence!.month, _vence!.day))),
                trailing: _vence == null
                    ? const Icon(Icons.chevron_right)
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _vence = null)),
                onTap: _elegirFecha,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: _guardando
                    ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: const Text('Publicar encomienda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
