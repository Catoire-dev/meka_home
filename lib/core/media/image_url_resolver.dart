import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';

final imageUrlResolverProvider = Provider<ImageUrlResolver>(
  (ref) => ImageUrlResolver(),
);

/// Seul point de l'app qui sait comment un nom de fichier stocké devient
/// une URL affichable. Le backend ne fournit qu'un nom de fichier ; si le
/// stockage change (S3, CDN...), seule cette classe est à adapter.
class ImageUrlResolver {
  ImageUrlResolver({AppConfig config = AppConfig.current})
    : _baseUrl = config.mediaBaseUrl;

  final String _baseUrl;

  String? resolve(String? filename) {
    if (filename == null || filename.isEmpty) return null;
    return '$_baseUrl/$filename';
  }
}
