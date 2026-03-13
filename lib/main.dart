import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/login_screen.dart';

List<CameraDescription> globalCameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print("Sistem: .env dosyası başarıyla yüklendi.");
  } catch (e) {
    print("Hata: .env dosyası yüklenemedi! $e");
  }

  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase başlatılırken bir sorun oluştu: $e");
  }

  try {
    globalCameras = await availableCameras();
  } catch (e) {
    print("Kamera yüklenirken hata oluştu: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mutfak Asistanı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.orange,
      ),
      home: const LoginScreen(),
    );
  }
}