import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/breakpoints.dart';
import '../../core/errors/failure.dart';
import '../../core/network/result.dart';
import '../../core/widgets/empty_hint.dart';
import '../../core/widgets/error_retry_view.dart';
import '../../models/organization/organization.dart';
import '../../repositories/api_organization_repository.dart';
import 'organization_archive.dart';
import 'organization_filter.dart';
import 'widgets/organization_card.dart';

/// Écran « Mes garages » : liste des organisations (garages, intervenants,
/// « Moi-même »), actives ou archivées selon le filtre.
class OrganizationsScreen extends ConsumerStatefulWidget {
  const OrganizationsScreen({super.key});

  @override
  ConsumerState<OrganizationsScreen> createState() =>
      _OrganizationsScreenState();
}

class _OrganizationsScreenState extends ConsumerState<OrganizationsScreen> {
  final _searchController = TextEditingController();
  bool _showArchived = false;
  bool _searching = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _closeSearch() {
    _searchController.clear();
    setState(() {
      _searching = false;
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final organizationsAsync = ref.watch(organizationsProvider);
    // Sur petit écran, la recherche ouverte prend toute la place du titre.
    final isCompact =
        AppBreakpoints.classify(MediaQuery.sizeOf(context).width) ==
        AppWindowClass.compact;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (!_searching || !isCompact) ...[
              const Text('Mes garages'),
              const SizedBox(width: 8),
            ],
            if (_searching)
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isCompact ? double.infinity : 360,
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un garage',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 36,
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Fermer la recherche',
                        icon: const Icon(Icons.close, size: 18),
                        visualDensity: VisualDensity.compact,
                        onPressed: _closeSearch,
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
              )
            else
              IconButton(
                tooltip: 'Rechercher',
                icon: const Icon(Icons.search),
                onPressed: () => setState(() => _searching = true),
              ),
          ],
        ),
        actions: [
          const Text('Archivés'),
          const SizedBox(width: 8),
          Switch(
            value: _showArchived,
            onChanged: (value) => setState(() => _showArchived = value),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Recharger',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(organizationsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nouveau garage',
        onPressed: () => context.push('/garages/new'),
        child: const Icon(Icons.add),
      ),
      body: organizationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorRetryView(
          failure: UnknownFailure('$error'),
          onRetry: () => ref.invalidate(organizationsProvider),
        ),
        data: (result) => switch (result) {
          FailureResult(:final failure) => ErrorRetryView(
            failure: failure,
            onRetry: () => ref.invalidate(organizationsProvider),
          ),
          Success(:final data) => _OrganizationsList(
            organizations: filterOrganizations(
              data,
              query: _query,
              showArchived: _showArchived,
            ),
            emptyMessage: _query.trim().isNotEmpty
                ? 'Aucun garage ne correspond à la recherche.'
                : _showArchived
                ? 'Aucun garage archivé.'
                : 'Aucun garage enregistré.',
          ),
        },
      ),
    );
  }
}

class _OrganizationsList extends ConsumerWidget {
  const _OrganizationsList({
    required this.organizations,
    required this.emptyMessage,
  });

  final List<Organization> organizations;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (organizations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: EmptyHint(emptyMessage),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: organizations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final organization = organizations[index];
        return OrganizationCard(
          organization: organization,
          onTap: () => context.push('/garages/${organization.id}'),
          onEdit: () => context.push('/garages/${organization.id}/edit'),
          onToggleArchived: () => setOrganizationArchived(
            context,
            ref,
            organization,
            archived: !organization.isArchived,
          ),
        );
      },
    );
  }
}
