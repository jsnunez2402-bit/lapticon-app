import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat en Firestore. Los mensajes NO pasan por el backend.
///
/// Estructura:
///   chats/{uid1_uid2}                -> { participantes, ultimoMensaje, actualizado }
///   chats/{uid1_uid2}/mensajes/{id}  -> { texto, autorId, fecha }
class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final _db = FirebaseFirestore.instance;

  /// uid1_uid2 con los dos uid ordenados: el mismo par de usuarios siempre
  /// abre el mismo documento, sin importar quién escriba primero.
  static String chatIdPara(String a, String b) {
    final l = [a, b]..sort();
    return '${l[0]}_${l[1]}';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> mensajes(String chatId) => _db
      .collection('chats')
      .doc(chatId)
      .collection('mensajes')
      .orderBy('fecha')
      .snapshots();

  Future<void> enviar({
    required String chatId,
    required String autorId,
    required String otroId,
    required String texto,
  }) async {
    final ref = _db.collection('chats').doc(chatId);
    final batch = _db.batch();
    batch.set(
      ref,
      {
        'participantes': [autorId, otroId]..sort(),
        'ultimoMensaje': texto,
        'actualizado': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(ref.collection('mensajes').doc(), {
      'texto': texto,
      'autorId': autorId,
      'fecha': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
