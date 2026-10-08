import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../logic.dart';
import '../models.dart';

/// Se o Firebase foi configurado (flutterfire configure). Sem ele, só o modo celular único funciona.
class Online {
  static bool ready = false;
}

/// Uma sala de jogo. A interface só lê [state] e chama [act].
abstract class RoomConnection {
  ValueNotifier<GameState?> get state;

  /// true = todo mundo joga no mesmo aparelho.
  bool get isLocal;

  /// Quem está neste aparelho. null no modo celular único.
  String? get myId;

  /// Aplica uma regra do jogo. Lança [GameError] se a jogada for inválida.
  Future<void> act(GameState Function(GameState s) change);

  void dispose();
}

/// Sala que vive só na memória deste aparelho (passa o celular).
class LocalRoom implements RoomConnection {
  @override
  final ValueNotifier<GameState?> state;

  LocalRoom(GameState initial) : state = ValueNotifier<GameState?>(initial);

  @override
  bool get isLocal => true;

  @override
  String? get myId => null;

  @override
  Future<void> act(GameState Function(GameState s) change) async {
    final s = state.value;
    if (s == null) return;
    final n = change(s);
    if (identical(n, s)) return;
    state.value = n.copyWith(version: s.version + 1);
  }

  @override
  void dispose() => state.dispose();
}

/// Sala no Firestore: um documento por sala, toda jogada é uma transação.
class OnlineRoom implements RoomConnection {
  final DocumentReference<Map<String, dynamic>> ref;

  @override
  final String myId;

  @override
  final ValueNotifier<GameState?> state = ValueNotifier<GameState?>(null);

  /// Vira true se a sala for apagada.
  final ValueNotifier<bool> gone = ValueNotifier<bool>(false);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  OnlineRoom(this.ref, this.myId) {
    _sub = ref.snapshots().listen((snap) {
      final data = snap.data();
      if (data == null) {
        gone.value = true;
        return;
      }
      try {
        state.value = GameState.fromJson(data);
      } catch (e) {
        debugPrint('Estado inválido na sala: $e');
      }
    }, onError: (Object e) => debugPrint('Erro ouvindo a sala: $e'));
  }

  @override
  bool get isLocal => false;

  @override
  Future<void> act(GameState Function(GameState s) change) async {
    GameError? ruleError;
    await ref.firestore.runTransaction<void>((tx) async {
      ruleError = null;
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null) {
        ruleError = GameError('Essa sala não existe mais.');
        return;
      }
      final s = GameState.fromJson(data);
      GameState? n;
      try {
        n = change(s);
      } on GameError catch (e) {
        ruleError = e;
      }
      final next = n;
      if (next == null || identical(next, s)) return;
      final out = next.copyWith(version: s.version + 1).toJson();
      out['updatedAt'] = FieldValue.serverTimestamp();
      tx.set(ref, out);
    });
    final err = ruleError;
    if (err != null) throw err;
  }

  @override
  void dispose() {
    _sub?.cancel();
    state.dispose();
    gone.dispose();
  }
}

class RoomService {
  static const _letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static String _newCode(Random r) =>
      List.generate(4, (_) => _letters[r.nextInt(_letters.length)]).join();

  static Future<OnlineRoom> create(Player me) async {
    final r = Random();
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = _newCode(r);
      final ref = _db.collection('rooms').doc(code);
      var created = false;
      await _db.runTransaction<void>((tx) async {
        created = false;
        final snap = await tx.get(ref);
        final data = snap.data();
        if (data != null) {
          // Reaproveita códigos de salas abandonadas há mais de 12 horas.
          final updated = data['updatedAt'];
          final old = updated is Timestamp &&
              DateTime.now().difference(updated.toDate()) > const Duration(hours: 12);
          if (!old) return;
        }
        final out = Logic.create(code, me).toJson();
        out['updatedAt'] = FieldValue.serverTimestamp();
        tx.set(ref, out);
        created = true;
      });
      if (created) return OnlineRoom(ref, me.id);
    }
    throw GameError('Não consegui criar a sala. Tenta de novo!');
  }

  static Future<OnlineRoom> join(String code, Player me) async {
    final ref = _db.collection('rooms').doc(code.trim().toUpperCase());
    final room = OnlineRoom(ref, me.id);
    try {
      await room.act((s) => Logic.join(s, me));
      return room;
    } on GameError catch (e) {
      room.dispose();
      if (e.message.contains('não existe')) {
        throw GameError('Não achei a sala ${code.toUpperCase()}. Confere o código?');
      }
      rethrow;
    } catch (_) {
      room.dispose();
      rethrow;
    }
  }
}
