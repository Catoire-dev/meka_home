# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projet

Application Flutter multiplateforme (mobile/tablette/desktop/web) de carnet d'entretien numérique personnel pour un particulier possédant 4-5 véhicules (motos, voitures, autres). Permet de suivre informations administratives (type carte grise), entretiens, documents et kilométrage — y compris pour les anciens véhicules conservés en historique. Ce n'est **pas** un logiciel de gestion de garage professionnel (pas de clients, facturation, ordres de réparation) : l'interface doit rester sobre, moderne, orientée usage personnel.

Backend : API HTTP développée séparément par l'utilisateur, volontairement simple et amenée à évoluer/être remplacée. Base de données MySQL/MariaDB gérée côté backend — Flutter ne s'y connecte jamais directement, uniquement via les endpoints REST.

Arborescence fonctionnelle cible :
```
Accueil     → résumé des véhicules actuels + prochaines échéances
Véhicules   → catégories (Moto / Voiture / Autre, liste backend) → En cours / Historique → recherche, filtres, tri
Véhicule    → infos générales, carte grise, kilométrage, photo, commentaire, entretiens, historique, documents
Mes garages → organisations (garages / intervenants / « Moi-même ») sélectionnables dans les entretiens
```

## Commandes

```bash
flutter pub get                 # installer les dépendances
flutter analyze                 # analyse statique (doit rester à "No issues found")
flutter test                    # tous les tests
flutter test test/models/vehicle_test.dart   # un seul fichier de test
dart run build_runner build --delete-conflicting-outputs   # régénérer les .g.dart après modif d'un modèle @JsonSerializable
flutter run -d chrome           # lancer en dev (web)
flutter run -d macos            # lancer en dev (desktop)
flutter build web --release     # build de vérification rapide (compile-only, sert de sanity check UI)
```

Configuration d'environnement via `--dart-define`, jamais en dur dans le code :
```bash
flutter run --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.example.com --dart-define=MEDIA_BASE_URL=https://api.example.com/uploads
```
Défauts (dev) : `API_BASE_URL=http://localhost:8080`, `MEDIA_BASE_URL=http://localhost:8080/uploads`.

## Architecture

Couches strictes, chacune ignorant celle du dessus (voir `lib/`) :

```
UI (features/)  →  Riverpod providers  →  repositories/  →  services/api/  →  backend HTTP
```

- **`lib/config/app_config.dart`** — environnement + URLs, seul point de vérité pour la config
- **`lib/core/`** — transverse et indépendant du domaine métier :
  - `network/` : `ApiClient` (Dio unique), `Result<T>` (sealed success/failure), `api_guard.dart` (convertit toute exception réseau en `Failure` — évite les try/catch dupliqués dans les repositories)
  - `errors/failure.dart` : hiérarchie `Failure` (`NetworkFailure`, `ServerFailure`, `NotFoundFailure`, `UnknownFailure`)
  - `media/image_url_resolver.dart` : seul point qui transforme un nom de fichier stocké en URL affichable — à adapter si le stockage change (S3, CDN...)
  - `constants/breakpoints.dart` : breakpoints responsive centralisés (`AppWindowClass.compact/medium/expanded`, seuils 600/840)
  - `theme/app_theme.dart` : thème Material 3 clair/sombre
  - `utils/json_parsing.dart` : conversions numériques tolérantes pour les champs dont l'encodage backend peut varier (ex. `cost` DECIMAL parfois sérialisé en string)
  - `widgets/` : composants réutilisables transverses (carte véhicule, placeholder, `ReminderTile`, `AsyncResultView`, `DatePickerField`, `EmptyHint`, `InfoRow`, dialogue de confirmation...) — y placer tout widget dupliqué à 2+ endroits
  - `utils/date_format.dart`, `utils/number_format.dart` : formatage date/montant et parsing des saisies utilisateur
- **`lib/models/`** — un sous-dossier par agrégat (`vehicle/`, `maintenance/`, `document/`, `reminder/`, `organization/`). Sérialisation via `json_serializable` (`@JsonSerializable(fieldRename: FieldRename.snake)` — JSON backend en snake_case, Dart en camelCase). `Reminder` est un modèle **dérivé**, calculé côté app à partir d'un `MaintenanceSchedule` + kilométrage actuel (pas de sérialisation JSON propre) : détermine l'urgence `upcoming`/`dueSoon`/`overdue` (seuils par défaut 30 jours / 1000 km, configurables par appel).
- **`lib/services/api/`** — HTTP brut (Dio → JSON), aucune connaissance des modèles Dart. Un service par agrégat.
- **`lib/repositories/`** — interface abstraite (`abstract interface class XxxRepository`) + implémentation `ApiXxxRepository` qui convertit JSON ↔ modèles et retourne `Result<T>`. Exposées via des `Provider` Riverpod (`xxxRepositoryProvider`). **C'est la seule couche qui changerait si le backend était remplacé.**
- **`lib/navigation/`** — `AdaptiveScaffold` (StatefulShellRoute de go_router) : `NavigationRail` à partir de 600px, `NavigationBar` en dessous, état de chaque branche préservé.
- **`lib/features/`** — un dossier par écran majeur (`home/`, `vehicles/`, `maintenance/`...), écrans + widgets locaux à cet écran uniquement. Les écritures passent par une classe d'actions exposée en `Provider` (ex. `MaintenanceActions`) qui appelle le repository puis invalide les providers concernés — les écrans n'orchestrent pas eux-mêmes les invalidations.

