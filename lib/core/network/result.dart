import '../errors/failure.dart';

/// Résultat typé d'un appel repository : succès avec donnée, ou échec avec
/// [Failure]. Évite que les exceptions réseau ne remontent jusqu'à l'UI.
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Failure failure) = FailureResult<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) => switch (this) {
    Success<T>(:final data) => success(data),
    FailureResult<T>(failure: final f) => failure(f),
  };
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final Failure failure;
}
