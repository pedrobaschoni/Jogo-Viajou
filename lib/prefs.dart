import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Lembra nome, cor e id deste aparelho (para voltar à sala depois de recarregar a página).
class Prefs {
  static SharedPreferences? _p;
  static final Map<String, Object> _mem = {};

  static Future<void> init() async {
    try {
      _p = await SharedPreferences.getInstance();
    } catch (_) {
      _p = null;
    }
  }

  static String? _getString(String k) => _p?.getString(k) ?? _mem[k] as String?;
  static void _setString(String k, String v) {
    _mem[k] = v;
    _p?.setString(k, v);
  }

  static String get id {
    var v = _getString('id');
    if (v == null) {
      final r = Random();
      v = List.generate(12, (_) => r.nextInt(36).toRadixString(36)).join();
      _setString('id', v);
    }
    return v;
  }

  /// Última sala online (para voltar depois de recarregar a página).
  static String get lastRoom => _getString('lastRoom') ?? '';
  static set lastRoom(String v) => _setString('lastRoom', v);

  static String get name => _getString('name') ?? '';
  static set name(String v) => _setString('name', v);

  static int get color => _p?.getInt('color') ?? (_mem['color'] as int?) ?? 0;
  static set color(int v) {
    _mem['color'] = v;
    _p?.setInt('color', v);
  }

  static bool get muted => _p?.getBool('muted') ?? (_mem['muted'] as bool?) ?? false;
  static set muted(bool v) {
    _mem['muted'] = v;
    _p?.setBool('muted', v);
  }

  static List<String> get localNames =>
      _p?.getStringList('localNames') ?? (_mem['localNames'] as List<String>?) ?? const [];
  static set localNames(List<String> v) {
    _mem['localNames'] = v;
    _p?.setStringList('localNames', v);
  }
}
