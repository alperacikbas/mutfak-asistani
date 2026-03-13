import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isGuest => currentUser?.isAnonymous ?? true;
  String get uid => currentUser?.uid ?? '';

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Çıkış yapılırken hata oluştu: $e");
    }
  }
}