import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../errors/failure.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Point d'entrée HTTP unique de l'application.
///
/// Les services API (`services/api/`) sont les seuls consommateurs de cette
/// classe : aucun repository ni widget ne doit importer `dio` directement.
class ApiClient {
  ApiClient({AppConfig config = AppConfig.current})
    : _dio = Dio(
        BaseOptions(
          baseUrl: config.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      ) {
    if (config.isDevelopment) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  final Dio _dio;

  Dio get dio => _dio;

  /// Convertit une erreur Dio en [Failure] métier normalisée.
  Failure mapError(Object error) {
    if (error is! DioException) return const UnknownFailure();

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) return const NotFoundFailure();
        return ServerFailure(
          error.response?.statusMessage ?? 'Erreur serveur.',
          statusCode: statusCode,
        );
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
      default:
        return const UnknownFailure();
    }
  }
}
