import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ocr_service.dart';
import '../services/bgg_service.dart';
import '../models/game_model.dart';
import '../providers/game_provider.dart';
import 'package:provider/provider.dart';
import 'game_confirmation_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final OCRService _ocrService = OCRService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;
  bool _isFlashOn = false;
  String _processingMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
      }
      return;
    }

    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Capturing image...';
    });

    try {
      final XFile image = await _controller!.takePicture();
      await _processImage(image.path);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Failed to capture image: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _isProcessing = true;
        _processingMessage = 'Processing image...';
      });
      await _processImage(image.path);
    }
  }

  Future<void> _processImage(String imagePath) async {
    setState(() {
      _processingMessage = 'Extracting text from image...';
    });

    try {
      // Process image with OCR
      final ocrResult = await _ocrService.processGameImage(imagePath);

      setState(() {
        _processingMessage = 'Searching BoardGameGeek database...';
      });

      // Check confidence level
      if (ocrResult.confidence >= 0.95) {
        // Auto-accept high confidence matches
        if (ocrResult.bggMatches.isNotEmpty) {
          final topMatch = ocrResult.bggMatches.first;
          await _saveGameFromBGG(topMatch.bggId, imagePath);
        } else {
          _navigateToManualEntry(imagePath, ocrResult);
        }
      } else if (ocrResult.confidence >= 0.60) {
        // Show confirmation screen for medium confidence
        _navigateToConfirmation(imagePath, ocrResult);
      } else {
        // Manual entry for low confidence
        _navigateToManualEntry(imagePath, ocrResult);
      }
    } catch (e) {
      _showError('Error processing image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _saveGameFromBGG(int bggId, String imagePath) async {
    final bggService = BGGService();
    final gameDetails = await bggService.getGameDetails(bggId);

    if (gameDetails != null && mounted) {
      // Create game model from BGG data
      final game = GameModel(
        gameId: DateTime.now().millisecondsSinceEpoch.toString(),
        ownerId: '', // Will be set by provider
        title: gameDetails['title'],
        publisher: gameDetails['publisher'] ?? '',
        year: gameDetails['year'],
        designers: List<String>.from(gameDetails['designers'] ?? []),
        minPlayers: gameDetails['minPlayers'],
        maxPlayers: gameDetails['maxPlayers'],
        playTime: gameDetails['playTime'],
        weight: gameDetails['weight'].toDouble(),
        bggId: bggId,
        bggRank: gameDetails['rank'],
        mechanics: List<String>.from(gameDetails['mechanics'] ?? []),
        categories: List<String>.from(gameDetails['categories'] ?? []),
        tags: [],
        coverImage: gameDetails['image'] ?? '',
        thumbnailImage: gameDetails['thumbnail'] ?? '',
        condition: GameCondition.good,
        location: 'Main Shelf',
        visibility: GameVisibility.friends,
        importSource: ImportSource.photo,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save game
      await context.read<GameProvider>().addGame(game, File(imagePath));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${game.title}" to your library'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _navigateToConfirmation(String imagePath, OCRResult ocrResult) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameConfirmationScreen(
          imagePath: imagePath,
          extractedData: {
            'title': ocrResult.title ?? '',
            'publisher': ocrResult.publisher ?? '',
            'year': 0,  // Year not available from OCR
            'confidence': ocrResult.confidence,
          },
        ),
      ),
    );
  }

  void _navigateToManualEntry(String imagePath, OCRResult ocrResult) {
    // Navigate to manual entry screen
    // Implementation would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not identify game. Please enter details manually.'),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add Game'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Game'),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
              await _controller!.setFlashMode(
                _isFlashOn ? FlashMode.torch : FlashMode.off,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickFromGallery,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          SizedBox.expand(
            child: CameraPreview(_controller!),
          ),

          // Guide Overlay
          if (!_isProcessing)
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.width * 0.85 * 1.2,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.casino,
                      color: Colors.white.withOpacity(0.5),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Position game box here',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ensure title is clearly visible',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Processing Overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _processingMessage,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Capture Button
          if (!_isProcessing)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _captureImage,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),

          // Tips
          if (!_isProcessing)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.yellow,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Good lighting improves recognition accuracy',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}