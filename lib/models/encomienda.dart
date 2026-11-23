import '../utils.dart';

class Encomienda {
  final String id;
  final String uid; // remitente
  final String ciudadOrigen;
  final String ciudadDestino;
  final String observaciones;
  final String moneda;
  final num valor;
  final String estado; // disponible | tomada | recibida | vencida
  final String? viajeroId;
  final DateTime? fechaCreacion;
  final DateTime? fechaVencimiento;
  final String? nombreRemitente;

  Encomienda({
    required this.id,
    required this.uid,
    required this.ciudadOrigen,
    required this.ciudadDestino,
    required this.observaciones,
    required this.moneda,
    required this.valor,
    required this.estado,
    this.viajeroId,
    this.fechaCreacion,
    this.fechaVencimiento,
    this.nombreRemitente,
  });

  factory Encomienda.fromJson(Map<String, dynamic> j) {
    final v = j['valor'];
    final viajero = j['viajeroId'];
    return Encomienda(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      uid: (j['uid'] ?? '').toString(),
      ciudadOrigen: (j['ciudadOrigen'] ?? '').toString(),
      ciudadDestino: (j['ciudadDestino'] ?? '').toString(),
      observaciones: (j['observaciones'] ?? '').toString(),
      moneda: (j['moneda'] ?? '').toString(),
      valor: v is num ? v : (num.tryParse('$v') ?? 0),
      estado: (j['estado'] ?? 'disponible').toString(),
      viajeroId: (viajero == null || '$viajero'.isEmpty) ? null : '$viajero',
      fechaCreacion: parseFecha(j['fechaCreacion']),
      fechaVencimiento: parseFecha(j['fechaVencimiento']),
      nombreRemitente: (j['nombreRemitente'] ??
              j['remitenteNombre'] ??
              j['nombre'] ??
              (j['remitente'] is Map ? j['remitente']['nombre'] : null))
          ?.toString(),
    );
  }

  String get ruta => '$ciudadOrigen → $ciudadDestino';
  String get valorTexto =>
      '${valor % 1 == 0 ? valor.toInt() : valor} $moneda'.trim();
}
