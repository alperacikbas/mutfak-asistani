import 'dart:io';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class MLService {
  late final GenerativeModel _model;

  MLService() {
    _initializeModel();
  }

  void _initializeModel() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Kritik Hata: API Anahtarı bulunamadı! Lütfen .env dosyasını kontrol et.');
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  Future<List<String>> identifyIngredients(String imagePath) async {
    try {
      final file = File(imagePath);
      final imageBytes = await file.readAsBytes();
      final imagePart = DataPart('image/jpeg', imageBytes);

      final prompt = TextPart(
          "Bu fotoğraftaki yiyecek ve mutfak malzemelerini (sebze, meyve, paketli gıdalar vb.) tespit et. "
              "Sadece malzemelerin Türkçe isimlerini içeren bir JSON dizisi (array) döndür. "
              "Örnek format: [\"Domates\", \"Süt\", \"Un\"]. "
              "Başka hiçbir ekstra açıklama, markdown işareti veya metin yazma."
              "Dönen malzeme isimlerinin baş harfleri büyük olsun. Örnek: Elma"
      );

      final response = await _model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final text = response.text ?? '[]';

      final cleanText = text.replaceAll('```json', '').replaceAll('```', '').trim();

      List<dynamic> parsedList = jsonDecode(cleanText);

      return parsedList.map((e) => e.toString()).toList();

    } catch (e) {
      print("Gemini API Hatası: $e");
      return ["Model bir hata ile karşılaştı"];
    }
  }

  void dispose() {
  }
}