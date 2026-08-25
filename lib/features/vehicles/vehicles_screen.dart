import 'package:flutter/material.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Véhicules')),
      body: const Center(
        child: Text('Liste des véhicules — à venir'),
      ),
    );
  }
}
