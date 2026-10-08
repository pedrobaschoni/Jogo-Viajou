import 'dart:math';

import 'package:flutter/material.dart';

import '../format.dart';
import '../logic.dart';
import '../models.dart';
import '../net/room.dart';
import '../theme.dart';
import '../widgets/bid_pad.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/question_card.dart';
import 'reveal.dart';

/// Mesa de jogo: carta, lance atual e teclado (ou espera pela vez).
class GameView extends StatelessWidget {
  final RoomConnection conn;
  final GameState s;
  final VoidCallback onLeave;
  const GameView({super.key, required this.conn, required this.s, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    final q = s.question;
    if (q == null) return const SizedBox.shrink();
    final me = conn.myId;
    final actor = conn.isLocal ? s.turn : me;
    final myTurn = s.phase == Phase.bidding && s.turn != null && s.turn == actor;
    final top = s.top;
    final canViajou = myTurn && top != null && top.pid != actor;
    final isHost = conn.isLocal || s.hostId == me;

    return LayoutBuilder(builder: (context, cons) {
      final wide = cons.maxWidth >= 900 && cons.maxHeight >= 560;
      final tiny = !wide && cons.maxHeight < 690;
      final compact = wide ? cons.maxHeight < 700 : cons.maxHeight < 800;

      Future<bool> bid(double v) => runAct(context, () => conn.act((st) => Logic.bid(st, actor!, v)));
      Future<bool> viajou() => runAct(context, () => conn.act((st) => Logic.challenge(st, actor!)));

      final topBar = _TopBar(conn: conn, s: s, onLeave: onLeave);
      final players = _PlayersStrip(s: s, me: me, compact: compact);
      final card = QuestionCard(q: q, index: s.round, total: s.deck.length, compact: compact);
      final board = _BidBoard(s: s, q: q, compact: compact);
      final current = s.player(s.turn);

      final Widget action = myTurn
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TurnBanner(
                  key: ValueKey('banner-${s.turn}-${s.round}'),
                  color: playerColor(current?.color ?? 0),
                  title: conn.isLocal ? 'VEZ DE ${(current?.name ?? '').toUpperCase()}' : 'SUA VEZ!',
                  sub: conn.isLocal
                      ? 'Passa o celular!'
                      : top == null
                          ? 'Dá o primeiro chute!'
                          : canViajou
                              ? 'Sobe o chute ou grita VIAJOU!'
                              : 'Sobe o chute!',
                ),
                SizedBox(height: compact ? 8 : 10),
                BidPad(
                  key: ValueKey('pad-${s.round}-${s.turn}'),
                  q: q,
                  current: top?.value,
                  canViajou: canViajou,
                  compact: compact,
                  onBid: bid,
                  onViajou: viajou,
                ),
              ],
            )
          : _WaitingPanel(
              s: s,
              canSkip: isHost && !conn.isLocal && s.turn != me && s.phase == Phase.bidding,
              onSkip: () => runAct(context, () => conn.act(Logic.skip)),
            );

      Widget content;
      if (wide) {
        content = Column(children: [
          topBar,
          players,
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 14, 24),
                  child: Column(children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 480),
                          child: card,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: board),
                  ]),
                ),
              ),
              Expanded(
                flex: 4,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 8, 28, 24),
                    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: action),
                  ),
                ),
              ),
            ]),
          ),
        ]);
      } else if (tiny) {
        content = SingleChildScrollView(
          child: Column(children: [
            topBar,
            players,
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SizedBox(height: 210, child: card),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: board),
            Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: action),
          ]),
        );
      } else {
        content = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(children: [
              topBar,
              players,
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, compact ? 4 : 10, 16, compact ? 8 : 12),
                  child: card,
                ),
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: board),
              Padding(
                padding: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 16, 10),
                child: action,
              ),
            ]),
          ),
        );
      }

      return Stack(children: [
        Positioned.fill(child: content),
        if (s.phase == Phase.reveal)
          Positioned.fill(child: RevealView(key: ValueKey('reveal-${s.round}'), conn: conn, s: s)),
      ]);
    });
  }
}

class _TopBar extends StatelessWidget {
  final RoomConnection conn;
  final GameState s;
  final VoidCallback onLeave;
  const _TopBar({required this.conn, required this.s, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Row(children: [
        RoundIconButton(icon: Icons.arrow_back_rounded, onTap: onLeave, size: 40, tooltip: 'Sair'),
        const SizedBox(width: 10),
        Pill('CARTA ${s.round + 1} DE ${s.deck.length}', color: C.sun, textColor: C.ink, size: 14),
        const Spacer(),
        if (!conn.isLocal) ...[
          Pill(s.code, icon: Icons.vpn_key_rounded, size: 13),
          const SizedBox(width: 8),
        ],
        const MuteButton(),
      ]),
    );
  }
}

