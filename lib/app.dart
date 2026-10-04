import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/sticky_result_provider.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';

class MekaHomeApp extends ConsumerStatefulWidget {
  const MekaHomeApp({super.key});

  @override
  ConsumerState<MekaHomeApp> createState() => _MekaHomeAppState();
}

class _MekaHomeAppState extends ConsumerState<MekaHomeApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  void _showRefreshFailure(RefreshFailureEvent event) {
    final messenger = _messengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${event.failure.message} Données affichées non actualisées.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    ref.listen(refreshFailureProvider, (previous, next) {
      if (next != null) _showRefreshFailure(next);
    });

    return MaterialApp.router(
      title: 'Meka Home',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      scaffoldMessengerKey: _messengerKey,
      routerConfig: router,
    );
  }
}
