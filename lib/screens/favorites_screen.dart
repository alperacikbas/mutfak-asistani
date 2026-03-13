import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/recipe_model.dart';
import '../models/user_model.dart';
import 'recipe_detail_screen.dart';
import 'login_screen.dart';
import '../widgets/recipe_card.dart';
import '../widgets/empty_state.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 80, color: Colors.orange.shade200),
            const SizedBox(height: 24),
            const Text(
              'Bu Alan Kayıtlı Üyelere Özel',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Favori tariflerini kaydetmek ve daha sonra kolayca ulaşmak için aramıza katılmalısın.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('Giriş Yap / Kayıt Ol', style: TextStyle(fontSize: 16)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserFavorites() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('users').doc(_authService.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Center(child: Text('Profil bulunamadı.'));
        }

        final userModel = UserModel.fromMap(userSnapshot.data!.data() as Map<String, dynamic>, userSnapshot.data!.id);
        final favoriteIds = userModel.favoritedRecipes;

        if (favoriteIds.isEmpty) {
          return const EmptyState(
            title: "Favorilerin Boş",
            message: "Henüz hiçbir tarifi kalbine almamışsın. Beğendiğin tariflerin yanındaki kalbe basarak buraya ekleyebilirsin!",
            icon: Icons.favorite_border_rounded,
          );
        }

        return FutureBuilder<QuerySnapshot>(
          future: _db.collection('recipes').where(FieldPath.documentId, whereIn: favoriteIds.take(10).toList()).get(),
          builder: (context, recipeSnapshot) {
            if (recipeSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.orange));
            }

            if (!recipeSnapshot.hasData || recipeSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Favori tariflerin yüklenemedi.'));
            }

            final docs = recipeSnapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final recipe = RecipeModel.fromMap(data, docs[index].id);

                return RecipeCard(recipe: recipe);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Favorilerim', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: _authService.isGuest ? _buildGuestView() : _buildUserFavorites(),
    );
  }
}