import 'package:flutter/material.dart';

class RecipeInputField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? icon;
  final TextEditingController? controller;
  final int maxLines;
  final String? Function(String?)? validator;
  final int? maxLength;

  const RecipeInputField({
    super.key,
    required this.label,
    required this.hint,
    this.icon,
    this.controller,
    this.maxLines = 1,
    this.validator,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, color: Colors.orange) : null,
          filled: true,
          fillColor: Colors.orange.shade50.withOpacity(0.3),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orange, width: 1.5),
          ),
          labelStyle: const TextStyle(color: Colors.orange),
        ),
      ),
    );
  }
}