import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';

class ChefInfoBar extends StatelessWidget {
  final RecipeModel recipe;
  final int liveLikeCount;

  const ChefInfoBar({super.key, required this.recipe, required this.liveLikeCount});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return FutureBuilder<DocumentSnapshot>(
      future: recipe.authorId == 'system' ? null : db.collection('users').doc(recipe.authorId).get(),
      builder: (context, snapshot) {
        String avatarPath = 'assets/images/chef_1.png';
        String subtitle = recipe.authorId == 'system' ? 'Master Şef' : '0 Puan';
        String name = recipe.authorName;

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          int avatarId = userData['avatarId'] ?? 1;
          if (avatarId < 1 || avatarId > 5) avatarId = 1;
          avatarPath = 'assets/images/chef_$avatarId.png';
          subtitle = '${userData['chefScore'] ?? 0} Puan';
          name = userData['username'] ?? name;
        }

        return Row(
          children: [
            CircleAvatar(radius: 24, backgroundColor: Colors.grey.shade200, backgroundImage: AssetImage(avatarPath)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    children: [
                      Icon(recipe.authorId == 'system' ? Icons.star_rounded : Icons.workspace_premium, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(subtitle, style: TextStyle(color: recipe.authorId == 'system' ? Colors.orange.shade800 : Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Icon(Icons.thumb_up, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 6),
                  Text('$liveLikeCount', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}