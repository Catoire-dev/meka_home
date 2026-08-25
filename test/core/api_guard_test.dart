import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meka_home/core/errors/failure.dart';
import 'package:meka_home/core/network/api_client.dart';
import 'package:meka_home/core/network/api_guard.dart';

void main() {
  final client = ApiClient();

  test('apiGuard renvoie Success quand l\'action réussit', () async {
    final result = await apiGuard(client, () async => 42);

    expect(
      result.when(success: (v) => v, failure: (_) => -1),
      42,
    );
  });

  test('apiGuard convertit une DioException 404 en NotFoundFailure', () async {
    final result = await apiGuard<int>(client, () async {
      throw DioException(
        requestOptions: RequestOptions(path: '/vehicles/unknown'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/vehicles/unknown'),
          statusCode: 404,
        ),
      );
    });

    expect(
      result.when(success: (_) => null, failure: (f) => f),
      isA<NotFoundFailure>(),
    );
  });

  test('apiGuard convertit un timeout de connexion en NetworkFailure', () async {
    final result = await apiGuard<int>(client, () async {
      throw DioException(
        requestOptions: RequestOptions(path: '/vehicles'),
        type: DioExceptionType.connectionTimeout,
      );
    });

    expect(
      result.when(success: (_) => null, failure: (f) => f),
      isA<NetworkFailure>(),
    );
  });
}
