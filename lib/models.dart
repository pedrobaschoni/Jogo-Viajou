enum Phase { lobby, bidding, reveal, end }

Phase _phaseFrom(Object? v) =>
    Phase.values.firstWhere((p) => p.name == v, orElse: () => Phase.lobby);

List<Map<String, dynamic>> _maps(Object? v) => ((v as List?) ?? const [])
    .map((e) => Map<String, dynamic>.from(e as Map))
    .toList();

Map<String, dynamic>? _map(Object? v) =>
    v == null ? null : Map<String, dynamic>.from(v as Map);

class Question {
  final String id;
  final String cat;
  final String text;
  final double answer;
  final String unit;
  final String fact;

  /// Nome de quem escreveu (só nas perguntas da família).
  final String? author;

  const Question({
    required this.id,
    required this.cat,
    required this.text,
    required this.answer,
    this.unit = '',
    this.fact = '',
    this.author,
  });

  bool get isYear => unit == 'ano';

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        id: j['id'] as String,
        cat: j['c'] as String,
        text: j['q'] as String,
        answer: (j['a'] as num).toDouble(),
        unit: (j['u'] as String?) ?? '',
        fact: (j['f'] as String?) ?? '',
        author: j['by'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'c': cat,
        'q': text,
        'a': answer,
        'u': unit,
        'f': fact,
        if (author != null) 'by': author,
      };
}

class Player {
  final String id;
  final String name;

  /// Índice na paleta de cores dos jogadores.
  final int color;

  /// Ids das cartas (perguntas) que essa pessoa levou.
  final List<String> cards;

  const Player({
    required this.id,
    required this.name,
    required this.color,
    this.cards = const [],
  });

  Player copyWith({String? name, int? color, List<String>? cards}) => Player(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        cards: cards ?? this.cards,
      );

  String get initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final w = words.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  factory Player.fromJson(Map<String, dynamic> j) => Player(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '?',
        color: ((j['color'] as num?) ?? 0).toInt(),
        cards: ((j['cards'] as List?) ?? const []).map((e) => e as String).toList(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color, 'cards': cards};
}

class Bid {
  final String pid;
  final double value;
  const Bid(this.pid, this.value);

  factory Bid.fromJson(Map<String, dynamic> j) =>
      Bid(j['p'] as String, (j['v'] as num).toDouble());
  Map<String, dynamic> toJson() => {'p': pid, 'v': value};
}

class Reveal {
  final String challenger;
  final String bidder;
  final String loser;
  final double bid;

  /// true = o lance passou da resposta (quem gritou VIAJOU acertou).
  final bool viajou;

  const Reveal({
    required this.challenger,
    required this.bidder,
    required this.loser,
    required this.bid,
    required this.viajou,
  });

  factory Reveal.fromJson(Map<String, dynamic> j) => Reveal(
        challenger: j['challenger'] as String,
        bidder: j['bidder'] as String,
        loser: j['loser'] as String,
        bid: (j['bid'] as num).toDouble(),
        viajou: j['viajou'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'challenger': challenger,
        'bidder': bidder,
        'loser': loser,
        'bid': bid,
        'viajou': viajou,
      };
}

class Settings {
  final int rounds;
  final List<String> cats;
  const Settings({required this.rounds, required this.cats});

  static const allCats = [
    'brasil', 'corpo', 'bichos', 'comida', 'espaco', 'esporte', 'mundo', 'pop', 'diaadia',
  ];
  static const defaults = Settings(rounds: 10, cats: allCats);

  Settings copyWith({int? rounds, List<String>? cats}) =>
      Settings(rounds: rounds ?? this.rounds, cats: cats ?? this.cats);

  factory Settings.fromJson(Map<String, dynamic>? j) => j == null
      ? defaults
      : Settings(
          rounds: ((j['rounds'] as num?) ?? 10).toInt(),
          cats: ((j['cats'] as List?) ?? allCats).map((e) => e as String).toList(),
        );

  Map<String, dynamic> toJson() => {'rounds': rounds, 'cats': cats};
}

const _keep = Object();

class GameState {
  final String code;
  final String hostId;
  final Phase phase;
  final List<Player> players;
  final Settings settings;
  final List<Question> custom;
  final List<Question> deck;
  final int round;
  final String? turn;
  final List<Bid> bids;
  final Reveal? reveal;
  final int version;

  const GameState({
    required this.code,
    required this.hostId,
    required this.phase,
    required this.players,
    required this.settings,
    required this.custom,
    required this.deck,
    required this.round,
    required this.turn,
    required this.bids,
    required this.reveal,
    required this.version,
  });

  Question? get question =>
      (phase == Phase.bidding || phase == Phase.reveal) && round < deck.length ? deck[round] : null;

  Bid? get top => bids.isEmpty ? null : bids.last;

  Player? player(String? id) {
    if (id == null) return null;
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  GameState copyWith({
    String? hostId,
    Phase? phase,
    List<Player>? players,
    Settings? settings,
    List<Question>? custom,
    List<Question>? deck,
    int? round,
    Object? turn = _keep,
    List<Bid>? bids,
    Object? reveal = _keep,
    int? version,
  }) =>
      GameState(
        code: code,
        hostId: hostId ?? this.hostId,
        phase: phase ?? this.phase,
        players: players ?? this.players,
        settings: settings ?? this.settings,
        custom: custom ?? this.custom,
        deck: deck ?? this.deck,
        round: round ?? this.round,
        turn: identical(turn, _keep) ? this.turn : turn as String?,
        bids: bids ?? this.bids,
        reveal: identical(reveal, _keep) ? this.reveal : reveal as Reveal?,
        version: version ?? this.version,
      );

  factory GameState.fromJson(Map<String, dynamic> j) {
    final rev = _map(j['reveal']);
    return GameState(
      code: (j['code'] as String?) ?? '',
      hostId: (j['host'] as String?) ?? '',
      phase: _phaseFrom(j['phase']),
      players: _maps(j['players']).map(Player.fromJson).toList(),
      settings: Settings.fromJson(_map(j['settings'])),
      custom: _maps(j['custom']).map(Question.fromJson).toList(),
      deck: _maps(j['deck']).map(Question.fromJson).toList(),
      round: ((j['round'] as num?) ?? 0).toInt(),
      turn: j['turn'] as String?,
      bids: _maps(j['bids']).map(Bid.fromJson).toList(),
      reveal: rev == null ? null : Reveal.fromJson(rev),
      version: ((j['version'] as num?) ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'host': hostId,
        'phase': phase.name,
        'players': players.map((p) => p.toJson()).toList(),
        'settings': settings.toJson(),
        'custom': custom.map((q) => q.toJson()).toList(),
        'deck': deck.map((q) => q.toJson()).toList(),
        'round': round,
        'turn': turn,
        'bids': bids.map((b) => b.toJson()).toList(),
        'reveal': reveal?.toJson(),
        'version': version,
      };
}
