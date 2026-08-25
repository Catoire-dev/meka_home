/// Erreur métier normalisée, indépendante de la source (Dio, parsing, etc.).
///
/// Les repositories ne laissent jamais remonter d'exception brute vers
/// l'UI : toute erreur réseau ou serveur est convertie en [Failure].
sealed class Failure {
  const Failure(this.message);

  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Impossible de contacter le serveur.']);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Ressource introuvable.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Une erreur inattendue est survenue.']);
}
