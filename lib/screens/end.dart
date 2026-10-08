import 'package:flutter/material.dart';

import '../logic.dart';
import '../models.dart';
import '../net/room.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/confetti.dart';

/// Placar final. Quem tem MAIS cartas é o Grande Viajante; todo o resto ganha.
class EndView extends StatelessWidget {
  final RoomConnection conn;
  final GameState s;
  final VoidCallback onLeave;
  const EndView({super.key, required this.conn, required this.s, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    final isHost = conn.isLocal || s.hostId == conn.myId;
    final losers = Logic.bigLosers(s);
    final ranked = [...s.players]..sort((a, b) => a.cards.length.compareTo(b.cards.length));

    // Posição com empate: quem tem o mesmo número de cartas divide a posição.
    final positions = <String, int>{};
    for (var i = 0; i < ranked.length; i++) {
      final same = i > 0 && ranked[i].cards.length == ranked[i - 1].cards.length;
      positions[ranked[i].id] = same ? positions[ranked[i - 1].id]! : i + 1;
    }

    return Stack(children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              Row(children: [
                RoundIconButton(icon: Icons.arrow_back_rounded, onTap: onLeave, size: 40, tooltip: 'Sair'),
                const Spacer(),
                const MuteButton(),
              ]),
              const SizedBox(height: 4),
              const Center(child: FittedBox(fit: BoxFit.scaleDown, child: Logo(size: 44))),
              const SizedBox(height: 4),
              Center(child: StrokeText('FIM DE JOGO!', size: 40, fill: C.sun, shadow: C.ink)),
              const SizedBox(height: 18),
              _bigLoserCard(losers),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                decoration: inkBox(color: C.cream, radius: 24, shadow: 6),
                child: Column(children: [
                  Text('PLACAR', style: display(20, color: C.ink, letterSpacing: 2)),
                  Text('Menos cartas = melhor', style: body(13, color: C.muted, weight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  for (var i = 0; i < ranked.length; i++)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 450 + i * 120),
                      curve: Curves.easeOutBack,
                      builder: (context, v, child) => Opacity(
                        opacity: v.clamp(0.0, 1.0),
                        child: Transform.translate(offset: Offset((1 - v) * 60, 0), child: child),
                      ),
                      child: _RankRow(
                        position: positions[ranked[i].id] ?? i + 1,
                        p: ranked[i],
                        isMe: ranked[i].id == conn.myId,
                        isLoser: losers.contains(ranked[i]),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 20),
              if (isHost)
                ChunkyButton(
                  label: 'JOGAR DE NOVO',
                  icon: Icons.replay_rounded,
                  color: C.pink,
                  textColor: C.cream,
                  fontSize: 24,
                  height: 64,
                  expand: true,
                  onTap: () => runAct(context, () => conn.act(Logic.toLobby)),
                )
              else
                Text(
                  'Esperando ${s.player(s.hostId)?.name ?? 'o anfitrião'} chamar a revanche...',
                  textAlign: TextAlign.center,
                  style: display(18, color: C.cream),
                ),
              const SizedBox(height: 12),
              ChunkyButton(
                label: 'SAIR',
                color: C.cream2,
                expand: true,
                fontSize: 18,
                onTap: onLeave,
              ),
            ],
          ),
        ),
      ),
      const Positioned.fill(child: Confetti()),
    ]);
  }

  Widget _bigLoserCard(List<Player> losers) {
    final names = losers.map((p) => p.name).toList();
    final title = losers.length > 1 ? 'OS GRANDES VIAJANTES' : 'O GRANDE VIAJANTE';
    final who = names.isEmpty
        ? 'Ninguém! Que família afiada.'
        : names.length == 1
            ? names.first
            : '${names.sublist(0, names.length - 1).join(', ')} e ${names.last}';
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: 0.5 + 0.5 * v, child: child),
      child: Transform.rotate(
        angle: -0.03,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: inkBox(color: C.sun, radius: 26, shadow: 7),
          child: Row(children: [
            const Mascot(size: 92),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: display(17, color: C.ink, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(who, style: display(30, color: C.ink)),
                const SizedBox(height: 4),
                Text(
                  losers.isEmpty
                      ? 'Ninguém levou carta nenhuma.'
                      : 'Levou ${losers.first.cards.length} ${losers.first.cards.length == 1 ? 'carta' : 'cartas'}. '
                          'Todo o resto ganhou!',
                  style: body(14.5, weight: FontWeight.w800),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int position;
  final Player p;
  final bool isMe;
  final bool isLoser;
  const _RankRow({required this.position, required this.p, required this.isMe, required this.isLoser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      decoration: BoxDecoration(
        color: isLoser ? const Color(0xFFFFD6E4) : (position == 1 ? const Color(0xFFDFFBEF) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.ink, width: 2.5),
      ),
      child: Row(children: [
        SizedBox(
          width: 34,
          child: Text('$positionº', style: display(22, color: C.ink)),
        ),
        PlayerChip(p: p, size: 38, showName: false, showCards: false),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isMe ? '${p.name} (você)' : p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: body(17, weight: FontWeight.w900),
          ),
        ),
        if (isLoser) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.rocket_launch_rounded, color: C.pink)),
        CardBadge(count: p.cards.length, size: 24),
      ]),
    );
  }
}
