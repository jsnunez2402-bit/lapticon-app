import 'package:flutter/material.dart';

import '../models/encomienda.dart';
import '../theme.dart';
import '../utils.dart';
import 'comunes.dart';
import 'ruta_visual.dart';

/// Tarjeta de encomienda usada por el remitente y por el viajero.
class EncomiendaCard extends StatelessWidget {
  final Encomienda e;
  final Widget? acciones;
  final bool mostrarEstado;
  final bool mostrarRemitente;
  final String? nota;

  const EncomiendaCard({
    super.key,
    required this.e,
    this.acciones,
    this.mostrarEstado = true,
    this.mostrarRemitente = false,
    this.nota,
  });

  @override
  Widget build(BuildContext context) {
    Widget linea(IconData i, String t) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(i, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(child: Text(t, style: TextStyle(color: Colors.grey.shade800))),
          ]),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (mostrarEstado)
                EstadoChip(e.estado)
              else
                Text('ENCOMIENDA',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: Colors.grey.shade600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.ambar.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(e.valorTexto,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Color(0xFF8A5A00))),
              ),
            ]),
            const SizedBox(height: 16),
            RutaVisual(origen: e.ciudadOrigen, destino: e.ciudadDestino),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 4),
            if (e.observaciones.isNotEmpty) linea(Icons.inventory_2_outlined, e.observaciones),
            if (mostrarRemitente && e.nombreRemitente != null)
              linea(Icons.person_outline, 'Remitente: ${e.nombreRemitente}'),
            if (e.fechaVencimiento != null)
              linea(Icons.event_outlined, 'Entregar antes del ${fmtFecha(e.fechaVencimiento)}'),
            if (nota != null) linea(Icons.info_outline, nota!),
            if (acciones != null) ...[const SizedBox(height: 14), acciones!],
          ]),
        ),
      ),
    );
  }
}
