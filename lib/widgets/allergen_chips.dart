import 'package:flutter/material.dart';

class AllergenChips extends StatelessWidget {
  final List<String> allergens;

  const AllergenChips({super.key, required this.allergens});

  @override
  Widget build(BuildContext context) {
    if (allergens.isEmpty) return const Text("Alerjen bilgisi yok.");

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: allergens.map((allergen) {
        return Chip(
          label: Text(allergen, style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.w500)),
          backgroundColor: Colors.orange.shade50,
          side: BorderSide(color: Colors.orange.shade200),
        );
      }).toList(),
    );
  }
}