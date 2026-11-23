import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../utils.dart';

/// Campo de ciudad con autocompletado desde GET /api/ciudades/ciudades.
/// Si la lista no carga, funciona como un campo de texto normal.
/// El backend compara las ciudades como texto: usar las sugerencias evita
/// diferencias como "Bogota" vs "Bogotá".
class CityField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const CityField({
    super.key,
    required this.controller,
    required this.label,
    this.icon = Icons.location_city,
  });

  @override
  State<CityField> createState() => _CityFieldState();
}

class _CityFieldState extends State<CityField> {
  final _focus = FocusNode();
  List<String> _ciudades = const [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final c = await ApiClient.instance.ciudades();
      if (mounted) setState(() => _ciudades = c);
    } catch (_) {
      // Sin sugerencias: el campo sigue funcionando como texto libre.
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focus,
      optionsBuilder: (value) {
        final q = normalizar(value.text);
        if (q.isEmpty) return const Iterable<String>.empty();
        return _ciudades.where((c) => normalizar(c).contains(q)).take(8);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextFormField(
        controller: controller,
        focusNode: focusNode,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.icon),
          border: const OutlineInputBorder(),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 340),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final o in options)
                  ListTile(dense: true, title: Text(o), onTap: () => onSelected(o)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
