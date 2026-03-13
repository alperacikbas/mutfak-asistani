class UserModel {
  final String uid;
  final String username;
  final int avatarId;
  final int chefScore;
  final List<String> allergies;
  final List<String> favoritedRecipes;
  final List<String> likedRecipes;

  UserModel({
    required this.uid,
    required this.username,
    required this.avatarId,
    this.chefScore = 0,
    this.allergies = const [],
    this.favoritedRecipes = const [],
    this.likedRecipes = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      username: map['username'] ?? '',
      avatarId: map['avatarId'] ?? 1,
      chefScore: map['chefScore'] ?? 0,
      allergies: List<String>.from(map['allergies'] ?? []),
      favoritedRecipes: List<String>.from(map['favoritedRecipes'] ?? []),
      likedRecipes: List<String>.from(map['likedRecipes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'avatarId': avatarId,
      'chefScore': chefScore,
      'allergies': allergies,
      'favoritedRecipes': favoritedRecipes,
      'likedRecipes': likedRecipes,
    };
  }
}