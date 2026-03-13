import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'ai_results_screen.dart';
import '../services/ml_service.dart';

class CameraScreen extends StatefulWidget {
  final bool isActive;
  const CameraScreen({super.key, required this.isActive});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  XFile? _capturedImage;
  bool _isScanning = false;
  late AnimationController _pulseController;

  final MLService _mlService = MLService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);

    if (widget.isActive) {
      _initCamera();
    }
  }

  @override
  void didUpdateWidget(CameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initCamera();
    } else if (!widget.isActive && oldWidget.isActive) {
      _cameraController?.dispose();
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  // UYGULAMA İÇİ KAMERAYI BAŞLATMA
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (e) {
      print("Kamera başlatılama hatası: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    _mlService.dispose();
    super.dispose();
  }

  // FOTOĞRAF ÇEKME
  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _cameraController!.value.isTakingPicture) return;

    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() => _capturedImage = image);
    } catch (e) {
      print("Fotoğraf çekme hatası: $e");
    }
  }

  // ML SERVİSİNİ KULLANARAK ANALİZ ETME
  Future<void> _analyzeImage() async {
    if (_isScanning || _capturedImage == null) return;

    setState(() => _isScanning = true);

    try {
      List<String> aiResults = await _mlService.identifyIngredients(_capturedImage!.path);

      if (aiResults.isEmpty || aiResults.contains("Model bir hata ile karşılaştı")) {
        throw Exception("Yapay zeka malzemeleri tanımlayamadı.");
      }

      if (mounted) {
        setState(() {
          _isScanning = false;
          _capturedImage = null;
        });

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AiResultsScreen(detectedIngredients: aiResults)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tarama başarısız oldu. Lütfen malzemelerin net göründüğü bir fotoğraf çekin.'),
              backgroundColor: Colors.red.shade800,
            )
        );
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive || !_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.orange))
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _capturedImage == null
                ? CameraPreview(_cameraController!)
                : Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
          ),

          if (_isScanning)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _pulseController,
                      child: const Icon(Icons.document_scanner_rounded, color: Colors.orange, size: 80),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Yapay Zeka Malzemeleri\nİnceliyor...",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(color: Colors.orange),
                  ],
                ),
              ),
            ),

          if (!_isScanning)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  if (_capturedImage == null)
                    GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.orange, width: 4),
                        ),
                        child: Center(
                          child: Container(
                            height: 60,
                            width: 60,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton(
                          backgroundColor: Colors.white,
                          onPressed: () => setState(() => _capturedImage = null),
                          child: const Icon(Icons.close, color: Colors.black87),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: _analyzeImage,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text("Malzemeleri Bul", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}