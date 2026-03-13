import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeModel {
  final String recipeId;
  final String title;
  final String authorId;
  final String authorName;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> allergens;
  final int likeCount;
  final DateTime createdAt;
  final String? imageUrl;

  RecipeModel({
    required this.recipeId,
    required this.title,
    required this.authorId,
    required this.authorName,
    required this.ingredients,
    required this.instructions,
    required this.allergens,
    required this.likeCount,
    required this.createdAt,
    this.imageUrl,
  });

  factory RecipeModel.fromMap(Map<String, dynamic> map, String id) {
    return RecipeModel(
      recipeId: id,
      title: map['title'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? 'Bilinmeyen Şef',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
      allergens: List<String>.from(map['allergens'] ?? []),
      likeCount: map['likeCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'authorId': authorId,
      'authorName': authorName,
      'ingredients': ingredients,
      'instructions': instructions,
      'allergens': allergens,
      'likeCount': likeCount,
      'createdAt': createdAt,
      'imageUrl': imageUrl,
    };
  }

  Widget buildRecipeImage({double? width, double? height, BoxFit fit = BoxFit.cover, double borderRadius = 0}) {
    Widget imageWidget;

    if (imageUrl == null || imageUrl!.isEmpty) {
      imageWidget = Container(
        width: width, height: height, color: Colors.orange.shade50,
        child: const Icon(Icons.restaurant, color: Colors.orange, size: 40),
      );
    } else if (imageUrl!.startsWith('assets/')) {
      imageWidget = Image.asset(imageUrl!, width: width, height: height, fit: fit);
    } else {
      try {
        imageWidget = Image.memory(
          base64Decode(imageUrl!),
          width: width, height: height, fit: fit,
          errorBuilder: (context, error, stackTrace) => Container(
            width: width, height: height, color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      } catch (e) {
        imageWidget = Container(width: width, height: height, color: Colors.grey.shade200);
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageWidget,
    );
  }
}