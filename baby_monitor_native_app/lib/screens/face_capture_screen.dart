import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/auth_service.dart';

// ============================================================================
// FACE CAPTURE SCREEN - Pantalla para capturar y registrar rostro
// ============================================================================

class FaceCaptureScreen extends StatefulWidget {
  final bool isLogin; // true si es para login, false si es para registro
  
  const FaceCaptureScreen({
    super.key,
    this.isLogin = false,
  });

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isProcessing = false;
  bool _faceDetected = false;
  String _statusMessage = 'Posiciona tu rostro en el óvalo';
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeFaceDetector();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {});
        _startFaceDetection();
      }
    } catch (e) {
      debugPrint('❌ Error inicializando cámara: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'Error al acceder a la cámara';
        });
      }
    }
  }

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    );
    _faceDetector = FaceDetector(options: options);
  }

  void _startFaceDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _cameraController!.startImageStream((image) async {
      if (_isProcessing || _isCapturing) return;
      _isProcessing = true;

      try {
        final inputImage = _convertToInputImage(image);
        if (inputImage != null) {
          final faces = await _faceDetector!.processImage(inputImage);
          
          if (mounted) {
            setState(() {
              _faceDetected = faces.isNotEmpty;
              if (_faceDetected) {
                _statusMessage = '✓ Rostro detectado';
              } else {
                _statusMessage = 'Posiciona tu rostro en el óvalo';
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Error detectando rostro: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  InputImage? _convertToInputImage(CameraImage image) {
    try {
      final List<int> allBytes = [];
      for (final Plane plane in image.planes) {
        allBytes.addAll(plane.bytes);
      }
      final bytes = Uint8List.fromList(allBytes);

      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );
    } catch (e) {
      debugPrint('Error convirtiendo imagen: $e');
      return null;
    }
  }

  Future<void> _captureFace() async {
    if (!_faceDetected || _isCapturing) return;

    setState(() {
      _isCapturing = true;
      _statusMessage = 'Capturando...';
    });

    try {
      await _cameraController?.stopImageStream();
      
      final image = await _cameraController?.takePicture();
      if (image == null) throw Exception('No se pudo capturar la imagen');

      final imageBytes = await image.readAsBytes();
      
      if (widget.isLogin) {
        // Login con reconocimiento facial
        await _performFaceLogin(imageBytes);
      } else {
        // Registrar rostro
        await _registerFace(imageBytes);
      }
    } catch (e) {
      debugPrint('❌ Error capturando rostro: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'Error al capturar. Intenta de nuevo.';
          _isCapturing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Reiniciar stream
        _startFaceDetection();
      }
    }
  }

  Future<void> _performFaceLogin(Uint8List imageBytes) async {
    try {
      setState(() => _statusMessage = 'Verificando...');
      
      final user = await AuthService.signInWithFace({'raw_image': base64Encode(imageBytes)});
      
      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Autenticación exitosa'),
            backgroundColor: Color(0xFF4F7A4A),
          ),
        );
        
        // Cerrar pantalla y regresar con éxito
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Rostro no reconocido');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Rostro no autorizado';
          _isCapturing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Rostro no reconocido. Intenta de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Reiniciar stream
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _startFaceDetection();
        }
      }
    }
  }

  Future<void> _registerFace(Uint8List imageBytes) async {
    try {
      setState(() => _statusMessage = 'Registrando rostro...');
      
      await AuthService.registerFaceBiometric(faceEncoding: {'raw_image': base64Encode(imageBytes)});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Rostro registrado correctamente'),
            backgroundColor: Color(0xFF4F7A4A),
          ),
        );
        
        // Cerrar pantalla
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error al registrar';
          _isCapturing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Reiniciar stream
        _startFaceDetection();
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vista de la cámara
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),
          
          // Overlay con óvalo
          Positioned.fill(
            child: CustomPaint(
              painter: FaceOvalPainter(
                faceDetected: _faceDetected,
              ),
            ),
          ),
          
          // Botón de cerrar
          Positioned(
            top: 48,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          
          // Mensaje de estado
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          
          // Botón de captura
          if (!_isCapturing)
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _captureFace,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _faceDetected
                          ? const Color(0xFF4F7A4A)
                          : Colors.grey.shade600,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Icon(
                      _faceDetected ? Icons.check : Icons.face,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// FACE OVAL PAINTER - Dibuja el óvalo guía para el rostro
// ============================================================================

class FaceOvalPainter extends CustomPainter {
  final bool faceDetected;

  FaceOvalPainter({required this.faceDetected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = faceDetected
          ? const Color(0xFF4F7A4A).withOpacity(0.5)
          : Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Dibujar overlay oscuro con agujero ovalado
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    // Óvalo centrado
    final center = Offset(size.width / 2, size.height / 2 - 50);
    final ovalWidth = size.width * 0.65;
    final ovalHeight = size.height * 0.45;
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // Borrar el área del óvalo
    canvas.saveLayer(null, Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);
    canvas.drawOval(ovalRect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    // Dibujar borde del óvalo
    canvas.drawOval(ovalRect, paint);
  }

  @override
  bool shouldRepaint(FaceOvalPainter oldDelegate) {
    return oldDelegate.faceDetected != faceDetected;
  }
}
