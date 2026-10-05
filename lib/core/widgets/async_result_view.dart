import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/result.dart';

/// Affiche le contenu d'une section alimentée par un provider
/// `AsyncValue<Result<T>>` : barre de chargement, message d'échec, ou
/// [builder] avec la donnée. Prévu pour les sections d'un écran, pas pour
/// un écran entier (voir `ErrorRetryView`).
class AsyncResultView<T> extends StatelessWidget {
  const AsyncResultView({
    super.key,
    required this.value,
    required this.builder,
  });

  final AsyncValue<Result<T>> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (error, stackTrace) => _ErrorText('$error'),
      data: (result) => switch (result) {
        FailureResult(:final failure) => _ErrorText(failure.message),
        Success(:final data) => builder(data),
      },
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(message, style: TextStyle(color: colorScheme.error));
  }
}
