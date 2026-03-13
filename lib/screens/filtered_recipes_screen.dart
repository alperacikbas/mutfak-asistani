import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';
import '../widgets/recipe_card.dart';
import '../widgets/empty_state.dart';

class FilteredRecipesScreen extends StatelessWidget {
  final List<String> ingredients;

  const FilteredRecipesScreen({super.key, required this.ingredients});

  @override
  Widget build(BuildContext context) {
    final queryIngredients = ingredients.take(10).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Sizin İçin Bulunanlar', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.orange),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recipes')
            .where('ingredients', arrayContainsAny: queryIngredients)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const EmptyState(
              title: "Tarif Bulunamadı",
              message: "Bu malzemelerle eşleşen bir tarif henüz topluluğumuzda yok. İlk sen oluşturmaya ne dersin?",
              icon: Icons.search_off_rounded,
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final recipe = RecipeModel.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
              return RecipeCard(recipe: recipe);
            },
          );
        },
      ),
    );
  }
}