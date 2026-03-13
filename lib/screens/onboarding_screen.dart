import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _usernameController = TextEditingController();

  int _selectedAvatarId = 1;
  bool _isLoading = false;
  String? _usernameError;

  final List<String> _availableAllergens = [
    'Glüten', 'Laktoz', 'Yer Fıstığı', 'Deniz Ürünleri',
    'Yumurta', 'Soya', 'Susam', 'Kuruyemiş'
  ];
  final List<String> _selectedAllergens = [];

  final int _totalAvatars = 5;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _validateUsername(String value) {
    if (value.isEmpty) {
      setState(() => _usernameError = null);
      return;
    }
    if (value != value.toLowerCase()) {
      setState(() => _usernameError = 'Kullanıcı adında büyük harf bulunamaz.');
      return;
    }
    if (value.contains(' ')) {
      setState(() => _usernameError = 'Kullanıcı adında boşluk bırakılamaz.');
      return;
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
      setState(() => _usernameError = 'Sadece küçük harf, rakam ve alt çizgi (_).');
      return;
    }
    if (value.length < 3 || value.length > 15) {
      setState(() => _usernameError = 'Kullanıcı adı 3-15 karakter arasında olmalı.');
      return;
    }
    setState(() => _usernameError = null);
  }

  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();

    if (username.isEmpty || _usernameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Lütfen kullanıcı adı kurallarına uyun.'), backgroundColor: Colors.red.shade400),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final existingUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        setState(() {
          _usernameError = "Bu kullanıcı adı zaten alınmış!";
          _isLoading = false;
        });
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Kullanıcı bulunamadı");

      UserModel newUser = UserModel(
        uid: user.uid,
        username: username,
        avatarId: _selectedAvatarId,
        allergies: _selectedAllergens,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(newUser.toMap());

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text('Profilini Oluştur', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 40),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text('Bir Şef Avatarı Seç', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _totalAvatars,
                  itemBuilder: (context, index) {
                    final avatarId = index + 1;
                    final isSelected = _selectedAvatarId == avatarId;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatarId = avatarId),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.orange.shade100 : Colors.grey.shade100,
                          border: Border.all(
                              color: isSelected ? Colors.orange.shade700 : Colors.transparent,
                              width: isSelected ? 4 : 0
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                          ] : [],
                          image: DecorationImage(
                            image: AssetImage('assets/images/chef_$avatarId.png'), // Assets'ten çekiyoruz
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      onChanged: _validateUsername,
                      decoration: InputDecoration(
                        labelText: 'Kullanıcı Adı (Zorunlu)',
                        prefixIcon: const Icon(Icons.alternate_email, color: Colors.orange),
                        errorText: _usernameError,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text('Alerjilerin (Opsiyonel)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _availableAllergens.map((allergen) {
                        final isSelected = _selectedAllergens.contains(allergen);
                        return FilterChip(
                          label: Text(allergen),
                          selected: isSelected,
                          selectedColor: Colors.orange.shade100,
                          checkmarkColor: Colors.orange.shade900,
                          backgroundColor: Colors.grey.shade50,
                          labelStyle: TextStyle(color: isSelected ? Colors.orange.shade900 : Colors.black87),
                          side: BorderSide(color: isSelected ? Colors.orange.shade400 : Colors.grey.shade300),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) _selectedAllergens.add(allergen);
                              else _selectedAllergens.remove(allergen);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                        : FilledButton(
                      onPressed: _saveProfile,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Mutfak Asistanına Başla!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}