import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/encomienda.dart';
import '../models/viaje.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Cliente de la API REST de Lapticon.
/// Cada petición protegida lleva `Authorization: Bearer <idToken de Firebase>`.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// true mientras RegisterScreen crea la cuenta y guarda el perfil, para que
  /// HomeScreen no intente crear un perfil vacío al mismo tiempo.
  bool registroEnCurso = false;

  // ---------------------------------------------------------------- base

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw ApiException(401, 'No has iniciado sesión.');
      final token = await user.getIdToken();
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$kBaseUrl$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    late final http.Response res;
    try {
      res = await request().timeout(kTimeout);
    } on TimeoutException {
      throw ApiException(0,
          'El servidor tardó demasiado en responder. Si estaba dormido, inténtalo de nuevo.');
    } on SocketException {
      throw ApiException(0, 'Sin conexión a internet.');
    } on http.ClientException {
      throw ApiException(0, 'No se pudo conectar con el servidor.');
    }

    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(res.body);
      } catch (_) {
        data = res.body;
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    var msg = 'Error ${res.statusCode}';
    if (data is Map) {
      msg = (data['error'] ?? data['message'] ?? data['mensaje'] ?? msg).toString();
    } else if (data is String && data.isNotEmpty && data.length < 200) {
      msg = data;
    }
    if (res.statusCode == 401) msg = 'Sesión inválida o vencida. Vuelve a iniciar sesión.';
    throw ApiException(res.statusCode, msg);
  }

  Future<dynamic> get(String path, {Map<String, String>? query, bool auth = true}) async {
    final h = await _headers(auth: auth);
    return _send(() => http.get(_uri(path, query), headers: h));
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final h = await _headers(auth: auth);
    return _send(() => http.post(_uri(path), headers: h, body: jsonEncode(body)));
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final h = await _headers();
    return _send(() => http.put(_uri(path), headers: h, body: jsonEncode(body)));
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final h = await _headers();
    return _send(() => http.patch(_uri(path), headers: h, body: jsonEncode(body)));
  }

  /// Acepta tanto `[...]` como `{ "encomiendas": [...] }`, `{ "data": [...] }`, etc.
  List<Map<String, dynamic>> _lista(dynamic data, [List<String> claves = const []]) {
    dynamic l = data;
    if (data is Map) {
      for (final k in [...claves, 'data', 'resultados', 'items']) {
        if (data[k] is List) {
          l = data[k];
          break;
        }
      }
    }
    if (l is! List) return [];
    return l.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic>? _objeto(dynamic data, String clave) {
    if (data is Map && data[clave] is Map) return Map<String, dynamic>.from(data[clave]);
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  // ------------------------------------------------------------ usuarios

  Future<void> registrarPerfil(Map<String, dynamic> datos) =>
      post('/api/users/register', datos);

  /// Devuelve null si el usuario aún no tiene perfil en el backend (404).
  Future<Map<String, dynamic>?> miPerfil(String uid) async {
    try {
      return _objeto(await get('/api/users/$uid'), 'user');
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  // --------------------------------------------------------- encomiendas

  Future<List<Encomienda>> misEncomiendas() async {
    final data = await get('/api/encomiendas');
    return _lista(data, ['encomiendas']).map(Encomienda.fromJson).toList();
  }

  Future<Encomienda?> crearEncomienda({
    required String ciudadOrigen,
    required String ciudadDestino,
    required String observaciones,
    required String moneda,
    required num valor,
    DateTime? fechaVencimiento,
  }) async {
    final data = await post('/api/encomiendas', {
      'ciudadOrigen': ciudadOrigen,
      'ciudadDestino': ciudadDestino,
      'observaciones': observaciones,
      'moneda': moneda,
      'valor': valor,
      if (fechaVencimiento != null) 'fechaVencimiento': fechaVencimiento.toIso8601String(),
    });
    final o = _objeto(data, 'encomienda');
    return o == null ? null : Encomienda.fromJson(o);
  }

  /// Encomiendas de una ruta: las disponibles y las que yo (viajero) ya tomé.
  Future<({List<Encomienda> disponibles, List<Encomienda> tomadas})> buscarEncomiendas(
      String origen, String destino) async {
    final data = await get('/api/encomiendas/buscar',
        query: {'origen': origen, 'destino': destino});
    if (data is Map) {
      return (
        disponibles: _lista(data['disponibles']).map(Encomienda.fromJson).toList(),
        tomadas: _lista(data['tomadas']).map(Encomienda.fromJson).toList(),
      );
    }
    return (disponibles: <Encomienda>[], tomadas: <Encomienda>[]);
  }

  Future<void> tomarEncomienda(String id) => put('/api/encomiendas/tomar/$id', {});

  /// estado: disponible | tomada | recibida | vencida
  Future<void> cambiarEstadoEncomienda(String id, String estado) =>
      put('/api/encomiendas/$id/estado', {'estado': estado});

  // -------------------------------------------------------------- viajes

  /// Devuelve null si no tengo un viaje en estado disponible (404).
  Future<Viaje?> miViajeDisponible() async {
    try {
      final o = _objeto(await get('/api/viajes/disponible'), 'viaje');
      return (o == null || o.isEmpty) ? null : Viaje.fromJson(o);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> crearViaje({
    required String numeroVuelo,
    required String ciudadOrigen,
    required String ciudadDestino,
    required String fechaViaje, // yyyy-MM-dd
  }) =>
      post('/api/viajes', {
        'numeroVuelo': numeroVuelo,
        'ciudadOrigen': ciudadOrigen,
        'ciudadDestino': ciudadDestino,
        'fechaViaje': fechaViaje,
      });

  /// estado: disponible | completado | cancelado
  Future<void> cambiarEstadoViaje(String id, String estado) =>
      patch('/api/viajes/$id/estado', {'estado': estado});

  // --------------------------------------------------------------- chats

  /// "abierto" | "cerrado". Si el backend aún no conoce el chat (404), se
  /// considera abierto.
  Future<String> estadoChat(String chatId) async {
    try {
      final data = await get('/api/chats/estado/$chatId');
      if (data is Map && data['estado'] != null) return data['estado'].toString();
      return 'abierto';
    } on ApiException catch (e) {
      if (e.statusCode == 404) return 'abierto';
      rethrow;
    }
  }

  // ------------------------------------------------------------ ciudades

  List<String>? _cacheCiudades;

  Future<List<String>> ciudades() async {
    if (_cacheCiudades != null) return _cacheCiudades!;
    final data = await get('/api/ciudades/ciudades', auth: false);
    dynamic l = data;
    if (data is Map) l = data['ciudades'] ?? data['data'] ?? [];
    final out = <String>{};
    if (l is List) {
      for (final e in l) {
        if (e is String) {
          out.add(e);
        } else if (e is Map) {
          final n = e['nombre'] ?? e['ciudad'] ?? e['name'];
          if (n != null) out.add(n.toString());
        }
      }
    }
    _cacheCiudades = out.toList()..sort();
    return _cacheCiudades!;
  }
}
