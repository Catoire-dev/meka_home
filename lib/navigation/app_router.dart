import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/maintenance/maintenance_detail_screen.dart';
import '../features/maintenance/maintenance_form_screen.dart';
import '../features/maintenance/schedule_form_screen.dart';
import '../features/organizations/organization_detail_screen.dart';
import '../features/organizations/organization_form_screen.dart';
import '../features/organizations/organizations_screen.dart';
import '../features/vehicles/vehicle_detail_screen.dart';
import '../features/vehicles/vehicle_form_screen.dart';
import '../features/vehicles/vehicles_screen.dart';
import 'adaptive_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdaptiveScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/vehicles',
                builder: (context, state) => const VehiclesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/garages',
                builder: (context, state) => const OrganizationsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/vehicles/new',
        builder: (context, state) => const VehicleFormScreen(),
      ),
      GoRoute(
        path: '/vehicles/:id',
        builder: (context, state) =>
            VehicleDetailScreen(vehicleId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/vehicles/:id/edit',
        builder: (context, state) =>
            VehicleFormScreen(vehicleId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/vehicles/:id/maintenances/new',
        builder: (context, state) => MaintenanceFormScreen(
          vehicleId: state.pathParameters['id']!,
          fromScheduleId: state.uri.queryParameters['scheduleId'],
        ),
      ),
      GoRoute(
        path: '/vehicles/:id/maintenances/:maintenanceId',
        builder: (context, state) => MaintenanceDetailScreen(
          vehicleId: state.pathParameters['id']!,
          maintenanceId: state.pathParameters['maintenanceId']!,
        ),
      ),
      GoRoute(
        path: '/vehicles/:id/maintenances/:maintenanceId/edit',
        builder: (context, state) => MaintenanceFormScreen(
          vehicleId: state.pathParameters['id']!,
          maintenanceId: state.pathParameters['maintenanceId']!,
        ),
      ),
      GoRoute(
        path: '/vehicles/:id/schedules/new',
        builder: (context, state) =>
            ScheduleFormScreen(vehicleId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/vehicles/:id/schedules/:scheduleId/edit',
        builder: (context, state) => ScheduleFormScreen(
          vehicleId: state.pathParameters['id']!,
          scheduleId: state.pathParameters['scheduleId']!,
        ),
      ),
      GoRoute(
        path: '/garages/new',
        builder: (context, state) => const OrganizationFormScreen(),
      ),
      GoRoute(
        path: '/garages/:id',
        builder: (context, state) => OrganizationDetailScreen(
          organizationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/garages/:id/edit',
        builder: (context, state) =>
            OrganizationFormScreen(organizationId: state.pathParameters['id']!),
      ),
    ],
  );
});
