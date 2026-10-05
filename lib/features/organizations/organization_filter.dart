import '../../models/organization/organization.dart';

/// Filtre la liste « Mes garages » : uniquement les archivés si
/// [showArchived], sinon uniquement les actifs ; puis recherche texte
/// (insensible à la casse) sur le nom, le type, la ville et les numéros de
/// téléphone.
List<Organization> filterOrganizations(
  List<Organization> organizations, {
  required String query,
  required bool showArchived,
}) {
  final normalizedQuery = query.trim().toLowerCase();

  return organizations.where((organization) {
    if (organization.isArchived != showArchived) return false;
    if (normalizedQuery.isEmpty) return true;
    return [
      organization.name,
      ?organization.type?.name,
      ?organization.address?.city,
      ?organization.phone,
      ?organization.mobile,
    ].any((value) => value.toLowerCase().contains(normalizedQuery));
  }).toList();
}
