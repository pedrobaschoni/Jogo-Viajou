import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../logic.dart';
import '../models.dart';
import '../net/room.dart';
import '../sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// A grande revelação: quem gritou, o lance, o contador girando até a resposta e o carimbo.
class RevealView extends StatefulWidget {
  final RoomConnection conn;
  final GameState s;
  const RevealView({super.key, required this.conn, required this.s});

  @override
  State<RevealView> createState() => _RevealViewState();
}

class _RevealViewState extends State<RevealView> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 5600));
  final Set<String> _played = {};
  bool _going = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_cues);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _cue(String key, double at, VoidCallback f) {
    if (_c.value >= at && _played.add(key)) f();
  }

  void _cues() {
    final r = widget.s.reveal;
    if (r == null) return;
    _cue('drum', 0.24, () => Sfx.play('drumroll'));
    _cue('stamp', 0.62, () {
      Sfx.play('stamp');
      HapticFeedback.heavyImpact();
    });
    _cue('result', 0.66, () => Sfx.play(r.viajou ? 'tada' : 'trombone'));
  }

  double _counted(double answer, double t) {
    final d = decimalsOf(answer);
    final raw = answer * t.clamp(0.0, 1.0);
    if (d == 0) return raw.roundToDouble();
    final f = pow(10, d).toDouble();
    return (raw * f).round() / f;
  }

  Future<void> _next() async {
    if (_going) return;
    setState(() => _going = true);
    final ok = await runAct(context, () => widget.conn.act((st) => Logic.next(st, widget.s.round)));
    if (!ok && mounted) setState(() => _going = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final r = s.reveal;
    final q = s.question;
    if (r == null || q == null) return const SizedBox.shrink();
    final challenger = s.player(r.challenger);
    final bidder = s.player(r.bidder);
    final loser = s.player(r.loser);
    final last = s.round + 1 >= s.deck.length;
    final short = MediaQuery.sizeOf(context).height < 700;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Toque na tela pula a animação.
        if (_c.value < 0.95) _c.animateTo(1, duration: const Duration(milliseconds: 250));
      },
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = _c.value;
          double iv(double a, double b, [Curve curve = Curves.easeOutCubic]) =>
              Interval(a, b, curve: curve).transform(v);

          final dim = iv(0.0, 0.06);
          final shout = iv(0.0, 0.18, Curves.elasticOut);
          final bidIn = iv(0.12, 0.22);
          final boxIn = iv(0.2, 0.27, Curves.easeOutBack);
          final count = iv(0.27, 0.6, Curves.easeOutQuart);
          final stamp = iv(0.62, 0.74, Curves.elasticOut);
          final loserIn = iv(0.72, 0.82, Curves.easeOutBack);
          final factIn = iv(0.82, 0.94);
          final shown = _counted(q.answer, count);
          final verdictColor = r.viajou ? C.pink : C.mint;

          return ColoredBox(
            color: C.ink.withValues(alpha: 0.86 * dim),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: short ? 10 : 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Quem gritou
                      Opacity(
                        opacity: shout.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.4 + 0.6 * shout,
                          child: Transform.rotate(
                            angle: -0.06,
                            child: Column(children: [
                              Text('${(challenger?.name ?? 'Alguém').toUpperCase()} GRITOU',
                                  textAlign: TextAlign.center, style: display(20, color: C.cream, letterSpacing: 1.5)),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: StrokeText('VIAJOU!', size: short ? 54 : 68, fill: C.pink, shadow: C.ink),
                              ),
                            ]),
                          ),
                        ),
                      ),
                      SizedBox(height: short ? 6 : 10),
                      // Lance
                      Opacity(
                        opacity: bidIn,
                        child: Transform.translate(
                          offset: Offset(0, (1 - bidIn) * 18),
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(text: 'Chute de ${bidder?.name ?? '?'}: '),
                              TextSpan(text: withUnit(r.bid, q.unit), style: display(22, color: C.sun)),
                            ]),
                            textAlign: TextAlign.center,
                            style: body(17, color: C.cream, weight: FontWeight.w800),
                          ),
                        ),
                      ),
                      SizedBox(height: short ? 10 : 14),
                      // Resposta girando
                      Opacity(
                        opacity: boxIn.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.7 + 0.3 * boxIn,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.fromLTRB(16, short ? 10 : 14, 16, short ? 12 : 16),
                            decoration: inkBox(color: C.cream, radius: 24, shadow: 6),
                            child: Column(children: [
                              Text(q.text,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: body(14.5, color: C.muted, weight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text('A RESPOSTA É…', style: display(15, color: C.ink, letterSpacing: 2)),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  withUnit(shown, q.unit),
                                  style: display(short ? 44 : 56, color: count >= 0.999 ? verdictColor : C.ink)
                                      .copyWith(
                                    shadows: count >= 0.999
                                        ? const [Shadow(color: C.ink, offset: Offset(2, 3))]
                                        : null,
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                      SizedBox(height: short ? 10 : 16),
                      // Carimbo
                      Opacity(
                        opacity: (stamp * 3).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: stamp <= 0 ? 2.6 : 2.6 - 1.6 * stamp,
                          child: Transform.rotate(
                            angle: -0.12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: C.ink.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: verdictColor, width: 5),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: StrokeText(
                                  r.viajou ? 'VIAJOU MESMO!' : 'NÃO VIAJOU!',
                                  size: short ? 34 : 42,
                                  fill: verdictColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: short ? 10 : 16),
                      // Quem leva a carta
                      Opacity(
                        opacity: loserIn.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, (1 - loserIn) * 30),
                          child: Column(children: [
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              if (loser != null) PlayerChip(p: loser, size: 46, showName: false),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text('${loser?.name ?? '?'} leva a carta!',
                                    style: display(26, color: C.sun)),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            Text(
                              r.viajou
                                  ? '${bidder?.name ?? '?'} chutou alto demais.'
                                  : '${challenger?.name ?? '?'} duvidou à toa: a resposta era pelo menos ${withUnit(r.bid, q.unit)}.',
                              textAlign: TextAlign.center,
                              style: body(15, color: C.cream, weight: FontWeight.w700),
                            ),
                          ]),
                        ),
                      ),
                      SizedBox(height: short ? 10 : 16),
                      // Curiosidade e botão
                      Opacity(
                        opacity: factIn,
                        child: Column(children: [
                          if (q.fact.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: glassBox(radius: 18),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Icon(Icons.lightbulb_rounded, color: C.sun),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(q.fact, style: body(15, color: C.cream, weight: FontWeight.w700)),
                                ),
                              ]),
                            ),
                          const SizedBox(height: 16),
                          IgnorePointer(
                            ignoring: factIn < 0.5,
                            child: ChunkyButton(
                              label: last ? 'VER RESULTADO' : 'PRÓXIMA CARTA',
                              icon: last ? Icons.emoji_events_rounded : Icons.arrow_forward_rounded,
                              color: C.sun,
                              expand: true,
                              fontSize: 22,
                              onTap: _going ? null : _next,
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
