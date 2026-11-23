import 'package:flutter/material.dart';

import '../theme.dart';

/// Chip de color según el estado de una encomienda o viaje.
class EstadoChip extends StatelessWidget {
  final String estado;
  const EstadoChip(this.estado, {super.key});

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icono, String texto) = switch (estado) {
      'disponible' => (AppColors.azul, Icons.schedule, 'Disponible'),
      'tomada' => (const Color(0xFFE67E00), Icons.local_shipping, 'En camino'),
      'entregada' => (const Color(0xFF00897B), Icons.inventory, 'Entregada'),
      'recibida' => (const Color(0xFF2E7D32), Icons.check_circle, 'Recibida'),
      'completado' => (const Color(0xFF2E7D32), Icons.check_circle, 'Completado'),
      'contactado' => (const Color(0xFF6A1B9A), Icons.forum, 'Contactado'),
      'vencida' => (Colors.grey.shade600, Icons.timer_off, 'Vencida'),
      'cancelado' || 'cancelada' => (Colors.red.shade700, Icons.cancel, 'Cancelado'),
      _ => (Colors.blueGrey, Icons.info_outline, estado),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, size: 14, color: color),
        const SizedBox(width: 5),
        Text(texto,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// Cabecera azul con degradado y esquinas inferiores redondeadas.
class CabeceraGradiente extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<Widget> acciones;
  final Widget? abajo;

  const CabeceraGradiente({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acciones = const [],
    this.abajo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.gradiente,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (subtitulo != null)
                    Text(subtitulo!,
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(titulo,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                ]),
              ),
              ...acciones,
            ]),
            if (abajo != null) ...[
              const SizedBox(height: 18),
              Padding(padding: const EdgeInsets.only(right: 12), child: abajo!),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Recuadro de estadística para usar dentro de la cabecera azul.
class StatBox extends StatelessWidget {
  final String etiqueta;
  final int valor;
  final IconData icono;
  const StatBox({super.key, required this.etiqueta, required this.valor, required this.icono});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icono, color: Colors.white70, size: 18),
          const SizedBox(height: 6),
          Text('$valor',
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      );
}

class ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const ErrorView({super.key, required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(Icons.cloud_off_rounded, size: 40, color: Colors.red.shade400),
            ),
            const SizedBox(height: 16),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
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
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 28),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.azul.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 44, color: AppColors.azul),
          ),
          const SizedBox(height: 16),
          Text(texto,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
          if (accion != null) ...[const SizedBox(height: 18), accion!],
        ]),
      );
}

class SeccionTitulo extends StatelessWidget {
  final String texto;
  const SeccionTitulo(this.texto, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        child: Text(texto.toUpperCase(),
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: Colors.grey.shade600)),
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
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
  return r ?? false;
}
