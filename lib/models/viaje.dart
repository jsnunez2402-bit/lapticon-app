import '../utils.dart';

class Viaje {
  final String id;
  final String uid; // viajero
  final String numeroVuelo;
  final String ciudadOrigen;
  final String ciudadDestino;
  final DateTime? fechaViaje;
  final String estado; // disponible | completado | cancelado | contactado

  Viaje({
    required this.id,
    required this.uid,
    required this.numeroVuelo,
    required this.ciudadOrigen,
    required this.ciudadDestino,
    required this.fechaViaje,
    required this.estado,
  });

  factory Viaje.fromJson(Map<String, dynamic> j) => Viaje(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        uid: (j['uid'] ?? '').toString(),
        numeroVuelo: (j['numeroVuelo'] ?? '').toString(),
        ciudadOrigen: (j['ciudadOrigen'] ?? '').toString(),
        ciudadDestino: (j['ciudadDestino'] ?? '').toString(),
        fechaViaje: parseFecha(j['fechaViaje']),
        estado: (j['estado'] ?? 'disponible').toString(),
      );

  String get ruta => '$ciudadOrigen → $ciudadDestino';
}
