import 'api_client.dart';
import 'result.dart';

/// Exécute un appel réseau et normalise toute erreur en [Result.failure]
/// via [ApiClient.mapError], pour que les repositories n'aient jamais à
/// répéter de bloc try/catch.
Future<Result<T>> apiGuard<T>(
  ApiClient client,
  Future<T> Function() action,
) async {
  try {
    return Result.success(await action());
  } catch (error) {
    return Result.failure(client.mapError(error));
  }
}
