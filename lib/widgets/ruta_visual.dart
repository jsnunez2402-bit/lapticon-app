import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'ruta_selector.dart' show bandera;

/// Ruta tipo "pase de abordar": Origen ·····✈····· Destino.
/// Con [claro] = true se dibuja en blanco, para fondos azules.
class RutaVisual extends StatelessWidget {
  final String origen;
  final String destino;
  final bool claro;

  const RutaVisual({
    super.key,
    required this.origen,
    required this.destino,
    this.claro = false,
  });

  @override
  Widget build(BuildContext context) {
    final texto = claro ? Colors.white : AppColors.tinta;
    final sub = claro ? Colors.white70 : Colors.grey.shade600;
    final linea = claro ? Colors.white54 : AppColors.azul.withValues(alpha: 0.35);
    final avion = claro ? AppColors.ambar : AppColors.azul;

    Widget ciudad(String c, String etiqueta, CrossAxisAlignment a) => ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 130),
          child: Column(crossAxisAlignment: a, children: [
            Text(etiqueta,
                style: TextStyle(fontSize: 11, color: sub, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('${bandera(c)} $c',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: texto)),
          ]),
        );

    return Row(children: [
      ciudad(origen, 'ORIGEN', CrossAxisAlignment.start),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(size: const Size(double.infinity, 2), painter: _Punteada(linea)),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: claro ? AppColors.azul : Colors.white,
                shape: BoxShape.circle,
              ),
              child: RotatedBox(
                  quarterTurns: 1, child: Icon(Icons.flight, size: 20, color: avion)),
            ),
          ]),
        ),
      ),
      ciudad(destino, 'DESTINO', CrossAxisAlignment.end),
    ]);
  }
}

class _Punteada extends CustomPainter {
  final Color color;
  _Punteada(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, size.width), y), p);
    }
  }

  @override
  bool shouldRepaint(_Punteada old) => old.color != color;
}
