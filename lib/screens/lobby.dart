import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/questions.dart';
import '../logic.dart';
import '../models.dart';
import '../net/room.dart';
import '../prefs.dart';
import '../sfx.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import 'sheets.dart';

class LobbyView extends StatefulWidget {
  final RoomConnection conn;
  final GameState s;
  final VoidCallback onLeave;
  const LobbyView({super.key, required this.conn, required this.s, required this.onLeave});

  @override
  State<LobbyView> createState() => _LobbyViewState();
}

class _LobbyViewState extends State<LobbyView> {
  final _newName = TextEditingController();

  RoomConnection get conn => widget.conn;
  GameState get s => widget.s;
  bool get isHost => conn.isLocal || s.hostId == conn.myId;

  @override
  void dispose() {
    _newName.dispose();
    super.dispose();
  }

  Future<void> _act(GameState Function(GameState s) f) => runAct(context, () => conn.act(f));

  void _addLocalPlayer() {
    final n = _newName.text.trim();
    if (n.isEmpty) return;
    final p = Player(
      id: 'L${DateTime.now().microsecondsSinceEpoch}',
      name: n,
      color: s.players.length % playerColors.length,
    );
    _act((st) => Logic.join(st, p));
    _newName.clear();
  }

  Future<void> _start() async {
    if (conn.isLocal) Prefs.localNames = s.players.map((p) => p.name).toList();
    await _act((st) => Logic.start(st, Bank.all));
  }

  Future<void> _addFamily() async {
    final me = s.player(conn.myId);
    final q = await showFamilySheet(context, author: me?.name ?? 'Família');
    if (q == null || !mounted) return;
    final ok = await runAct(context, () => conn.act((st) => Logic.addCustom(st, q)));
    if (ok && mounted) {
      Sfx.play('join');
      toast(context, 'Pergunta adicionada! Ela vai cair na partida.', color: C.mint);
    }
  }

