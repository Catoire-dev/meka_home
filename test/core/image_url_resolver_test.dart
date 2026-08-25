import 'package:flutter_test/flutter_test.dart';
import 'package:meka_home/core/media/image_url_resolver.dart';

void main() {
  final resolver = ImageUrlResolver();

  test('resolve renvoie null si aucun nom de fichier', () {
    expect(resolver.resolve(null), isNull);
    expect(resolver.resolve(''), isNull);
  });

  test('resolve construit une URL à partir du nom de fichier', () {
    expect(
      resolver.resolve('twingo.jpg'),
      'http://localhost:8000/uploads/twingo.jpg',
    );
  });
}
