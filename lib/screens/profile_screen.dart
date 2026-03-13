import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> _avatarPaths = [
    'assets/images/chef_1.png',
    'assets/images/chef_2.png',
    'assets/images/chef_3.png',
    'assets/images/chef_4.png',
    'assets/images/chef_5.png',
  ];

  final List<String> _availableAllergens = [
    'Glüten', 'Laktoz', 'Yer Fıstığı', 'Deniz Ürünleri',
    'Yumurta', 'Soya', 'Susam', 'Kuruyemiş'
  ];

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  void _showAvatarPicker(int currentAvatarId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
              "Şef Avatarını Seç",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold)
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _avatarPaths.length,
                itemBuilder: (context, index) {
                  final avatarId = index + 1;
                  final isSelected = currentAvatarId == avatarId;

                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await _db.collection('users').doc(_authService.uid).update({'avatarId': avatarId});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Avatar güncellendi!'))
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.orange, width: 4) : null,
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.grey.shade100,
                        backgroundImage: AssetImage(_avatarPaths[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  void _showAllergenPicker(List<String> currentAllergies) {
    List<String> tempSelected = List.from(currentAllergies);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text("Alerjenlerini Güncelle"),
                content: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _availableAllergens.map((allergen) {
                      final isSelected = tempSelected.contains(allergen);
                      return FilterChip(
                        label: Text(allergen),
                        selected: isSelected,
                        selectedColor: Colors.orange.shade200,
                        checkmarkColor: Colors.orange.shade900,
                        onSelected: (bool selected) {
                          setDialogState(() {
                            if (selected) {
                              tempSelected.add(allergen);
                            } else {
                              tempSelected.remove(allergen);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context), // İptal et
                    child: const Text("İptal", style: TextStyle(color: Colors.grey)),
                  ),
                  FilledButton(
                    onPressed: () async {
                      Navigator.pop(context); // Kapat
                      await _db.collection('users').doc(_authService.uid).update({'allergies': tempSelected});
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sağlık profilin güncellendi!')));
                    },
                    style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text("Kaydet"),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  void _showHowItWorks() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nasıl Çalışır?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.workspace_premium, Colors.amber, "Aşçı Puanı", "Paylaştığınız tarifler başkaları tarafından beğenildikçe Aşçı Puanınız artar."),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.warning_rounded, Colors.red, "Sağlık Uyarısı", "Profilinizdeki alerjenlere uymayan bir tarif açtığınızda sistem sizi otomatik uyarır."),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.thumb_up, Colors.blue, "Topluluk", "Trendler sayfasında en çok beğeni alan tarifler listelenir."),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Anladım", style: TextStyle(color: Colors.orange)))
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(desc, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_authService.isGuest) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(title: const Text('Profilim', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0),
        body: _buildGuestView(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Profilim', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Çıkış Yap',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                    FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: _handleLogout, child: const Text('Çıkış Yap')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('users').doc(_authService.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.orange));
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Profil verisi bulunamadı."));

          final userData = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);

          final avatarIndex = (userData.avatarId > 0 && userData.avatarId <= _avatarPaths.length)
              ? userData.avatarId - 1
              : 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showAvatarPicker(userData.avatarId),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: AssetImage(_avatarPaths[avatarIndex]), // GERÇEK FOTOĞRAF BURADA
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(userData.username, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                Text(_authService.currentUser?.email ?? "", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.withOpacity(0.3))),
                        child: Column(
                          children: [
                            const Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
                            const SizedBox(height: 8),
                            Text(userData.chefScore.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber)),
                            Text("Aşçı Puanı", style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _db.collection('recipes').where('authorId', isEqualTo: _authService.uid).snapshots(),
                        builder: (context, recipeSnapshot) {
                          final recipeCount = recipeSnapshot.hasData ? recipeSnapshot.data!.docs.length : 0;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.withOpacity(0.3))),
                            child: Column(
                              children: [
                                const Icon(Icons.menu_book, color: Colors.blue, size: 30),
                                const SizedBox(height: 8),
                                Text(recipeCount.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                                Text("Tariflerin", style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.health_and_safety_outlined, color: Colors.orange),
                  title: const Text("Alerjenlerimi Güncelle", style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAllergenPicker(userData.allergies), // BUTON BAĞLANDI
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded, color: Colors.orange),
                  title: const Text("Nasıl Çalışır?"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showHowItWorks, // BUTON BAĞLANDI
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline_rounded, size: 100, color: Colors.orange.shade200),
            const SizedBox(height: 24),
            const Text("Profilini Görmek İçin Giriş Yap", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text("Aşçı puanını takip etmek ve kendi tariflerini paylaşmak için hemen kayıt ol.", style: TextStyle(fontSize: 16, color: Colors.grey.shade600), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
              icon: const Icon(Icons.login),
              label: const Text("Giriş Yap / Kayıt Ol", style: TextStyle(fontSize: 16)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}