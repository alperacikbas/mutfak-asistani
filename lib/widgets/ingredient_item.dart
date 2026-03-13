import 'package:flutter/material.dart';

class IngredientItem extends StatelessWidget {
  final String ingredient;

  const IngredientItem({super.key, required this.ingredient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(ingredient, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}