### Décisions techniques actées

- **State management** : Riverpod **sans codegen** (API `Provider`/`Notifier` classique). `riverpod_generator` est actuellement incompatible avec `freezed`/`riverpod_annotation` récents sur pub.dev → pas de codegen Riverpod, pas de freezed. Les modèles utilisent `json_serializable` seul, avec `copyWith` écrits à la main.
- **HTTP** : Dio (pas `package:http`).
- **Upload photos/documents** : multipart direct vers le backend ; le backend ne renvoie qu'un nom de fichier, résolu en URL via `ImageUrlResolver`. Ne pas utiliser `dart:io File` dans les services/repositories (incompatible web) — signatures en `List<int> bytes` + `String filename`.
- **Kilométrage** : saisie manuelle uniquement (pas d'intégration OBD/tierce).
- **Listes de référence backend** (id INT) : catégories de véhicules (`GET /vehicle-categories`, exposées par `vehicleCategoriesProvider`) et types d'organisation (`GET /organization-types`, `organizationTypesProvider`). Pas d'enum Dart pour ces valeurs ; les icônes (placeholder, filtres, carte garage) sont déduites du nom, avec repli générique.
- **Catégorie par défaut** : une seule catégorie a `is_default` (« Autre » à l'installation) ; `vehicleCategoriesProvider` la place en dernier (filtres, formulaires) et le formulaire véhicule la présélectionne.
- **Relations en écriture par identifiant** : en lecture, un véhicule reçoit `category: {id, name, is_default}` et une organisation `categories: [...]` / `type: {...}` (absent pour « Moi-même ») / `address: {...}` ; en écriture ils envoient `vehicle_category_id` / `category_ids` / `organization_type_id` / `address_id` (champs objets exclus du `toJson` généré, ids ajoutés à la main). Booléens envoyés en `0/1`.
- **Adresses** : ressource séparée (`/addresses`) ; `ApiOrganizationRepository` la crée/met à jour avant l'organisation. Un PUT backend remplace tous les champs : toujours envoyer l'objet complet.
- **Erreurs backend** : corps `{ "error": "..." }`, lu par `ApiClient.mapError` (codes 400/404/409/422).
- **Champs carte grise retenus sur `Vehicle`** : immatriculation, marque, modèle, VIN, date de 1ère immatriculation, énergie, puissance fiscale, puissance en CH, poids, couleur — volontairement pas l'exhaustivité d'une carte grise réelle. Ne pas ajouter de champ carte grise supplémentaire sans validation utilisateur.

## Décisions produit / UX actées

- **Design général** : sobre, moderne, orienté application personnelle (pas un logiciel professionnel). Cartes, sections, hiérarchie visuelle claire, informations importantes mises en avant.
- **Navigation** : desktop/tablette (≥600px) → `NavigationRail` à gauche (étendu ≥840px). Mobile (<600px) → `NavigationBar` en bas. 3 destinations principales (Accueil, Véhicules, Mes garages) ; ne pas ajouter d'onglet supplémentaire (ex. "Échéances" dédié mobile) sauf si l'usage réel le justifie une fois l'app en place.
- **Filtres véhicules (écran Véhicules)** : `SegmentedButton` pour la catégorie (segments générés depuis `vehicleCategoriesProvider`) + `SegmentedButton` ou `FilterChip` secondaire pour le statut (En cours/Historique), sous une barre de recherche texte. Choix fait plutôt qu'une `TabBar` scrollable car il s'agit de deux filtres orthogonaux combinés (catégorie × statut), pas d'un contenu à swiper.
- **Catégorie d'un véhicule** : une seule (1-N), `SegmentedButton` dans le formulaire. Les garages restent en N-N (cases à cocher en ligne, `VehicleCategoriesField`).
- **Placeholders image** : si un véhicule n'a pas de photo, afficher un placeholder différent selon sa catégorie — pas un placeholder générique unique.
- **Écran Accueil** : cartes des véhicules actuels (photo ou placeholder, nom personnalisé, marque, modèle, immatriculation, kilométrage, commentaire, prochain entretien) + bloc prochaines échéances. Sur desktop, le bloc échéances est visible directement sur l'accueil ; sur mobile, un aperçu limité suffit (pas d'écran dédié pour l'instant, cf. Navigation ci-dessus).
- **Fiche véhicule** : sections infos générales, infos carte grise, entretiens (réalisés / à venir / en retard), documents.
- **Historique d'entretien** : chaque intervention = type, date, kilométrage, description, coût, garage/intervenant, commentaire, documents associés. Présentation chronologique.
- **Garages (`Organization`)** : nom, type (liste backend, non demandé pour « Moi-même »), téléphone, mobile, site web, adresse (rue, complément, CP, ville), commentaire, `is_archived`, `is_mine` (entrée « Moi-même »), catégories de véhicules prises en charge (N-N, cases à cocher). Le garage est **obligatoire** sur une intervention (`organization_id`) ; le formulaire ne propose que les garages non archivés prenant en charge la catégorie du véhicule (« Moi-même » toujours proposé). Un garage référencé par des interventions s'archive plutôt que se supprimer.
- **Types d'entretien pré-remplis** (voir aussi seed SQL) : vidange, changement de pneus, plaquettes de frein, distribution, contrôle technique, révision, entretien personnalisé, petit entretien (nettoyage/lubrification/tension de chaîne moto). Liste extensible par l'utilisateur (`MaintenanceType.isCustom`).
- **Échéances d'entretien** : en date, en kilométrage, ou les deux (`MaintenanceSchedule.dueDate` / `dueMileage`). Pas de récupération automatique d'un plan constructeur — saisie manuelle uniquement.
- **Notifications** : pas de notifications push natives dans un premier temps. L'architecture (`Reminder`) est prête pour brancher `flutter_local_notifications` plus tard sans changer les repositories — se limiter pour l'instant à un affichage des échéances (badges, tri par urgence) dans l'UI.
- **Documents** : gestion simple au départ — nom de fichier uploadé, type, commentaire, date, éventuellement lié à une intervention d'entretien précise. Pensé pour évoluer (pas de sur-ingénierie immédiate).

## Règles de qualité de code

- Aucune logique métier dans les widgets — elle vit dans les repositories ou dans des providers/notifiers dédiés.
- Widgets dupliqués à 2+ endroits → extraire dans `core/widgets/` (ex. carte véhicule, placeholder image par catégorie, empty state, indicateur de chargement).
- Pas de breakpoint/URL/couleur en dur dans un widget — passer par `core/constants/`, `core/theme/`, `AppConfig`.
- Fichiers courts, un widget = une responsabilité ; éviter les fichiers géants.
- Respecter la structure en couches existante : ne jamais faire un widget qui appelle directement `services/api/` ou Dio — toujours passer par un repository.

## Base de données

`database/schema.sql` — schéma MySQL/MariaDB de référence (tables `vehicle_categories`, `vehicles`, `maintenance_types`, `addresses`, `organization_types`, `organizations`, `organization_vehicle_categories`, `maintenances`, `maintenance_schedules`, `documents`). Géré par l'utilisateur côté backend ; Flutter n'appelle que les endpoints REST.

### Routes backend attendues (à créer côté serveur si manquantes)

`GET/POST /vehicles`, `GET/PUT/DELETE /vehicles/:id`, `POST /vehicles/:id/photo` (multipart), `GET /vehicle-categories`, `GET /maintenance-types`, `GET/POST /vehicles/:id/maintenances`, `GET/PUT/DELETE /vehicles/:id/maintenances/:id`, `GET/POST /vehicles/:id/maintenance-schedules`, `GET/PUT/DELETE /vehicles/:id/maintenance-schedules/:id`, `GET/POST /vehicles/:id/documents` (multipart), `GET/PUT/DELETE /vehicles/:id/documents/:id`, `GET /organization-types`, `GET/POST /organizations`, `GET/PUT/DELETE /organizations/:id`, `POST /addresses`, `PUT /addresses/:id`. Création = 200 (pas de 201).

Si une fonctionnalité nécessite une route non listée ici : la proposer (méthode, chemin, format JSON, raison) avant de l'implémenter côté Flutter, sans coupler le frontend à une implémentation backend spécifique.

## État d'avancement

- [x] Étape 1 — Init projet, thème, config, navigation adaptative
- [x] Étape 2 — Modèles (`Vehicle`, `Maintenance`, `MaintenanceSchedule`, `Document`, `Reminder`...)
- [x] Étape 3 — Couche API (services, repositories, `Result<T>`, gestion d'erreurs)
- [x] Étape 4 — Écran Accueil (résumé véhicules actuels + prochaines échéances)
- [x] Étape 5 — Liste des véhicules (filtres catégorie/statut, recherche, tri)
- [x] Étape 6 — Ajout / modification d'un véhicule
- [x] Étape 7 — Fiche détaillée du véhicule
- [x] Étape 8 — Entretiens (historique + échéances)
- [ ] Étape 9 — Documents
- [ ] Étape 10 — Notifications / rappels (pas de push natif dans un premier temps)
- [ ] Étape 11 — Polissage responsive et UX

## Evolution
- scanner une carte grise
- suggest address
- suggest magasin
- recuperer les plan d'entretien constructeur
- liste de marque
- liste de modele par marque


Prochaine étape à la reprise : **Étape 9 — Documents**.
