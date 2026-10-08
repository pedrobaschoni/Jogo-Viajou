import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

/// Pede o código de 4 letras da sala.
Future<String?> showCodeSheet(BuildContext context, {String? initial}) {
  final ctrl = TextEditingController(text: initial ?? '');
  return showStyledSheet<String>(
    context,
    (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        final ok = ctrl.text.length == 4;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('CÓDIGO DA SALA', textAlign: TextAlign.center, style: display(28, color: C.ink)),
            const SizedBox(height: 6),
            Text('São 4 letras. Quem criou a sala vê o código na tela.',
                textAlign: TextAlign.center, style: body(15, weight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              textAlign: TextAlign.center,
              maxLength: 4,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')), _UpperCase()],
              style: display(44, color: C.ink, letterSpacing: 14),
              decoration: fieldDeco('ABCD').copyWith(
                hintStyle: display(44, color: const Color(0xFFD8CFE8), letterSpacing: 14),
              ),
              onChanged: (_) => setS(() {}),
              onSubmitted: (v) {
                if (v.length == 4) Navigator.of(ctx).pop(v.toUpperCase());
              },
            ),
            const SizedBox(height: 16),
            ChunkyButton(
              label: 'ENTRAR',
              icon: Icons.login_rounded,
              color: C.sun,
              expand: true,
              onTap: ok ? () => Navigator.of(ctx).pop(ctrl.text.toUpperCase()) : null,
            ),
          ],
        );
      },
    ),
  );
}

/// Formulário de pergunta da família.
Future<Question?> showFamilySheet(BuildContext context, {required String author}) {
  final qCtrl = TextEditingController();
  final aCtrl = TextEditingController();
  final uCtrl = TextEditingController();
  final fCtrl = TextEditingController();
  String? error;

  return showStyledSheet<Question>(
    context,
    (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        void submit() {
          final text = qCtrl.text.trim();
          final answer = parseHumanNumber(aCtrl.text);
          if (text.length < 8) {
            setS(() => error = 'Escreve a pergunta completa.');
            return;
          }
          if (answer == null || answer < 0) {
            setS(() => error = 'A resposta precisa ser um número (ex: 12, 1.500 ou 3,5).');
            return;
          }
          final unit = uCtrl.text.trim().toLowerCase();
          Navigator.of(ctx).pop(Question(
            id: 'f${DateTime.now().microsecondsSinceEpoch}',
            cat: 'familia',
            text: text.endsWith('?') ? text : '$text?',
            answer: answer,
            unit: unit,
            fact: fCtrl.text.trim(),
            author: author,
          ));
        }

        Widget unitChip(String u, String label) => GestureDetector(
              onTap: () => setS(() => uCtrl.text = u),
              child: Pill(label, color: uCtrl.text == u ? C.pink : C.lilac, textColor: C.ink, size: 13),
            );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('PERGUNTA DA FAMÍLIA', textAlign: TextAlign.center, style: display(26, color: C.ink)),
            const SizedBox(height: 6),
            Text(
              'Algo que só a família sabe, e cuja resposta seja um número. '
              'Ex: "Quantos anos a vó tinha quando casou?"',
              textAlign: TextAlign.center,
              style: body(14.5, weight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: qCtrl,
              maxLength: 140,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: body(17, weight: FontWeight.w800),
              decoration: fieldDeco('Quantas vezes o tio já...', label: 'Pergunta'),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: aCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  style: body(18, weight: FontWeight.w900),
                  decoration: fieldDeco('12', label: 'Resposta'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: uCtrl,
                  maxLength: 20,
                  style: body(17, weight: FontWeight.w800),
                  decoration: fieldDeco('vezes', label: 'Unidade'),
                  onChanged: (_) => setS(() {}),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              unitChip('ano', 'É UM ANO'),
              unitChip('anos', 'ANOS'),
              unitChip('vezes', 'VEZES'),
              unitChip('reais', 'REAIS'),
              unitChip('km', 'KM'),
              unitChip('', 'SEM UNIDADE'),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: fCtrl,
              maxLength: 140,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              style: body(15, weight: FontWeight.w700),
              decoration: fieldDeco('Conta a história por trás (opcional)', label: 'Curiosidade'),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, textAlign: TextAlign.center, style: body(14, color: C.pink, weight: FontWeight.w900)),
            ],
            const SizedBox(height: 14),
            ChunkyButton(
              label: 'ADICIONAR',
              icon: Icons.add_rounded,
              color: C.mint,
              expand: true,
              onTap: submit,
            ),
          ],
        );
      },
    ),
  );
}

/// Como jogar.
Future<void> showHowTo(BuildContext context) {
  Widget step(int n, String title, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: inkBox(color: playerColor(n + 1), radius: 18, shadow: 2, border: 2.5),
            child: Text('$n', style: display(19, color: C.ink)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: display(19, color: C.ink)),
              const SizedBox(height: 2),
              Text(text, style: body(15, weight: FontWeight.w600)),
            ]),
          ),
        ]),
      );

  return showStyledSheet<void>(
    context,
    (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('COMO JOGAR', textAlign: TextAlign.center, style: display(30, color: C.ink)),
        const SizedBox(height: 16),
        step(1, 'Vira a carta', 'Aparece uma pergunta cuja resposta é um número. Ninguém precisa saber a resposta.'),
        step(2, 'Dá um chute', 'Seu chute quer dizer: "a resposta é PELO MENOS isso". O primeiro chute é livre.'),
        step(3, 'Sobe ou duvida', 'Na sua vez, chute mais alto que o último... ou grite VIAJOU! se achar que o último chute passou da conta.'),
        step(4, 'Revela', 'Se a resposta for menor que o chute, quem chutou viajou e leva a carta. Se não, quem gritou leva.'),
        step(5, 'Fim de jogo', 'Quando as cartas acabam, quem tiver MAIS cartas é o Grande Viajante. Todo o resto ganha!'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: inkBox(color: C.cream2, radius: 18, shadow: 3),
          child: Text(
            'Dica: quem leva a carta começa a próxima rodada. '
            'E nas Perguntas da Família, quem escreveu sabe a resposta, então fique de olho!',
            style: body(14.5, weight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 16),
        ChunkyButton(
          label: 'BORA!',
          color: C.pink,
          textColor: C.cream,
          expand: true,
          onTap: () => Navigator.of(ctx).pop(),
        ),
      ],
    ),
  );
}
