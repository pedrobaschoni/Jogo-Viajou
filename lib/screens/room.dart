import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic.dart';
import '../models.dart';
import '../net/room.dart';
import '../prefs.dart';
import '../sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/starfield.dart';
import 'end.dart';
import 'game.dart';
import 'lobby.dart';

/// Tela da sala: escolhe entre lobby, jogo e fim conforme a fase,
/// e toca os sons quando algo muda (inclusive jogadas de outros celulares).
class RoomScreen extends StatefulWidget {
  final RoomConnection conn;
  const RoomScreen({super.key, required this.conn});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  GameState? _prev;
  bool _leaving = false;

  RoomConnection get conn => widget.conn;

  @override
  void initState() {
    super.initState();
    _prev = conn.state.value;
    conn.state.addListener(_onState);
    final c = conn;
    if (c is OnlineRoom) c.gone.addListener(_onGone);
  }

  @override
  void dispose() {
    conn.state.removeListener(_onState);
    final c = conn;
    if (c is OnlineRoom) c.gone.removeListener(_onGone);
    conn.dispose();
    super.dispose();
  }

  void _onGone() {
    if (!mounted || _leaving) return;
    _leaving = true;
    toast(context, 'A sala foi fechada.');
    Navigator.of(context).pop();
  }

  void _onState() {
    final s = conn.state.value;
    final p = _prev;
    _prev = s;
    if (s == null || p == null || !mounted) return;

    final me = conn.myId;
    if (me != null && p.player(me) != null && s.player(me) == null) {
      if (!_leaving) {
        _leaving = true;
        toast(context, 'Você saiu da sala.');
        Navigator.of(context).pop();
      }
      return;
    }

    if (s.phase == Phase.lobby && s.players.length > p.players.length) Sfx.play('join');
    if (s.phase == Phase.bidding && s.round == p.round && s.bids.length > p.bids.length) {
      Sfx.play('bid');
    }
    if (me != null && s.phase == Phase.bidding && s.turn == me && p.turn != me) {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 250), () => Sfx.play('yourturn', volume: 0.8));
    }
    if (s.phase == Phase.reveal && p.phase != Phase.reveal) {
      HapticFeedback.heavyImpact();
      Sfx.play('viajou');
    }
    if (s.phase == Phase.end && p.phase != Phase.end) Sfx.play('fanfare');
  }

  Future<void> _leave() async {
    final s = conn.state.value;
    final playing = s != null && s.phase != Phase.lobby;
    final ok = await confirmDialog(
      context,
      'SAIR DA SALA?',
      conn.isLocal
          ? 'A partida deste celular vai acabar.'
          : playing
              ? 'O jogo continua sem você. Dá pra voltar depois com o mesmo código.'
              : 'Você vai sair da lista de jogadores.',
    );
    if (!ok || !mounted) return;
    _leaving = true;
    if (!conn.isLocal) Prefs.lastRoom = '';
    final me = conn.myId;
    if (!conn.isLocal && me != null && s != null && s.phase == Phase.lobby) {
      try {
        await conn.act((st) => Logic.remove(st, me));
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: Starfield(
          child: SafeArea(
            child: ValueListenableBuilder<GameState?>(
              valueListenable: conn.state,
              builder: (context, s, _) {
                if (s == null) {
                  return const Center(child: CircularProgressIndicator(color: C.pink));
                }
                final Widget view = switch (s.phase) {
                  Phase.lobby => LobbyView(key: const ValueKey('lobby'), conn: conn, s: s, onLeave: _leave),
                  Phase.bidding || Phase.reveal =>
                    GameView(key: const ValueKey('game'), conn: conn, s: s, onLeave: _leave),
                  Phase.end => EndView(key: const ValueKey('end'), conn: conn, s: s, onLeave: _leave),
                };
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1).animate(anim),
                      child: child,
                    ),
                  ),
                  child: view,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
