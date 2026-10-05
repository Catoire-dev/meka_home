import 'package:flutter_test/flutter_test.dart';
import 'package:meka_home/core/utils/number_format.dart';

void main() {
  test('formatEuros utilise la virgule décimale', () {
    expect(formatEuros(129.9), '129,90 €');
  });

  test('parseUserDouble accepte virgule, point et espaces', () {
    expect(parseUserDouble('1 234,50'), 1234.5);
    expect(parseUserDouble('12.3'), 12.3);
    expect(parseUserDouble(''), isNull);
    expect(parseUserDouble('abc'), isNull);
  });

  test('parseUserInt tolère les espaces', () {
    expect(parseUserInt('45 000'), 45000);
    expect(parseUserInt('  '), isNull);
    expect(parseUserInt('12,5'), isNull);
  });
}
