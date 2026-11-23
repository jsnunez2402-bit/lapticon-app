import 'package:flutter/material.dart';

/// Chip de color según el estado de una encomienda o viaje.
class EstadoChip extends StatelessWidget {
  final String estado;
  const EstadoChip(this.estado, {super.key});

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icono) = switch (estado) {
      'disponible' => (Colors.blue, Icons.schedule),
      'tomada' => (Colors.orange, Icons.local_shipping),
      'recibida' => (Colors.green, Icons.check_circle),
      'completado' => (Colors.green, Icons.check_circle),
      'vencida' => (Colors.grey, Icons.timer_off),
      'cancelado' || 'cancelada' => (Colors.red, Icons.cancel),
      _ => (Colors.blueGrey, Icons.info_outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, size: 14, color: color),
        const SizedBox(width: 4),
        Text(estado,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const ErrorView({super.key, required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onReintentar, child: const Text('Reintentar')),
          ]),
        ),
      );
}

class VacioView extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Widget? accion;
  const VacioView({super.key, required this.icono, required this.texto, this.accion});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(children: [
          Icon(icono, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(texto,
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
          if (accion != null) ...[const SizedBox(height: 16), accion!],
        ]),
      );
}

class SeccionTitulo extends StatelessWidget {
  final String texto;
  const SeccionTitulo(this.texto, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(texto.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 1.1, color: Theme.of(context).colorScheme.primary)),
      );
}

/// Muestra un SnackBar con el mensaje.
void avisar(BuildContext context, String mensaje, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(mensaje),
    backgroundColor: error ? Theme.of(context).colorScheme.error : null,
  ));
}

Future<bool> confirmar(BuildContext context, String titulo, String texto) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
      ],
    ),
  );
  return r ?? false;
}
