import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../errors/failure.dart';
import 'result.dart';

/// Échec d'un rechargement dont les données précédentes ont été conservées.
///
/// Chaque instance est un événement distinct (pas d'égalité par valeur),
/// pour que deux échecs identiques successifs soient bien tous deux signalés.
class RefreshFailureEvent {
  RefreshFailureEvent(this.failure);

  final Failure failure;
}

class RefreshFailureNotifier extends Notifier<RefreshFailureEvent?> {
  @override
  RefreshFailureEvent? build() => null;

  void report(Failure failure) => state = RefreshFailureEvent(failure);
}

/// Dernier échec de rechargement masqué par [StickyResultNotifier], écouté
/// par l'UI pour afficher un message non bloquant (toast).
final refreshFailureProvider =
    NotifierProvider<RefreshFailureNotifier, RefreshFailureEvent?>(
      RefreshFailureNotifier.new,
    );

/// Charge un [Result] et, si un rechargement échoue faute de joindre le
/// serveur ([NetworkFailure]) alors que des données avaient déjà été obtenues, conserve ces données au lieu d'exposer
/// l'échec : la vue reste affichée et l'échec est signalé via
/// [refreshFailureProvider].
///
/// Au premier chargement (aucune donnée précédente), l'échec est exposé
/// normalement pour que l'écran affiche son état d'erreur.
class StickyResultNotifier<T> extends AsyncNotifier<Result<T>> {
  StickyResultNotifier(this._fetch);

  final Future<Result<T>> Function(Ref ref) _fetch;

  @override
  Future<Result<T>> build() async {
    final previous = state.value;
    final result = await _fetch(ref);
    if (result is FailureResult<T> &&
        result.failure is NetworkFailure &&
        previous is Success<T>) {
      ref.read(refreshFailureProvider.notifier).report(result.failure);
      return previous;
    }
    return result;
  }
}

AsyncNotifierProvider<StickyResultNotifier<T>, Result<T>>
stickyResultProvider<T>(Future<Result<T>> Function(Ref ref) fetch) =>
    AsyncNotifierProvider<StickyResultNotifier<T>, Result<T>>(
      () => StickyResultNotifier<T>(fetch),
    );

AsyncNotifierProviderFamily<StickyResultNotifier<T>, Result<T>, A>
stickyResultProviderFamily<T, A>(
  Future<Result<T>> Function(Ref ref, A arg) fetch,
) => AsyncNotifierProvider.family<StickyResultNotifier<T>, Result<T>, A>(
  (arg) => StickyResultNotifier<T>((ref) => fetch(ref, arg)),
);
