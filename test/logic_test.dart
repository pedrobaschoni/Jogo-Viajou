import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:viajou/logic.dart';
import 'package:viajou/models.dart';

const pool = [
  Question(id: 'q1', cat: 'corpo', text: 'Quantos ossos?', answer: 206, unit: 'ossos'),
  Question(id: 'q2', cat: 'corpo', text: 'Quantos dentes?', answer: 32, unit: 'dentes'),
  Question(id: 'q3', cat: 'corpo', text: 'Quantos pares de costelas?', answer: 12, unit: 'pares'),
];

GameState _started() {
  var s = Logic.create('ABCD', const Player(id: 'a', name: 'Ana', color: 0));
  s = Logic.join(s, const Player(id: 'b', name: 'Beto', color: 1));
  s = Logic.join(s, const Player(id: 'c', name: 'Caio', color: 2));
  s = Logic.setSettings(s, s.settings.copyWith(rounds: 2, cats: ['corpo']));
  return Logic.start(s, pool, rng: Random(1));
}

String _after(GameState s, String id) {
  final i = s.players.indexWhere((p) => p.id == id);
  return s.players[(i + 1) % s.players.length].id;
}

void main() {
  test('o lance precisa subir e a vez passa adiante', () {
    var s = _started();
    final first = s.turn!;
    s = Logic.bid(s, first, 100);
    expect(s.top!.value, 100);
    expect(s.turn, _after(s, first));
    expect(() => Logic.bid(s, s.turn!, 100), throwsA(isA<GameError>()));
    expect(() => Logic.bid(s, first, 150), throwsA(isA<GameError>()));
  });

  test('VIAJOU certo: quem chutou alto leva a carta', () {
    var s = _started();
    final q = s.question!;
    final bidder = s.turn!;
    s = Logic.bid(s, bidder, q.answer + 1);
    final caller = s.turn!;
    s = Logic.challenge(s, caller);
    expect(s.phase, Phase.reveal);
    expect(s.reveal!.viajou, isTrue);
    expect(s.reveal!.loser, bidder);
    expect(s.player(bidder)!.cards, [q.id]);
  });

  test('VIAJOU errado: quem duvidou leva a carta (resposta igual ao lance vale)', () {
    var s = _started();
    final q = s.question!;
    final bidder = s.turn!;
    s = Logic.bid(s, bidder, q.answer);
    final caller = s.turn!;
    s = Logic.challenge(s, caller);
    expect(s.reveal!.viajou, isFalse);
    expect(s.reveal!.loser, caller);
  });

  test('não dá pra duvidar sem lance nem de si mesmo', () {
    var s = _started();
    expect(() => Logic.challenge(s, s.turn!), throwsA(isA<GameError>()));
  });

  test('próxima carta começa com quem perdeu e o jogo termina', () {
    var s = _started();
    final b = s.turn!;
    s = Logic.bid(s, b, 99999);
    s = Logic.challenge(s, s.turn!);
    final loser = s.reveal!.loser;
    s = Logic.next(s, 0);
    expect(s.phase, Phase.bidding);
    expect(s.round, 1);
    expect(s.turn, loser);
    // Toque repetido na mesma rodada não pula carta.
    expect(identical(Logic.next(s, 0), s), isTrue);
    s = Logic.bid(s, s.turn!, 99999);
    s = Logic.challenge(s, s.turn!);
    s = Logic.next(s, 1);
    expect(s.phase, Phase.end);
  });

  test('estado sobrevive ida e volta em JSON', () {
    var s = _started();
    s = Logic.bid(s, s.turn!, 12.5);
    final back = GameState.fromJson(s.toJson());
    expect(back.top!.value, 12.5);
    expect(back.players.length, 3);
    expect(back.deck.length, s.deck.length);
    expect(back.turn, s.turn);
  });
}