class _PlayersStrip extends StatelessWidget {
  final GameState s;
  final String? me;
  final bool compact;
  const _PlayersStrip({required this.s, required this.me, required this.compact});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(12, compact ? 10 : 14, 12, compact ? 4 : 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: max(0.0, cons.maxWidth - 24)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final p in s.players)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: PlayerChip(
                    p: p,
                    size: compact ? 40 : 48,
                    active: s.phase == Phase.bidding && s.turn == p.id,
                    isMe: p.id == me,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BidBoard extends StatelessWidget {
  final GameState s;
  final Question q;
  final bool compact;
  const _BidBoard({required this.s, required this.q, required this.compact});

  @override
  Widget build(BuildContext context) {
    final top = s.top;
    final bidder = s.player(top?.pid);
    return Container(
      padding: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 12, compact ? 8 : 12),
      decoration: glassBox(radius: 20),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                top == null ? 'NINGUÉM CHUTOU AINDA' : 'LANCE ATUAL  ·  ${s.bids.length} ${s.bids.length == 1 ? 'chute' : 'chutes'}',
                style: display(12.5, color: C.lilac, letterSpacing: 1.5),
              ),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                layoutBuilder: (cur, prev) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...prev, if (cur != null) cur],
                ),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                  alignment: Alignment.centerLeft,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: top == null
                    ? Text('O primeiro chute é livre',
                        key: const ValueKey('none'), style: body(16, color: C.cream, weight: FontWeight.w800))
                    : FittedBox(
                        key: ValueKey('bid-${s.bids.length}'),
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(withUnit(top.value, q.unit),
                            style: display(compact ? 30 : 38, color: C.sun)),
                      ),
              ),
            ],
          ),
        ),
        if (bidder != null) ...[
          const SizedBox(width: 10),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('de', style: body(11, color: C.cream, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            PlayerChip(p: bidder, size: compact ? 34 : 40, showCards: false),
          ]),
        ],
      ]),
    );
  }
}

class _TurnBanner extends StatelessWidget {
  final String title;
  final String sub;
  final Color color;
  const _TurnBanner({super.key, required this.title, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: 0.6 + 0.4 * v, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: inkBox(color: color, radius: 16, shadow: 3),
        child: Row(children: [
          const Icon(Icons.touch_app_rounded, color: C.ink),
          const SizedBox(width: 8),
          Flexible(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: display(20, color: C.ink)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(sub,
                textAlign: TextAlign.right,
                maxLines: 2,
                style: body(13, weight: FontWeight.w800, height: 1.1)),
          ),
        ]),
      ),
    );
  }
}

class _WaitingPanel extends StatelessWidget {
  final GameState s;
  final bool canSkip;
  final VoidCallback onSkip;
  const _WaitingPanel({required this.s, required this.canSkip, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final cur = s.player(s.turn);
    final hasBid = s.top != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: glassBox(radius: 22),
      child: Row(children: [
        const Mascot(size: 64, wave: false),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              if (cur != null) ...[
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: playerColor(cur.color),
                    shape: BoxShape.circle,
                    border: Border.all(color: C.ink, width: 2),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  cur == null ? 'AGUARDANDO...' : 'VEZ DE ${cur.name.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: display(22, color: C.sun),
                ),
              ),
            ]),
            const SizedBox(height: 2),
            Text(
              hasBid ? 'Vai subir o chute ou gritar VIAJOU?' : 'Pensando no primeiro chute...',
              style: body(14.5, color: C.cream, weight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Row(children: [
              const _Dots(),
              const Spacer(),
              if (canSkip)
                GestureDetector(
                  onTap: onSkip,
                  child: Text(
                    'Pular vez',
                    style: body(13, color: C.lilac, weight: FontWeight.w800)
                        .copyWith(decoration: TextDecoration.underline, decorationColor: C.lilac),
                  ),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();
  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < 3; i++)
          Transform.translate(
            offset: Offset(0, -4 * max(0.0, sin((_c.value - i * 0.15) * pi * 2))),
            child: Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(right: 5),
              decoration: const BoxDecoration(color: C.cream, shape: BoxShape.circle),
            ),
          ),
      ]),
    );
  }
}
