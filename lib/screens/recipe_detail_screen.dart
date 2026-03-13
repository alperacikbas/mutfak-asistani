import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

import '../widgets/section_header.dart';
import '../widgets/allergen_chips.dart';
import '../widgets/ingredient_item.dart';
import '../widgets/instruction_item.dart';
import '../widgets/chef_info_bar.dart';

class RecipeDetailScreen extends StatefulWidget {
  final RecipeModel recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<String> _userAllergies = [];
  List<String> _matchingAllergies = [];
  bool _isFavorite = false;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _checkUserData();
  }

  Future<void> _checkUserData() async {
    if (_authService.isGuest || !_authService.isLoggedIn) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await _db.collection('users').doc(_authService.uid).get();
      if (doc.exists) {
        final userModel = UserModel.fromMap(doc.data()!, doc.id);
        _userAllergies = userModel.allergies;
        setState(() {
          _isFavorite = userModel.favoritedRecipes.contains(widget.recipe.recipeId);
          _isLiked = userModel.likedRecipes.contains(widget.recipe.recipeId);
          _matchingAllergies = widget.recipe.allergens
              .where((allergen) => _userAllergies.contains(allergen))
              .toList();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showGuestWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Bu özellik için giriş yapmalı veya kayıt olmalısınız.'), backgroundColor: Colors.orange.shade800),
    );
  }

  Future<void> _toggleFavorite() async {
    if (_authService.isGuest) { _showGuestWarning(); return; }
    final userRef = _db.collection('users').doc(_authService.uid);
    setState(() => _isFavorite = !_isFavorite);

    try {
      if (_isFavorite) {
        await userRef.update({'favoritedRecipes': FieldValue.arrayUnion([widget.recipe.recipeId])});
      } else {
        await userRef.update({'favoritedRecipes': FieldValue.arrayRemove([widget.recipe.recipeId])});
      }
    } catch (e) {
      setState(() => _isFavorite = !_isFavorite);
    }
  }

  Future<void> _toggleLike() async {
    if (_authService.isGuest) { _showGuestWarning(); return; }
    final userRef = _db.collection('users').doc(_authService.uid);
    final recipeRef = _db.collection('recipes').doc(widget.recipe.recipeId);
    final authorRef = _db.collection('users').doc(widget.recipe.authorId);

    setState(() => _isLiked = !_isLiked);

    try {
      if (_isLiked) {
        await userRef.update({'likedRecipes': FieldValue.arrayUnion([widget.recipe.recipeId])});
        await recipeRef.update({'likeCount': FieldValue.increment(1)});
        if (widget.recipe.authorId != 'system') await authorRef.update({'chefScore': FieldValue.increment(1)});
      } else {
        await userRef.update({'likedRecipes': FieldValue.arrayRemove([widget.recipe.recipeId])});
        await recipeRef.update({'likeCount': FieldValue.increment(-1)});
        if (widget.recipe.authorId != 'system') await authorRef.update({'chefScore': FieldValue.increment(-1)});
      }
    } catch (e) {
      setState(() => _isLiked = !_isLiked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('recipes').doc(widget.recipe.recipeId).snapshots(),
      builder: (context, snapshot) {
        int liveLikeCount = widget.recipe.likeCount;
        if (snapshot.hasData && snapshot.data!.exists) {
          liveLikeCount = (snapshot.data!.data() as Map<String, dynamic>)['likeCount'] ?? 0;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.orange),
            actions: [
              IconButton(icon: Icon(_isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, color: Colors.orange.shade700), onPressed: _toggleLike),
              IconButton(icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent), onPressed: _toggleFavorite),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.orange))
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.recipe.buildRecipeImage(width: double.infinity, height: 250, borderRadius: 0),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.recipe.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      ChefInfoBar(recipe: widget.recipe, liveLikeCount: liveLikeCount),
                      const SizedBox(height: 24),

                      if (_matchingAllergies.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.red.shade50, border: Border.all(color: Colors.red.shade200), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_rounded, color: Colors.red, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Sağlık Uyarısı!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text("Bu tarif profilinizdeki şu alerjenleri içeriyor: ${_matchingAllergies.join(', ')}", style: TextStyle(color: Colors.red.shade900)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SectionHeader(title: "Malzemeler", icon: Icons.shopping_basket),
                      ...widget.recipe.ingredients.map((item) => IngredientItem(ingredient: item)),
                      const SizedBox(height: 24),

                      const SectionHeader(title: "Alerjenler", icon: Icons.warning_rounded),
                      AllergenChips(allergens: widget.recipe.allergens),
                      const SizedBox(height: 24),

                      const SectionHeader(title: "Hazırlanışı", icon: Icons.restaurant),
                      ...widget.recipe.instructions.asMap().entries.map((entry) =>
                          InstructionItem(stepNumber: entry.key + 1, instruction: entry.value)
                      ),

                      SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}