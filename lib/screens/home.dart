import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../logic.dart';
import '../models.dart';
import '../net/room.dart';
import '../prefs.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/starfield.dart';
import 'room.dart';
import 'sheets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _name = TextEditingController(text: Prefs.name);
  late int _color = Prefs.color % playerColors.length;
  bool _busy = false;
  String? _linkCode;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      final c = Uri.base.queryParameters['sala'];
      if (c != null && RegExp(r'^[A-Za-z]{4}$').hasMatch(c)) _linkCode = c.toUpperCase();
    }
    final last = Prefs.lastRoom;
    if (_linkCode == null && Online.ready && last.length == 4) _linkCode = last;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Player? _me() {
    final n = _name.text.trim();
    if (n.isEmpty) {
      toast(context, 'Coloca seu nome primeiro!');
      return null;
    }
    Prefs.name = n;
    Prefs.color = _color;
    return Player(id: Prefs.id, name: n, color: _color);
  }

  bool _onlineOk() {
    if (Online.ready) return true;
    toast(context, 'O modo online ainda não foi configurado (veja o README). Dá pra jogar no modo celular único!',
        color: C.pink);
    return false;
  }

  void _open(RoomConnection conn) {
    if (conn is OnlineRoom) Prefs.lastRoom = conn.ref.id;
    Navigator.of(context)
        .push(PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, anim, secondary) => RoomScreen(conn: conn),
          transitionsBuilder: (context, anim, secondary, child) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.06, end: 1.0)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        ))
        .then((_) {
      if (mounted) setState(() => _linkCode = null);
    });
  }

  Future<void> _create() async {
    final me = _me();
    if (me == null || !_onlineOk()) return;
    setState(() => _busy = true);
    try {
      final room = await RoomService.create(me);
      if (!mounted) {
        room.dispose();
        return;
      }
      setState(() => _busy = false);
      _open(room);
    } on GameError catch (e) {
      if (mounted) toast(context, e.message);
    } catch (e) {
      debugPrint('Erro criando sala: $e');
      if (mounted) toast(context, 'Não consegui falar com o servidor. Confere a internet!', color: C.pink);
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  Future<void> _join([String? code]) async {
    final me = _me();
    if (me == null || !_onlineOk()) return;
    code ??= await showCodeSheet(context, initial: _linkCode);
    if (code == null || code.length != 4 || !mounted) return;
    setState(() => _busy = true);
    try {
      final room = await RoomService.join(code, me);
      if (!mounted) {
        room.dispose();
        return;
      }
      setState(() => _busy = false);
      _open(room);
    } on GameError catch (e) {
      if (mounted) toast(context, e.message);
    } catch (e) {
      debugPrint('Erro entrando na sala: $e');
      if (mounted) toast(context, 'Não consegui entrar na sala. Confere a internet!', color: C.pink);
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  void _local() {
    final typed = _name.text.trim();
    if (typed.isNotEmpty) Prefs.name = typed;
    final saved = Prefs.localNames;
    final names = saved.isNotEmpty ? saved : [typed.isNotEmpty ? typed : 'Jogador 1'];
    final players = [
      for (var i = 0; i < names.length; i++)
        Player(id: 'L$i', name: names[i], color: i % playerColors.length),
    ];
    var s = Logic.create('LOCAL', players.first);
    for (final p in players.skip(1)) {
      s = Logic.join(s, p);
    }
    _open(LocalRoom(s));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final short = size.height < 720;
    return Scaffold(
      body: PageFrame(
        maxWidth: 460,
        child: LayoutBuilder(
          builder: (context, cons) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: cons.maxHeight - 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Align(alignment: Alignment.centerRight, child: MuteButton()),
                  Mascot(size: short ? 120 : 165),
                  FittedBox(fit: BoxFit.scaleDown, child: Logo(size: short ? 54 : 66)),
                  const SizedBox(height: 10),
                  Text(
                    'Chute alto, blefe bonito\ne não viaje demais.',
                    textAlign: TextAlign.center,
                    style: body(17, color: C.cream, weight: FontWeight.w800),
                  ),
                  SizedBox(height: short ? 18 : 26),
                  _nameCard(),
                  const SizedBox(height: 20),
                  if (_linkCode != null) ...[
                    ChunkyButton(
                      label: 'ENTRAR NA SALA $_linkCode',
                      icon: Icons.login_rounded,
                      color: C.sun,
                      expand: true,
                      fontSize: 24,
                      onTap: _busy ? null : () => _join(_linkCode),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ChunkyButton(
                    label: 'CRIAR SALA',
                    icon: Icons.add_circle_rounded,
                    color: C.pink,
                    textColor: C.cream,
                    expand: true,
                    fontSize: 24,
                    onTap: _busy ? null : _create,
                  ),
                  const SizedBox(height: 12),
                  ChunkyButton(
                    label: 'ENTRAR COM CÓDIGO',
                    icon: Icons.vpn_key_rounded,
                    color: _linkCode != null ? C.cream : C.sun,
                    expand: true,
                    onTap: _busy ? null : () => _join(),
                  ),
                  const SizedBox(height: 12),
                  ChunkyButton(
                    label: 'JOGAR NUM CELULAR SÓ',
                    icon: Icons.smartphone_rounded,
                    color: C.mint,
                    expand: true,
                    onTap: _busy ? null : _local,
                  ),
                  const SizedBox(height: 18),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: CircularProgressIndicator(color: C.pink),
                    ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => showHowTo(context),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.help_rounded, color: C.sun),
                        const SizedBox(width: 6),
                        Text('Como jogar?', style: display(20, color: C.sun)),
                      ]),
                    ),
                  ),
                  if (!Online.ready) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Modo online desligado: falta configurar o Firebase (veja o README).',
                      textAlign: TextAlign.center,
                      style: body(12.5, color: C.cream.withValues(alpha: 0.7), weight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: inkBox(color: C.cream, radius: 24, shadow: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('COMO VOCÊ SE CHAMA?', style: display(17, color: C.ink, letterSpacing: 1)),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            maxLength: 16,
            textCapitalization: TextCapitalization.words,
            style: body(20, weight: FontWeight.w900),
            decoration: fieldDeco('Seu nome'),
            onChanged: (v) => Prefs.name = v.trim(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < playerColors.length; i++)
                GestureDetector(
                  onTap: () {
                    setState(() => _color = i);
                    Prefs.color = i;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: playerColors[i],
                      shape: BoxShape.circle,
                      border: Border.all(color: C.ink, width: _color == i ? 4 : 2.5),
                      boxShadow: _color == i ? const [BoxShadow(color: C.ink, offset: Offset(2, 2))] : null,
                    ),
                    child: _color == i ? const Icon(Icons.check_rounded, color: C.ink, size: 20) : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
