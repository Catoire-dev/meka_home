import 'dart:async';

import 'package:flutter/material.dart';

import '../errors/failure.dart';

/// Affiche une erreur de chargement avec un bouton « Réessayer ».
///
/// Pour une [NetworkFailure] (serveur injoignable), relance aussi [onRetry]
/// automatiquement toutes les [autoRetryInterval], tant que le widget est
/// affiché : l'app se reconnecte seule dès que le backend redevient
/// disponible. Le contenu est scrollable pour rester compatible avec un
/// `RefreshIndicator` parent (tirer pour rafraîchir).
class ErrorRetryView extends StatefulWidget {
  const ErrorRetryView({
    super.key,
    required this.failure,
    required this.onRetry,
    this.autoRetryInterval = const Duration(seconds: 10),
  });

  final Failure failure;
  final VoidCallback onRetry;
  final Duration autoRetryInterval;

  @override
  State<ErrorRetryView> createState() => _ErrorRetryViewState();
}

class _ErrorRetryViewState extends State<ErrorRetryView> {
  Timer? _timer;
  int _secondsLeft = 0;

  bool get _autoRetries => widget.failure is NetworkFailure;

  @override
  void initState() {
    super.initState();
    _restartCountdown();
  }

  @override
  void didUpdateWidget(ErrorRetryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.failure.runtimeType != widget.failure.runtimeType) {
      _restartCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restartCountdown() {
    _timer?.cancel();
    _timer = null;
    if (!_autoRetries) return;

    _secondsLeft = widget.autoRetryInterval.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
        return;
      }
      setState(() => _secondsLeft = widget.autoRetryInterval.inSeconds);
      widget.onRetry();
    });
  }

  void _retryNow() {
    widget.onRetry();
    _restartCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _autoRetries ? Icons.cloud_off : Icons.error_outline,
                    size: 40,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(widget.failure.message, textAlign: TextAlign.center),
                  if (_autoRetries) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Nouvelle tentative dans $_secondsLeft s',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: _retryNow,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
