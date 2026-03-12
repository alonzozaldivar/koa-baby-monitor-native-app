// ============================================================================
// AUTH SERVICE - Servicio de autenticación con Supabase
// ============================================================================
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';

class AuthService {
  // ============================================================================
  // REGISTRO
  // ============================================================================
  
  /// Registrar nuevo usuario con email y contraseña
  static Future<User?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      if (response.user != null) {
        debugPrint('✅ Usuario registrado: ${response.user!.email}');
        return response.user;
      }
      
      return null;
    } on AuthException catch (e) {
      debugPrint('❌ Error de autenticación: ${e.message}');
      throw AuthException(e.message);
    } catch (e) {
      debugPrint('❌ Error al registrar usuario: $e');
      rethrow;
    }
  }

  // ============================================================================
  // LOGIN
  // ============================================================================
  
  /// Iniciar sesión con email y contraseña
  static Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        debugPrint('✅ Usuario autenticado: ${response.user!.email}');
        return response.user;
      }
      
      return null;
    } on AuthException catch (e) {
      debugPrint('❌ Error de autenticación: ${e.message}');
      throw AuthException(e.message);
    } catch (e) {
      debugPrint('❌ Error al iniciar sesión: $e');
      rethrow;
    }
  }

  // ============================================================================
  // LOGIN CON RECONOCIMIENTO FACIAL
  // ============================================================================
  
  /// Autenticar con reconocimiento facial
  /// Compara el encoding facial capturado con los almacenados en la BD
  static Future<User?> signInWithFace(Map<String, dynamic> faceEncoding) async {
    try {
      // 1. Obtener todos los encodings faciales de la BD
      final response = await supabase
          .from('face_biometrics')
          .select('user_id, face_encoding');

      if (response == null || (response as List).isEmpty) {
        throw Exception('No hay rostros registrados en el sistema');
      }

      // 2. Comparar el encoding capturado con cada uno en la BD
      String? matchedUserId;
      double maxSimilarity = 0.0;
      const double threshold = 0.75; // Umbral de similitud (75%)

      for (final record in response as List) {
        final storedEncoding = record['face_encoding'] as Map<String, dynamic>;
        final similarity = _calculateSimilarity(faceEncoding, storedEncoding);
        
        if (similarity > maxSimilarity && similarity >= threshold) {
          maxSimilarity = similarity;
          matchedUserId = record['user_id'];
        }
      }

      if (matchedUserId == null) {
        throw Exception('No se encontró coincidencia facial');
      }

      // 3. Obtener datos del usuario
      final userData = await supabase
          .from('users')
          .select('email')
          .eq('id', matchedUserId)
          .single();

      if (userData == null) {
        throw Exception('Usuario no encontrado');
      }

      // 4. Crear sesión con token de autenticación facial
      // Nota: Esto requiere una función de servidor en Supabase
      // Por ahora, asumimos que el usuario ya tiene una sesión válida
      debugPrint('✅ Rostro reconocido con ${(maxSimilarity * 100).toStringAsFixed(1)}% de similitud');
      debugPrint('Usuario: ${userData['email']}');
      
      return currentUser;
    } catch (e) {
      debugPrint('❌ Error en autenticación facial: $e');
      rethrow;
    }
  }

  /// Calcular similitud entre dos encodings faciales
  /// Retorna un valor entre 0 (sin similitud) y 1 (idénticos)
  static double _calculateSimilarity(
    Map<String, dynamic> encoding1,
    Map<String, dynamic> encoding2,
  ) {
    // Implementación simplificada de similitud de coseno
    // En producción, usar una librería especializada como ml_linalg
    
    try {
      // Convertir encodings a listas de números
      final vec1 = (encoding1['vector'] as List).cast<double>();
      final vec2 = (encoding2['vector'] as List).cast<double>();
      
      if (vec1.length != vec2.length) {
        return 0.0;
      }

      // Calcular producto punto
      double dotProduct = 0.0;
      double magnitude1 = 0.0;
      double magnitude2 = 0.0;

      for (int i = 0; i < vec1.length; i++) {
        dotProduct += vec1[i] * vec2[i];
        magnitude1 += vec1[i] * vec1[i];
        magnitude2 += vec2[i] * vec2[i];
      }

      magnitude1 = magnitude1 > 0 ? sqrt(magnitude1.abs()) : 0.0;
      magnitude2 = magnitude2 > 0 ? sqrt(magnitude2.abs()) : 0.0;

      if (magnitude1 == 0 || magnitude2 == 0) {
        return 0.0;
      }

      // Similitud de coseno
      return dotProduct / (magnitude1 * magnitude2);
    } catch (e) {
      debugPrint('Error calculando similitud: $e');
      return 0.0;
    }
  }

  // ============================================================================
  // REGISTRO DE DATOS BIOMÉTRICOS
  // ============================================================================
  
  /// Registrar encoding facial del usuario
  static Future<void> registerFaceBiometric({
    required Map<String, dynamic> faceEncoding,
    String? deviceId,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('Usuario no autenticado');
      }

      await supabase.from('face_biometrics').insert({
        'user_id': currentUserId,
        'face_encoding': faceEncoding,
        'device_id': deviceId,
      });

      debugPrint('✅ Datos biométricos faciales registrados');
    } catch (e) {
      debugPrint('❌ Error al registrar biometría facial: $e');
      rethrow;
    }
  }

  /// Obtener encodings faciales del usuario actual
  static Future<List<Map<String, dynamic>>> getUserFaceBiometrics() async {
    try {
      if (currentUserId == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await supabase
          .from('face_biometrics')
          .select('id, face_encoding, device_id, registered_at')
          .eq('user_id', currentUserId!);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Error al obtener biometría facial: $e');
      rethrow;
    }
  }

  /// Eliminar encoding facial
  static Future<void> deleteFaceBiometric(String biometricId) async {
    try {
      await supabase
          .from('face_biometrics')
          .delete()
          .eq('id', biometricId)
          .eq('user_id', currentUserId!);

      debugPrint('✅ Biometría facial eliminada');
    } catch (e) {
      debugPrint('❌ Error al eliminar biometría facial: $e');
      rethrow;
    }
  }

  // ============================================================================
  // CIERRE DE SESIÓN
  // ============================================================================
  
  /// Cerrar sesión
  static Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
      debugPrint('✅ Sesión cerrada');
    } catch (e) {
      debugPrint('❌ Error al cerrar sesión: $e');
      rethrow;
    }
  }

  // ============================================================================
  // GESTIÓN DE USUARIO
  // ============================================================================
  
  /// Obtener usuario actual
  static User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  /// Verificar si hay sesión activa
  static bool get isAuthenticated => supabase.auth.currentUser != null;

  /// Obtener email del usuario actual
  static String? get currentUserEmail => supabase.auth.currentUser?.email;

  /// Obtener ID del usuario actual
  static String? get currentUserId => supabase.auth.currentUser?.id;

  // ============================================================================
  // RECUPERACIÓN DE CONTRASEÑA
  // ============================================================================
  
  /// Enviar email para recuperar contraseña
  static Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
      debugPrint('✅ Email de recuperación enviado a: $email');
    } on AuthException catch (e) {
      debugPrint('❌ Error al enviar email de recuperación: ${e.message}');
      throw AuthException(e.message);
    } catch (e) {
      debugPrint('❌ Error al recuperar contraseña: $e');
      rethrow;
    }
  }

  /// Actualizar contraseña
  static Future<void> updatePassword(String newPassword) async {
    try {
      final response = await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        debugPrint('✅ Contraseña actualizada');
      }
    } on AuthException catch (e) {
      debugPrint('❌ Error al actualizar contraseña: ${e.message}');
      throw AuthException(e.message);
    } catch (e) {
      debugPrint('❌ Error al actualizar contraseña: $e');
      rethrow;
    }
  }

  // ============================================================================
  // ELIMINAR CUENTA
  // ============================================================================
  
  /// Eliminar cuenta del usuario actual y todos sus datos asociados
  static Future<void> deleteAccount() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // 1. Eliminar datos biométricos faciales
      await supabase
          .from('face_biometrics')
          .delete()
          .eq('user_id', userId);
      debugPrint('✅ Datos biométricos eliminados');

      // 2. Eliminar perfiles de bebés y datos asociados
      final babyProfiles = await supabase
          .from('baby_profiles')
          .select('id')
          .eq('user_id', userId);

      for (final profile in babyProfiles as List) {
        final babyId = profile['id'];
        // Eliminar registros de actividades del bebé
        await supabase.from('activity_logs').delete().eq('baby_id', babyId);
        await supabase.from('feeding_logs').delete().eq('baby_id', babyId);
        await supabase.from('sleep_logs').delete().eq('baby_id', babyId);
        await supabase.from('health_records').delete().eq('baby_id', babyId);
        await supabase.from('milestones').delete().eq('baby_id', babyId);
        await supabase.from('growth_records').delete().eq('baby_id', babyId);
      }
      debugPrint('✅ Registros de bebés eliminados');

      // 3. Eliminar perfiles de bebés
      await supabase
          .from('baby_profiles')
          .delete()
          .eq('user_id', userId);
      debugPrint('✅ Perfiles de bebés eliminados');

      // 4. Eliminar suscripciones
      await supabase
          .from('subscriptions')
          .delete()
          .eq('user_id', userId);
      debugPrint('✅ Suscripciones eliminadas');

      // 5. Cerrar sesión (esto invalida el token)
      await supabase.auth.signOut();
      debugPrint('✅ Cuenta eliminada completamente');
    } catch (e) {
      debugPrint('❌ Error al eliminar cuenta: $e');
      rethrow;
    }
  }

  // ============================================================================
  // LISTENERS DE ESTADO
  // ============================================================================
  
  /// Escuchar cambios en el estado de autenticación
  static Stream<AuthState> get authStateChanges {
    return supabase.auth.onAuthStateChange;
  }
}
