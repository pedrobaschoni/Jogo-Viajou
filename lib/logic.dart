import 'dart:math';

import 'format.dart';
import 'models.dart';

/// Erro de regra do jogo, com mensagem pronta para mostrar na tela.
class GameError implements Exception {
  final String message;
  GameError(this.message);
  @override
  String toString() => message;
}

/// Regras do VIAJOU!. Funções puras: recebem um estado e devolvem outro.
///
/// Cada lance quer dizer "a resposta é PELO MENOS esse número".
/// Na sua vez, você sobe o lance ou grita VIAJOU! (o último lance passou da conta).
/// Se a resposta for menor que o lance, quem lançou viajou e leva a carta.
/// Se não, quem gritou leva. Ganha quem terminar com MENOS cartas.
class Logic {
  static const maxPlayers = 10;
  static const roundOptions = [5, 10, 15, 20];

  static GameState create(String code, Player host) => GameState(
        code: code,
        hostId: host.id,
        phase: Phase.lobby,
        players: [host],
        settings: Settings.defaults,
        custom: const [],
        deck: const [],
        round: 0,
        turn: null,
        bids: const [],
        reveal: null,
        version: 0,
      );

  static GameState join(GameState s, Player p) {
    final i = s.players.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      final list = [...s.players];
      list[i] = list[i].copyWith(name: p.name, color: p.color);
      return s.copyWith(players: list);
    }
    if (s.players.length >= maxPlayers) {
      throw GameError('A sala está cheia (máximo de $maxPlayers jogadores).');
    }
    return s.copyWith(players: [...s.players, p]);
  }

  static String? _nextExisting(List<Player> order, String fromId, Set<String> skip) {
    if (order.isEmpty) return null;
    final i = order.indexWhere((p) => p.id == fromId);
    for (var k = 1; k <= order.length; k++) {
      final cand = order[(max(i, 0) + k) % order.length];
      if (!skip.contains(cand.id)) return cand.id;
    }
    return null;
  }

  static GameState remove(GameState s, String pid) {
    if (s.player(pid) == null) return s;
    final players = s.players.where((p) => p.id != pid).toList();
    var host = s.hostId;
    if (host == pid && players.isNotEmpty) host = players.first.id;
    var turn = s.turn;
    if (turn == pid) turn = _nextExisting(s.players, pid, {pid});
    var next = s.copyWith(players: players, hostId: host, turn: turn);
    if (next.phase != Phase.lobby && players.length < 2) next = toLobby(next);
    return next;
  }

  static GameState setSettings(GameState s, Settings st) {
    if (s.phase != Phase.lobby) return s;
    return s.copyWith(settings: st);
  }

  static GameState addCustom(GameState s, Question q) {
    if (s.custom.length >= 40) throw GameError('Já tem pergunta da família demais (máximo 40).');
    return s.copyWith(custom: [...s.custom, q]);
  }

  static GameState removeCustom(GameState s, String qid) =>
      s.copyWith(custom: s.custom.where((q) => q.id != qid).toList());

  static GameState start(GameState s, List<Question> pool, {Random? rng}) {
    if (s.phase != Phase.lobby) return s;
    if (s.players.length < 2) throw GameError('Precisa de pelo menos 2 jogadores.');
    final r = rng ?? Random();
    final n = s.settings.rounds;
    final custom = [...s.custom]..shuffle(r);
    final builtin = pool.where((q) => s.settings.cats.contains(q.cat)).toList()..shuffle(r);
    final deck = <Question>[...custom.take(n)];
    for (final q in builtin) {
      if (deck.length >= n) break;
      deck.add(q);
    }
    if (deck.isEmpty) throw GameError('Escolha pelo menos uma categoria.');
    deck.shuffle(r);
    final players = s.players.map((p) => p.copyWith(cards: const [])).toList();
    final first = players[r.nextInt(players.length)].id;
    return s.copyWith(
      phase: Phase.bidding,
      players: players,
      deck: deck,
      round: 0,
      turn: first,
      bids: const [],
      reveal: null,
    );
  }

  static GameState bid(GameState s, String pid, double value) {
    if (s.phase != Phase.bidding) throw GameError('Não é hora de chutar.');
    if (s.turn != pid) throw GameError('Calma! Não é a sua vez.');
    if (value.isNaN || value.isInfinite || value < 0) throw GameError('Número inválido.');
    final top = s.top;
    final q = s.question;
    if (top != null && value <= top.value) {
      final shown = q == null ? fmtNum(top.value) : withUnit(top.value, q.unit);
      throw GameError('Tem que ser maior que $shown.');
    }
    return s.copyWith(
      bids: [...s.bids, Bid(pid, value)],
      turn: _nextExisting(s.players, pid, const {}),
    );
  }

  static GameState challenge(GameState s, String pid) {
    if (s.phase != Phase.bidding) throw GameError('Não dá pra gritar agora.');
    if (s.turn != pid) throw GameError('Calma! Não é a sua vez.');
    final top = s.top;
    if (top == null) throw GameError('Ninguém chutou ainda. Dá o primeiro chute!');
    if (top.pid == pid) throw GameError('Não dá pra duvidar do seu próprio chute.');
    final q = s.question;
    if (q == null) return s;
    final viajou = q.answer < top.value;
    final loser = viajou ? top.pid : pid;
    final players = s.players
        .map((p) => p.id == loser ? p.copyWith(cards: [...p.cards, q.id]) : p)
        .toList();
    return s.copyWith(
      phase: Phase.reveal,
      players: players,
      turn: null,
      reveal: Reveal(
        challenger: pid,
        bidder: top.pid,
        loser: loser,
        bid: top.value,
        viajou: viajou,
      ),
    );
  }

  /// Próxima carta. [expectedRound] evita pular duas cartas se duas pessoas tocarem juntas.
  static GameState next(GameState s, int expectedRound) {
    if (s.phase != Phase.reveal || s.round != expectedRound) return s;
    if (s.round + 1 >= s.deck.length) {
      return s.copyWith(phase: Phase.end, turn: null);
    }
    final loser = s.reveal?.loser;
    final starter = s.player(loser) != null ? loser! : s.players.first.id;
    return s.copyWith(
      phase: Phase.bidding,
      round: s.round + 1,
      bids: const [],
      reveal: null,
      turn: starter,
    );
  }

  /// O anfitrião pula a vez de alguém que sumiu.
  static GameState skip(GameState s) {
    if (s.phase != Phase.bidding || s.turn == null) return s;
    return s.copyWith(turn: _nextExisting(s.players, s.turn!, const {}));
  }

  static GameState toLobby(GameState s) => s.copyWith(
        phase: Phase.lobby,
        deck: const [],
        round: 0,
        bids: const [],
        reveal: null,
        turn: null,
        players: s.players.map((p) => p.copyWith(cards: const [])).toList(),
      );

  /// Quem terminou com mais cartas (pode haver empate).
  static List<Player> bigLosers(GameState s) {
    if (s.players.isEmpty) return const [];
    final most = s.players.map((p) => p.cards.length).reduce(max);
    if (most == 0) return const [];
    return s.players.where((p) => p.cards.length == most).toList();
  }
}