  void _copyInvite() {
    final code = s.code;
    final link = kIsWeb ? '${Uri.base.origin}${Uri.base.path}?sala=$code' : code;
    Clipboard.setData(ClipboardData(text: kIsWeb ? 'Bora jogar VIAJOU! Entra aqui: $link' : code));
    toast(context, kIsWeb ? 'Convite copiado! Manda no grupo da família.' : 'Código copiado!', color: C.mint);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(children: [
                RoundIconButton(icon: Icons.arrow_back_rounded, onTap: widget.onLeave, tooltip: 'Sair'),
                const SizedBox(width: 12),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: StrokeText(conn.isLocal ? 'CELULAR ÚNICO' : 'SALA', size: 32, fill: C.sun),
                  ),
                ),
                const MuteButton(),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                children: [
                  if (!conn.isLocal) ...[_codeCard(), const SizedBox(height: 16)],
                  _playersCard(),
                  const SizedBox(height: 16),
                  _settingsCard(),
                  const SizedBox(height: 16),
                  _familyCard(),
                ],
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _codeCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: inkBox(color: C.sun, radius: 24, shadow: 6),
      child: Column(children: [
        Text('CÓDIGO DA SALA', style: display(16, color: C.ink, letterSpacing: 2)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < s.code.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Transform.rotate(
                  angle: (i.isEven ? -1 : 1) * 0.06,
                  child: Container(
                    width: 58,
                    height: 68,
                    alignment: Alignment.center,
                    decoration: inkBox(color: C.cream, radius: 14, shadow: 4),
                    child: Text(s.code[i], style: display(42, color: C.ink)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          kIsWeb ? 'Manda o link pra galera ou fala o código.' : 'Quem quiser entrar digita esse código.',
          textAlign: TextAlign.center,
          style: body(14.5, weight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ChunkyButton(
          label: kIsWeb ? 'COPIAR CONVITE' : 'COPIAR CÓDIGO',
          icon: Icons.ios_share_rounded,
          color: C.cream,
          fontSize: 18,
          onTap: _copyInvite,
        ),
      ]),
    );
  }

  Widget _playersCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: glassBox(radius: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('JOGADORES  ${s.players.length}/${Logic.maxPlayers}',
            style: display(18, color: C.cream, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            for (final p in s.players)
              TweenAnimationBuilder<double>(
                key: ValueKey(p.id),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, v, child) => Transform.scale(scale: v, child: child),
                child: PlayerChip(
                  p: p,
                  size: 56,
                  showCards: false,
                  isMe: p.id == conn.myId,
                  isHost: !conn.isLocal && p.id == s.hostId,
                  onRemove: (conn.isLocal && s.players.length > 1) || (isHost && p.id != conn.myId)
                      ? () => _act((st) => Logic.remove(st, p.id))
                      : null,
                ),
              ),
          ],
        ),
        if (conn.isLocal && s.players.length < Logic.maxPlayers) ...[
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _newName,
                maxLength: 16,
                textCapitalization: TextCapitalization.words,
                style: body(18, weight: FontWeight.w800),
                decoration: fieldDeco('Nome de quem vai jogar'),
                onSubmitted: (_) => _addLocalPlayer(),
              ),
            ),
            const SizedBox(width: 10),
            ChunkyButton(
              label: '',
              icon: Icons.person_add_alt_1_rounded,
              color: C.mint,
              padding: const EdgeInsets.all(14),
              onTap: _addLocalPlayer,
            ),
          ]),
        ],
        if (!conn.isLocal && s.players.length < 2) ...[
          const SizedBox(height: 14),
          Text('Esperando mais gente entrar...',
              textAlign: TextAlign.center, style: body(14.5, color: C.cream, weight: FontWeight.w700)),
        ],
      ]),
    );
  }

  Widget _settingsCard() {
    final st = s.settings;
    final total = Bank.all.where((q) => st.cats.contains(q.cat)).length + s.custom.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: inkBox(color: C.cream, radius: 24, shadow: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('PARTIDA', style: display(20, color: C.ink, letterSpacing: 1.5))),
          if (!isHost) Pill('SÓ O ANFITRIÃO MUDA', color: C.cream2, textColor: C.muted, size: 11),
        ]),
        const SizedBox(height: 12),
        Text('Quantas cartas?', style: body(15, weight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(children: [
          for (final n in Logic.roundOptions) ...[
            Expanded(
              child: _Choice(
                label: '$n',
                selected: st.rounds == n,
                onTap: isHost ? () => _act((x) => Logic.setSettings(x, x.settings.copyWith(rounds: n))) : null,
              ),
            ),
            if (n != Logic.roundOptions.last) const SizedBox(width: 8),
          ],
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Text('Categorias', style: body(15, weight: FontWeight.w800))),
          Text('$total perguntas', style: body(13, color: C.muted, weight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in cats)
              _CatChip(
                cat: c,
                on: st.cats.contains(c.key),
                count: Bank.count(c.key),
                onTap: isHost
                    ? () => _act((x) {
                          final list = [...x.settings.cats];
                          if (list.contains(c.key)) {
                            list.remove(c.key);
                          } else {
                            list.add(c.key);
                          }
                          return Logic.setSettings(x, x.settings.copyWith(cats: list));
                        })
                    : null,
              ),
          ],
        ),
      ]),
    );
  }

  Widget _familyCard() {
    final me = conn.myId;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: inkBox(color: C.cream2, radius: 24, shadow: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.home_rounded, color: C.ink),
          const SizedBox(width: 6),
          Expanded(child: Text('PERGUNTAS DA FAMÍLIA', style: display(18, color: C.ink, letterSpacing: 1))),
          Pill('${s.custom.length}', color: C.pink, size: 13),
        ]),
        const SizedBox(height: 6),
        Text(
          'Cada um pode criar perguntas sobre a família. Elas entram primeiro no baralho.',
          style: body(14, weight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        for (final q in s.custom)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
            decoration: inkBox(color: C.cream, radius: 14, shadow: 2, border: 2),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(q.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: body(14.5, weight: FontWeight.w800)),
                  Text('por ${q.author ?? 'Família'}  ·  resposta escondida',
                      style: body(12, color: C.muted, weight: FontWeight.w700)),
                ]),
              ),
              if (conn.isLocal || isHost || q.author == s.player(me)?.name)
                IconButton(
                  tooltip: 'Remover',
                  icon: const Icon(Icons.delete_rounded, color: C.ink),
                  onPressed: () => _act((x) => Logic.removeCustom(x, q.id)),
                ),
            ]),
          ),
        Align(
          alignment: Alignment.center,
          child: ChunkyButton(
            label: 'CRIAR PERGUNTA',
            icon: Icons.add_rounded,
            color: C.pink,
            textColor: C.cream,
            fontSize: 18,
            onTap: _addFamily,
          ),
        ),
      ]),
    );
  }

  Widget _footer() {
    final enough = s.players.length >= 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: isHost
          ? ChunkyButton(
              label: enough ? 'COMEÇAR!' : 'PRECISA DE 2 JOGADORES',
              icon: enough ? Icons.play_arrow_rounded : null,
              color: C.pink,
              textColor: C.cream,
              fontSize: 26,
              height: 64,
              expand: true,
              onTap: enough ? _start : null,
            )
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Mascot(size: 54, wave: false),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Esperando ${s.player(s.hostId)?.name ?? 'o anfitrião'} começar...',
                  style: display(19, color: C.cream),
                ),
              ),
            ]),
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _Choice({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              Sfx.play('key', volume: 0.5);
              onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 46,
        alignment: Alignment.center,
        decoration: inkBox(color: selected ? C.ink : Colors.white, radius: 14, shadow: selected ? 0 : 3),
        child: Text(label, style: display(22, color: selected ? C.sun : C.ink)),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final Cat cat;
  final bool on;
  final int count;
  final VoidCallback? onTap;
  const _CatChip({required this.cat, required this.on, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              Sfx.play('key', volume: 0.5);
              onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: on ? cat.color : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? C.ink : C.disabled, width: 2.5),
          boxShadow: on ? const [BoxShadow(color: C.ink, offset: Offset(2, 2))] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(on ? cat.icon : Icons.block_rounded, size: 17, color: on ? C.ink : C.disabled),
          const SizedBox(width: 5),
          Text(cat.name, style: body(14, color: on ? C.ink : C.disabled, weight: FontWeight.w900)),
          const SizedBox(width: 5),
          Text('$count', style: body(12, color: on ? C.ink.withValues(alpha: 0.6) : C.disabled, weight: FontWeight.w800)),
        ]),
      ),
    );
  }
}
