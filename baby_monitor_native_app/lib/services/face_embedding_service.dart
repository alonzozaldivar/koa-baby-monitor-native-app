// ============================================================================
// FACE EMBEDDING SERVICE - Genera embeddings faciales con MobileFaceNet TFLite
// ============================================================================
// Modelo: mobilefacenet.tflite (~5MB)
// Input : [1, 112, 112, 3] float32 normalizado a [-1, 1]
// Output: [1, N] float32 embedding L2-normalizado (N detectado dinámicamente)
// ============================================================================

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Rect;
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FaceEmbeddingService {
  // Singleton
  static final FaceEmbeddingService instance = FaceEmbeddingService._();
  FaceEmbeddingService._();

  Interpreter? _interpreter;
  int _embeddingSize = 192; // MobileFaceNet default; se sobreescribe al cargar
  bool _isInitialized = false;

  static const int _inputSize = 112; // MobileFaceNet espera 112x112
  static const double _padding = 20.0; // Padding alrededor del bounding box

  // ============================================================================
  // INICIALIZACIÓN
  // ============================================================================

  Future<void> initialize() async {
    if (_isInitialized && _interpreter != null) return;

    try {
      _interpreter = await Interpreter.fromAsset('models/mobilefacenet.tflite');

      // Detectar tamaño del embedding dinámicamente desde el modelo
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      if (outputShape.length >= 2) {
        _embeddingSize = outputShape[1];
      }

      _isInitialized = true;
      debugPrint('✅ MobileFaceNet cargado — embedding size: $_embeddingSize');
    } catch (e) {
      _isInitialized = false;
      debugPrint('❌ Error cargando MobileFaceNet: $e');
      rethrow;
    }
  }

  // ============================================================================
  // GENERAR EMBEDDING
  // ============================================================================

  /// Genera un vector de embedding L2-normalizado para el rostro en [imageBytes].
  /// Si se proporciona [faceBounds], se recorta la región del rostro antes de
  /// procesar. Devuelve null si algo falla.
  Future<List<double>?> generateEmbedding(
    Uint8List imageBytes,
    Rect? faceBounds,
  ) async {
    if (!_isInitialized || _interpreter == null) {
      try {
        await initialize();
      } catch (_) {
        return null;
      }
    }

    try {
      // 1. Decodificar imagen
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) return null;

      // 2. Recortar al rostro con padding
      img.Image faceImage = decoded;
      if (faceBounds != null) {
        final x = (faceBounds.left - _padding)
            .clamp(0.0, decoded.width.toDouble() - 1)
            .toInt();
        final y = (faceBounds.top - _padding)
            .clamp(0.0, decoded.height.toDouble() - 1)
            .toInt();
        final w = (faceBounds.width + _padding * 2)
            .clamp(1.0, (decoded.width - x).toDouble())
            .toInt();
        final h = (faceBounds.height + _padding * 2)
            .clamp(1.0, (decoded.height - y).toDouble())
            .toInt();
        faceImage = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
      }

      // 3. Redimensionar a 112x112
      final resized =
          img.copyResize(faceImage, width: _inputSize, height: _inputSize);

      // 4. Construir tensor de entrada [1, 112, 112, 3]
      //    Normalizar píxeles de [0,255] → [-1,1] : (pixel/127.5) - 1.0
      final input = List.generate(
        1,
        (_) => List.generate(
          _inputSize,
          (y) => List.generate(
            _inputSize,
            (x) {
              final pixel = resized.getPixel(x, y);
              return [
                (pixel.r.toDouble() / 127.5) - 1.0,
                (pixel.g.toDouble() / 127.5) - 1.0,
                (pixel.b.toDouble() / 127.5) - 1.0,
              ];
            },
          ),
        ),
      );

      // 5. Tensor de salida [1, embeddingSize]
      final output = List.generate(
        1,
        (_) => List<double>.filled(_embeddingSize, 0.0),
      );

      // 6. Inferencia
      _interpreter!.run(input, output);

      // 7. Normalizar L2 y devolver
      return _l2Normalize(output[0]);
    } catch (e) {
      debugPrint('Error generando embedding facial: $e');
      return null;
    }
  }

  // ============================================================================
  // UTILIDADES
  // ============================================================================

  List<double> _l2Normalize(List<double> vector) {
    double norm = 0.0;
    for (final v in vector) norm += v * v;
    norm = math.sqrt(norm);
    if (norm == 0) return vector;
    return vector.map((v) => v / norm).toList();
  }

  /// Similitud de coseno entre dos embeddings L2-normalizados.
  /// Retorna un valor en [0, 1], donde 1 = idénticos.
  /// Umbral recomendado para MobileFaceNet: >= 0.70 → misma persona.
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = math.sqrt(normA) * math.sqrt(normB);
    return denom == 0 ? 0.0 : (dot / denom).clamp(0.0, 1.0);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
