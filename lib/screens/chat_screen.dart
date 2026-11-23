import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/chat_service.dart';
import '../utils.dart';
import '../widgets/comunes.dart';

/// Chat remitente ↔ viajero en tiempo real (Firestore).
/// Antes de permitir escribir, consulta al backend si el chat está cerrado.
class ChatScreen extends StatefulWidget {
  final String otroUid;
  final String titulo;
  final String? subtitulo;

  const ChatScreen({
    super.key,
    required this.otroUid,
    required this.titulo,
    this.subtitulo,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _miUid = FirebaseAuth.instance.currentUser!.uid;
  final _texto = TextEditingController();
  final _scroll = ScrollController();
  late final String _chatId;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  bool _cerrado = false;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _chatId = ChatService.chatIdPara(_miUid, widget.otroUid);
    _stream = ChatService.instance.mensajes(_chatId);
    _verificarEstado();
  }

  Future<void> _verificarEstado() async {
    try {
      final estado = await ApiClient.instance.estadoChat(_chatId);
      if (mounted) setState(() => _cerrado = estado == 'cerrado');
    } catch (_) {
      // Si el backend no responde, se deja escribir.
    }
  }

  @override
  void dispose() {
    _texto.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final t = _texto.text.trim();
    if (t.isEmpty || _cerrado) return;
    setState(() => _enviando = true);
    try {
      await ChatService.instance.enviar(
        chatId: _chatId,
        autorId: _miUid,
        otroId: widget.otroUid,
        texto: t,
      );
      _texto.clear();
    } on FirebaseException catch (e) {
      if (mounted) {
        avisar(
            context,
            e.code == 'permission-denied'
                ? 'Firestore rechazó el mensaje (reglas de seguridad).'
                : 'No se pudo enviar: ${e.message}',
            error: true);
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.titulo),
          if (widget.subtitulo != null)
            Text(widget.subtitulo!, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No se pudo cargar el chat:\n${snap.error}',
                        textAlign: TextAlign.center),
                  ),
                );
              }
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const VacioView(
                  icono: Icons.chat_bubble_outline,
                  texto: 'Aún no hay mensajes.\nSaluda y coordina la entrega.',
                );
              }
              _bajar();
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final m = docs[i].data();
                  final mio = m['autorId'] == _miUid;
                  final fecha = (m['fecha'] as Timestamp?)?.toDate();
                  return Align(
                    alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: mio ? cs.primary : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: Radius.circular(mio ? 14 : 2),
                          bottomRight: Radius.circular(mio ? 2 : 14),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            mio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text('${m['texto'] ?? ''}',
                              style: TextStyle(color: mio ? cs.onPrimary : cs.onSurface)),
                          const SizedBox(height: 2),
                          Text(fecha == null ? 'enviando…' : fmtHora(fecha),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: (mio ? cs.onPrimary : cs.onSurface)
                                      .withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (_cerrado)
          Container(
            width: double.infinity,
            color: cs.errorContainer,
            padding: const EdgeInsets.all(12),
            child: Text('Este chat está cerrado: la entrega ya fue confirmada.',
                textAlign: TextAlign.center, style: TextStyle(color: cs.onErrorContainer)),
          )
        else
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _texto,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje…',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24))),
                    ),
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  onPressed: _enviando ? null : _enviar,
                  icon: const Icon(Icons.send),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}
