import 'package:flutter/material.dart';

/// Bouton « Enregistrer » d'un formulaire, désactivé avec indicateur de
/// progression pendant l'enregistrement.
class FormSubmitButton extends StatelessWidget {
  const FormSubmitButton({
    super.key,
    required this.saving,
    required this.onPressed,
  });

  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: saving ? null : onPressed,
      child: saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Enregistrer'),
    );
  }
}
