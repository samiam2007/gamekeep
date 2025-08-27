import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import '../utils/theme.dart';
import '../models/game_model.dart';
import 'game_confirmation_screen.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({Key? key}) : super(key: key);

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> 
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _flashOn = false;
  String _captureHint = 'Position game box in frame';
  
  final TextRecognizer _textRecognizer = TextRecognizer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    // Check if we're on web - camera functionality is limited
    if (kIsWeb) {
      setState(() {
        _isInitialized = false;
        _captureHint = 'Camera scanning is not available on web. Please use the BGG import instead.';
      });
      return;
    }
    
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      // For web/demo, we'll show a mock camera view
      if (mounted) {
        setState(() {
          _isInitialized = true; // Show mock view
        });
      }
    }
  }

  Future<void> _captureAndProcess() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _captureHint = 'Processing image...';
    });

    try {
      // For web demo, simulate OCR processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock OCR results
      final mockOcrResults = {
        'title': 'Wingspan',
        'publisher': 'Stonemaier Games',
        'designer': 'Elizabeth Hargrave',
        'players': '1-5',
        'playTime': '40-70',
        'confidence': 0.92,
      };

      if (!mounted) return;

      // Navigate to confirmation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameConfirmationScreen(
            extractedData: mockOcrResults,
            imagePath: null, // No actual image in demo
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error capturing/processing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _captureHint = 'Position game box in frame';
        });
      }
    }
  }

  Future<Map<String, dynamic>> _processWithOCR(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    
    // Extract game information from OCR text
    final extractedData = _extractGameInfo(recognizedText.text);
    
    return extractedData;
  }

  Map<String, dynamic> _extractGameInfo(String text) {
    final lines = text.split('\n');
    
    // Smart extraction logic
    String? title;
    String? publisher;
    String? designer;
    String? players;
    String? playTime;
    double confidence = 0.0;

    // Look for patterns in the text
    for (final line in lines) {
      // Title is usually the largest/first text
      if (title == null && line.length > 3) {
        title = line.trim();
        confidence += 0.3;
      }
      
      // Look for player count patterns
      if (players == null) {
        final playerMatch = RegExp(r'(\d+[-–]\d+)\s*players?', caseSensitive: false)
            .firstMatch(line);
        if (playerMatch != null) {
          players = playerMatch.group(1);
          confidence += 0.2;
        }
      }
      
      // Look for time patterns
      if (playTime == null) {
        final timeMatch = RegExp(r'(\d+[-–]?\d*)\s*(min|minutes)', caseSensitive: false)
            .firstMatch(line);
        if (timeMatch != null) {
          playTime = timeMatch.group(1);
          confidence += 0.2;
        }
      }
      
      // Look for age patterns
      final ageMatch = RegExp(r'ages?\s*(\d+\+?)', caseSensitive: false)
          .firstMatch(line);
      if (ageMatch != null) {
        confidence += 0.1;
      }
    }

    confidence = confidence.clamp(0.0, 1.0);

    return {
      'title': title ?? 'Unknown Game',
      'publisher': publisher ?? '',
      'designer': designer ?? '',
      'players': players ?? '',
      'playTime': playTime ?? '',
      'confidence': confidence,
      'rawText': text,
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    // Only close text recognizer on mobile platforms
    // _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview or mock view
          if (_isInitialized)
            _buildCameraPreview()
          else
            const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            ),

          // UI Overlay
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tips_and_updates,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _captureHint,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _flashOn ? Icons.flash_on : Icons.flash_off,
                            color: _flashOn ? AppTheme.primaryColor : Colors.white,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _flashOn = !_flashOn;
                          });
                          _cameraController?.setFlashMode(
                            _flashOn ? FlashMode.torch : FlashMode.off,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Guide frame
                if (!_isProcessing)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.4,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // Corner indicators
                        Positioned(
                          top: 0,
                          left: 0,
                          child: _buildCornerIndicator(true, true),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: _buildCornerIndicator(false, true),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: _buildCornerIndicator(true, false),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: _buildCornerIndicator(false, false),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Bottom controls
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Tips
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ensure good lighting and game title is visible',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Capture button
                      GestureDetector(
                        onTap: _isProcessing ? null : _captureAndProcess,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _isProcessing ? 60 : 80,
                          height: _isProcessing ? 60 : 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isProcessing
                                  ? [Colors.grey, Colors.grey.shade700]
                                  : [AppTheme.primaryColor, AppTheme.primaryDark],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isProcessing
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  )
                                : const Icon(
                                    Icons.camera,
                                    color: Colors.black,
                                    size: 40,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isProcessing ? 'Analyzing...' : 'Tap to capture',
                        style: TextStyle(
                          color: _isProcessing ? AppTheme.primaryColor : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    // For web demo, show a mock camera view
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade900,
            Colors.grey.shade800,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.camera_alt,
          size: 100,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildCornerIndicator(bool isLeft, bool isTop) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? BorderSide(color: AppTheme.primaryColor, width: 4)
              : BorderSide.none,
          bottom: !isTop
              ? BorderSide(color: AppTheme.primaryColor, width: 4)
              : BorderSide.none,
          left: isLeft
              ? BorderSide(color: AppTheme.primaryColor, width: 4)
              : BorderSide.none,
          right: !isLeft
              ? BorderSide(color: AppTheme.primaryColor, width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }
}