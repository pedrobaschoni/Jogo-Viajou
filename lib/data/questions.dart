import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../theme.dart';

/// Banco de perguntas embutido (assets/questions.json).
class Bank {
  static List<Question> all = const [];

  static Future<void> load() async {
    try {
      final raw = await rootBundle.loadString('assets/questions.json');
      final list = jsonDecode(raw) as List<dynamic>;
      all = list.map((e) => Question.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      debugPrint('Não consegui carregar as perguntas: $e');
    }
  }

  static int count(String cat) => all.where((q) => q.cat == cat).length;
}

class Cat {
  final String key;
  final String name;
  final Color color;
  final IconData icon;
  const Cat(this.key, this.name, this.color, this.icon);
}

const cats = <Cat>[
  Cat('brasil', 'Brasil', Color(0xFF7BE36B), Icons.flag_rounded),
  Cat('corpo', 'Corpo Humano', Color(0xFFFF8FB1), Icons.favorite_rounded),
  Cat('bichos', 'Bichos', C.orange, Icons.pets_rounded),
  Cat('comida', 'Comida', C.sun, Icons.restaurant_rounded),
  Cat('espaco', 'Espaço', C.lilac, Icons.rocket_launch_rounded),
  Cat('esporte', 'Esporte', C.sky, Icons.sports_soccer_rounded),
  Cat('mundo', 'Mundo & História', C.mint, Icons.public_rounded),
  Cat('pop', 'Pop & Tech', Color(0xFF4DD9E8), Icons.videogame_asset_rounded),
  Cat('diaadia', 'Dia a Dia', Color(0xFFFFB86B), Icons.wb_sunny_rounded),
];

const familyCat = Cat('familia', 'Família', C.pink, Icons.home_rounded);

Cat catOf(String key) {
  for (final c in cats) {
    if (c.key == key) return c;
  }
  return familyCat;
}
