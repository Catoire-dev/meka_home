import 'package:dio/dio.dart';

/// Rejoue automatiquement les requêtes de lecture ayant échoué faute de
/// pouvoir joindre le serveur (backend redémarré, réseau coupé un instant).
///
/// Limité aux méthodes sans effet de bord (GET/HEAD) pour ne jamais créer
/// de doublon côté backend, et aux erreurs de connexion : une réponse HTTP
/// en erreur (4xx/5xx) n'est pas rejouée.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.retryDelays = const [Duration(seconds: 1), Duration(seconds: 2)],
  });

  /// Instance à laquelle l'intercepteur est attaché, utilisée pour rejouer.
  final Dio dio;

  /// Délai avant chaque nouvelle tentative ; sa longueur fixe le nombre
  /// maximal de tentatives supplémentaires.
  final List<Duration> retryDelays;

  static const _attemptKey = 'retry_attempt';
  static const _idempotentMethods = {'GET', 'HEAD'};

  bool _shouldRetry(DioException error) {
    final method = error.requestOptions.method.toUpperCase();
    if (!_idempotentMethods.contains(method)) return false;
    return switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout => true,
      _ => false,
    };
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;
    if (!_shouldRetry(err) || attempt >= retryDelays.length) {
      return handler.next(err);
    }

    await Future<void>.delayed(retryDelays[attempt]);
    final options = err.requestOptions..extra[_attemptKey] = attempt + 1;
    try {
      final response = await dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }
}
