import 'package:flutter_test/flutter_test.dart';
import 'package:viajou/format.dart';

void main() {
  test('números no padrão brasileiro', () {
    expect(fmtNum(1234567), '1.234.567');
    expect(fmtNum(13.8), '13,8');
    expect(fmtAnswer(1889, 'ano'), '1889');
    expect(withUnit(92, '%'), '92%');
    expect(withUnit(384400, 'km'), '384.400 km');
  });

  test('lê números digitados por gente', () {
    expect(parseHumanNumber('1.500'), 1500);
    expect(parseHumanNumber('13,8'), 13.8);
    expect(parseHumanNumber('13.8'), 13.8);
    expect(parseHumanNumber('abc'), isNull);
  });
}
