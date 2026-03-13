import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../widgets/section_header.dart';
import '../widgets/recipe_input_field.dart';
import '../models/recipe_model.dart';

class RecipeFormScreen extends StatefulWidget {
  final RecipeModel? recipeToEdit;
  final List<String>? initialIngredients;

  const RecipeFormScreen({super.key, this.recipeToEdit, this.initialIngredients});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _titleController = TextEditingController();
  final List<TextEditingController> _ingredientControllers = [];
  final List<TextEditingController> _instructionControllers = [];

  final List<String> _availableAllergens = ['Glüten', 'Süt Ürünleri', 'Yumurta', 'Kuruyemiş', 'Deniz Ürünleri', 'Soya', 'Fıstık'];
  final List<String> _selectedAllergens = [];

  File? _selectedImage;
  bool _isLoading = false;

  final int _maxIngredients = 15;
  final int _maxInstructions = 15;

  @override
  void initState() {
    super.initState();

    if (widget.initialIngredients != null && widget.initialIngredients!.isNotEmpty) {
      _ingredientControllers.clear(); // Boş kutuyu sil
      for (var ingredient in widget.initialIngredients!) {
        _ingredientControllers.add(TextEditingController(text: ingredient));
      }
    }

    if (widget.recipeToEdit != null) {
      _titleController.text = widget.recipeToEdit!.title;
      _selectedAllergens.addAll(widget.recipeToEdit!.allergens);

      for (var ingredient in widget.recipeToEdit!.ingredients) {
        _ingredientControllers.add(TextEditingController(text: ingredient));
      }
      for (var instruction in widget.recipeToEdit!.instructions) {
        _instructionControllers.add(TextEditingController(text: instruction));
      }
    } else {
      _ingredientControllers.add(TextEditingController());
      _instructionControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var c in _ingredientControllers) { c.dispose(); }
    for (var c in _instructionControllers) { c.dispose(); }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
    );

    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredientControllers.any((c) => c.text.trim().isEmpty)) {
      _showError('Lütfen boş malzeme alanı bırakmayın veya silin.');
      return;
    }
    if (_instructionControllers.any((c) => c.text.trim().isEmpty)) {
      _showError('Lütfen boş yapılış adımı bırakmayın veya silin.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? base64Image;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        base64Image = base64Encode(bytes);
        if (base64Image.length > 1048576) {
          _showError('Seçtiğiniz resim çok büyük. Lütfen başka bir resim deneyin.');
          setState(() => _isLoading = false);
          return;
        }
      }

      List<String> ingredients = _ingredientControllers.map((c) => c.text.trim()).toList();
      List<String> instructions = _instructionControllers.map((c) => c.text.trim()).toList();

      if (widget.recipeToEdit != null) {
        Map<String, dynamic> updateData = {
          'title': _titleController.text.trim(),
          'ingredients': ingredients,
          'instructions': instructions,
          'allergens': _selectedAllergens,
        };
        if (base64Image != null) {
          updateData['imageUrl'] = base64Image;
        }

        await _db.collection('recipes').doc(widget.recipeToEdit!.recipeId).update(updateData);
        _showSuccess('Tarif başarıyla güncellendi! ✍️');

      } else {
        String authorName = 'Bilinmeyen Şef';
        final userDoc = await _db.collection('users').doc(_authService.uid).get();
        if (userDoc.exists) {
          authorName = userDoc.data()?['username'] ?? 'Şef';
        }

        await _db.collection('recipes').add({
          'title': _titleController.text.trim(),
          'authorId': _authService.uid,
          'authorName': authorName,
          'ingredients': ingredients,
          'instructions': instructions,
          'allergens': _selectedAllergens,
          'likeCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'imageUrl': base64Image,
        });
        _showSuccess('Tarif başarıyla paylaşıldı! 👨‍🍳');
      }

      if (mounted) Navigator.pop(context);

    } catch (e) {
      _showError('Bir hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
      );
    }
    else if (widget.recipeToEdit?.imageUrl != null && widget.recipeToEdit!.imageUrl!.isNotEmpty) {
      return Stack(
        children: [
          widget.recipeToEdit!.buildRecipeImage(width: double.infinity, height: 200, borderRadius: 20),
          Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
            child: const Center(child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 48)),
          ),
        ],
      );
    }
    else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_rounded, size: 48, color: Colors.orange.shade300),
          const SizedBox(height: 12),
          Text('İştah Açıcı Bir Fotoğraf Ekle', style: TextStyle(color: Colors.orange.shade600, fontWeight: FontWeight.bold)),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recipeToEdit != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditing ? 'Tarifi Düzenle' : 'Yeni Tarif Ekle', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.orange),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade200, style: BorderStyle.solid, width: 2),
                ),
                child: _buildImagePreview(),
              ),
            ),
            const SizedBox(height: 24),

            RecipeInputField(
              label: 'Tarifin Adı',
              hint: 'Örn: Fırında Soslu Tavuk',
              icon: Icons.restaurant_menu,
              controller: _titleController,
              maxLength: 50,
              validator: (val) => val == null || val.isEmpty ? 'Tarif adı boş olamaz' : null,
            ),

            const SectionHeader(title: 'Malzemeler', icon: Icons.shopping_basket),
            ..._ingredientControllers.asMap().entries.map((entry) {
              int index = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RecipeInputField(
                        label: 'Malzeme ${index + 1}',
                        hint: 'Örn: 2 yemek kaşığı zeytinyağı',
                        controller: entry.value,
                        maxLength: 100,
                      ),
                    ),
                    if (_ingredientControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        onPressed: () => setState(() => _ingredientControllers.removeAt(index)),
                      )
                  ],
                ),
              );
            }).toList(),

            if (_ingredientControllers.length < _maxIngredients)
              TextButton.icon(
                onPressed: () => setState(() => _ingredientControllers.add(TextEditingController())),
                icon: const Icon(Icons.add, color: Colors.orange),
                label: const Text('Yeni Malzeme Ekle', style: TextStyle(color: Colors.orange)),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Maksimum malzeme sınırına (15) ulaştınız.', style: TextStyle(color: Colors.red.shade400, fontSize: 13, fontStyle: FontStyle.italic)),
              ),

            const SizedBox(height: 16),

            const SectionHeader(title: 'Hazırlanış Adımları', icon: Icons.format_list_numbered_rounded),
            ..._instructionControllers.asMap().entries.map((entry) {
              int index = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RecipeInputField(
                        label: 'Adım ${index + 1}',
                        hint: 'Ne yapmamız gerektiğini açıkla...',
                        controller: entry.value,
                        maxLines: 3,
                        maxLength: 400,
                      ),
                    ),
                    if (_instructionControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        onPressed: () => setState(() => _instructionControllers.removeAt(index)),
                      )
                  ],
                ),
              );
            }).toList(),

            if (_instructionControllers.length < _maxInstructions)
              TextButton.icon(
                onPressed: () => setState(() => _instructionControllers.add(TextEditingController())),
                icon: const Icon(Icons.add, color: Colors.orange),
                label: const Text('Yeni Adım Ekle', style: TextStyle(color: Colors.orange)),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Maksimum adım sınırına (15) ulaştınız.', style: TextStyle(color: Colors.red.shade400, fontSize: 13, fontStyle: FontStyle.italic)),
              ),

            const SizedBox(height: 16),

            const SectionHeader(title: 'Alerjen Uyarıları', icon: Icons.warning_rounded),
            Wrap(
              spacing: 8.0,
              children: _availableAllergens.map((allergen) {
                final isSelected = _selectedAllergens.contains(allergen);
                return FilterChip(
                  label: Text(allergen),
                  selected: isSelected,
                  selectedColor: Colors.red.shade100,
                  checkmarkColor: Colors.red.shade900,
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(color: isSelected ? Colors.red.shade900 : Colors.black87),
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

            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: isEditing ? Colors.blue.shade600 : Colors.orange.shade700, // Düzenlemedeyse mavi buton yapalım
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _saveRecipe,
                child: Text(isEditing ? 'Değişiklikleri Kaydet' : 'Tarifi Paylaş', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }
}