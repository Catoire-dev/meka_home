import 'package:flutter_test/flutter_test.dart';
import 'package:meka_home/models/organization/address.dart';
import 'package:meka_home/models/organization/organization.dart';
import 'package:meka_home/models/organization/organization_type.dart';
import 'package:meka_home/models/vehicle/vehicle_category.dart';

void main() {
  const moto = VehicleCategory(id: 1, name: 'Moto');
  const voiture = VehicleCategory(id: 2, name: 'Voiture');
  const autre = VehicleCategory(id: 3, name: 'Autre', isDefault: true);

  final json = {
    'id': 'o1',
    'name': 'Garage du Centre',
    'organization_type_id': 3,
    'type': {'id': 3, 'name': 'Contrôle technique'},
    'phone': '0102030405',
    'mobile': null,
    'website': null,
    'address_id': 'a1',
    'address': {
      'id': 'a1',
      'street': '1 rue X',
      'complement': null,
      'postal_code': '75001',
      'city': 'Paris',
      'region': null,
      'country': 'France',
      'latitude': '48.8600000',
      'longitude': null,
    },
    'comment': null,
    'categories': [
      {'id': 1, 'name': 'Moto'},
      {'id': 2, 'name': 'Voiture'},
    ],
    'is_archived': 0,
    'is_mine': '0',
  };

  test('désérialise type, adresse et catégories imbriqués', () {
    final organization = Organization.fromJson(json);

    expect(organization.type?.name, 'Contrôle technique');
    expect(organization.address?.singleLine, '1 rue X, 75001 Paris');
    expect(organization.address?.latitude, 48.86);
    expect(organization.categories, [moto, voiture]);
    expect(organization.isArchived, isFalse);
    expect(organization.isMine, isFalse);
  });

  test('sérialise les relations par identifiant et les booléens en 0/1', () {
    final out = Organization.fromJson(json).toJson();

    expect(out['organization_type_id'], 3);
    expect(out['address_id'], 'a1');
    expect(out['category_ids'], [1, 2]);
    expect(out['is_archived'], 0);
    expect(out['is_mine'], 0);
    expect(out.keys, isNot(containsAll(['type', 'address', 'categories'])));
  });

  test("address_id est null tant que l'adresse n'est pas créée", () {
    final organization = Organization(
      id: '',
      name: 'Nouveau',
      type: const OrganizationType(id: 1, name: 'Garage'),
      address: Address.fromJson({
        'street': '1 rue X',
        'postal_code': '75001',
        'city': 'Paris',
      }),
    );

    expect(organization.toJson()['address_id'], isNull);
  });

  test("« Moi-même » s'envoie sans type", () {
    const me = Organization(id: '', name: 'Moi', isMine: true);

    expect(me.toJson()['organization_type_id'], isNull);
    expect(me.toJson()['is_mine'], 1);
  });

  test(
    'handles : catégories prises en charge, toujours vrai pour « Moi-même »',
    () {
      final garage = Organization.fromJson(json);
      const me = Organization(id: 'me', name: 'Moi', isMine: true);

      expect(garage.handles(moto), isTrue);
      expect(garage.handles(autre), isFalse);
      expect(me.handles(autre), isTrue);
    },
  );
}
