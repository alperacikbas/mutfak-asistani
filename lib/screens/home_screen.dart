import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';
import 'recipe_detail_screen.dart';
import '../widgets/recipe_card.dart';
import '../widgets/empty_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Keşfet', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: Colors.orange.shade800,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange.shade800,
            tabs: const [
              Tab(text: 'Klasikler'),
              Tab(text: 'Topluluk'),
              Tab(text: 'Trendler'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFeed(_db.collection('recipes').where('authorId', isEqualTo: 'system')),
            _buildFeed(_db.collection('recipes').where('authorId', isNotEqualTo: 'system')),
            _buildFeed(_db.collection('recipes').where('likeCount', isGreaterThan: 0).orderBy('likeCount', descending: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed(Query query) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyState(
            title: "Tarif Bulunamadı",
            message: "Aradığın lezzeti şu an bulamadık. Başka bir şeyler denemeye ne dersin?",
            icon: Icons.search_off_rounded,
          );
        }

        final docs = snapshot.data!.docs;

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
  }
}
