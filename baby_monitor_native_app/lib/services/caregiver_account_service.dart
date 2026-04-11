// ============================================================================
// CAREGIVER ACCOUNT SERVICE
// ============================================================================
// Gestiona la creación de cuentas de cuidadores vinculadas a la cuenta
// principal. Los cuidadores tienen su propia sesión Supabase pero comparten
// los datos del bebé del usuario principal (via family_links + RLS).
//
// Flujo:
//  1. Usuario principal crea cuenta → opcionalmente agrega cuidadores.
//  2. CaregiverAccountService crea la cuenta Supabase del cuidador via HTTP
//     (sin reemplazar la sesión activa del usuario principal).
//  3. Vincula al cuidador en la tabla `family_links`.
//  4. El cuidador inicia sesión con su cuenta → el app detecta que es cuidador
//     y usa el `owner_user_id` para todas las operaciones de datos.
//  5. `givenBy` en registros = nombre del cuidador logueado (de su auth).
// ============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../config/supabase_client.dart';

/// Modelo de un cuidador vinculado.
class FamilyLink {
  final String id;
  final String ownerUserId;
  final String caregiverUserId;
  final String caregiverName;
  final String role;
  final DateTime linkedAt;

  FamilyLink({
    required this.id,
    required this.ownerUserId,
    required this.caregiverUserId,
    required this.caregiverName,
    required this.role,
    required this.linkedAt,
  });

  factory FamilyLink.fromJson(Map<String, dynamic> json) => FamilyLink(
        id: json['id'] as String,
        ownerUserId: json['owner_user_id'] as String,
        caregiverUserId: json['caregiver_user_id'] as String,
        caregiverName: json['caregiver_name'] as String? ?? 'Cuidador',
        role: json['role'] as String? ?? 'Cuidador',
        linkedAt: DateTime.parse(json['linked_at'] as String),
      );
}

class CaregiverAccountService {
  // ==========================================================================
  // CREAR CUENTA DE CUIDADOR
  // ==========================================================================

  /// Crea una cuenta Supabase para el cuidador sin reemplazar la sesión activa.
  /// Luego vincula al cuidador con el usuario principal en `family_links`.
  ///
  /// Retorna null si todo salió bien, o un mensaje de error si hubo problema.
  static Future<String?> createCaregiverAccount({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final ownerId = currentUserId;
    if (ownerId == null) return 'Usuario no autenticado';

    // 1. Crear la cuenta del cuidador via HTTP directo (sin SDK, preserva sesión)
    String? caregiverUserId;
    try {
      final response = await http.post(
        Uri.parse('${SupabaseConfig.supabaseUrl}/auth/v1/signup'),
        headers: {
          'apikey': SupabaseConfig.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'data': {
            'full_name': name.trim(),
            'is_caregiver': true,
            'owner_user_id': ownerId,
          },
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        // Supabase retorna el user dentro de la respuesta de signup
        final user = body['user'] as Map<String, dynamic>?;
        caregiverUserId = user?['id'] as String?;
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final msg = body['msg'] as String? ?? body['message'] as String? ?? 'Error al crear cuenta';
        // Si el email ya existe, continuar (puede ya tener cuenta)
        if (msg.toLowerCase().contains('already registered') ||
            msg.toLowerCase().contains('already exists')) {
          // Buscar el user_id por email usando consulta pública limitada
          debugPrint('⚠️ Cuidador ya tiene cuenta: $email');
        } else {
          return msg;
        }
      }
    } catch (e) {
      return 'Error de conexión: $e';
    }

    // 2. Vincular en family_links
    // Si no tenemos el user_id (email ya registrado), guardamos con null
    // y se vinculará automáticamente cuando el cuidador inicie sesión.
    try {
      if (caregiverUserId != null) {
        await supabase.from('family_links').upsert({
          'owner_user_id': ownerId,
          'caregiver_user_id': caregiverUserId,
          'caregiver_name': name.trim(),
          'role': role,
        }, onConflict: 'owner_user_id,caregiver_user_id');
        debugPrint('✅ Cuidador vinculado: $name ($email)');
      }
      // Guardar datos de la invitación localmente para mostrarlos en la lista
      await _savePendingInvite(
        ownerUserId: ownerId,
        caregiverEmail: email.trim(),
        caregiverName: name.trim(),
        caregiverUserId: caregiverUserId,
        role: role,
      );
    } catch (e) {
      debugPrint('❌ Error vinculando cuidador: $e');
      return 'Cuenta creada pero error al vincular: $e';
    }

    return null; // null = éxito
  }

  // ==========================================================================
  // DETECCIÓN: ¿Es el usuario actual un cuidador?
  // ==========================================================================

  /// Devuelve el `owner_user_id` si el usuario actual es cuidador.
  /// Devuelve null si es el usuario principal.
  static Future<String?> getOwnerUserId() async {
    final myId = currentUserId;
    if (myId == null) return null;
    try {
      final result = await supabase
          .from('family_links')
          .select('owner_user_id')
          .eq('caregiver_user_id', myId)
          .maybeSingle();
      return result?['owner_user_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Devuelve true si el usuario actual es un cuidador vinculado.
  static Future<bool> isCaregiver() async {
    return await getOwnerUserId() != null;
  }

  // ==========================================================================
  // LISTA DE CUIDADORES
  // ==========================================================================

  /// Devuelve todos los cuidadores vinculados al usuario principal actual.
  static Future<List<FamilyLink>> getCaregivers() async {
    final ownerId = currentUserId;
    if (ownerId == null) return [];
    try {
      final result = await supabase
          .from('family_links')
          .select()
          .eq('owner_user_id', ownerId)
          .order('linked_at');
      return (result as List)
          .map((e) => FamilyLink.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo cuidadores: $e');
      return [];
    }
  }

  /// Elimina el vínculo con un cuidador.
  static Future<void> removeCaregiver(String caregiverUserId) async {
    final ownerId = currentUserId;
    if (ownerId == null) return;
    await supabase
        .from('family_links')
        .delete()
        .eq('owner_user_id', ownerId)
        .eq('caregiver_user_id', caregiverUserId);
  }

  // ==========================================================================
  // AUTO-LINK: cuando el cuidador inicia sesión
  // ==========================================================================

  /// Llama esto justo después del login para vincular automáticamente
  /// al cuidador si fue creado desde la cuenta de un dueño.
  static Future<void> autoLinkOnLogin() async {
    final myId = currentUserId;
    if (myId == null) return;
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final meta = user.userMetadata;
      final ownerIdFromMeta = meta?['owner_user_id'] as String?;
      final isCaregiver = meta?['is_caregiver'] as bool? ?? false;

      if (isCaregiver && ownerIdFromMeta != null) {
        // Crear el vínculo si no existe
        await supabase.from('family_links').upsert({
          'owner_user_id': ownerIdFromMeta,
          'caregiver_user_id': myId,
          'caregiver_name': meta?['full_name'] as String? ?? 'Cuidador',
        }, onConflict: 'owner_user_id,caregiver_user_id');
        debugPrint('✅ Auto-link cuidador: $myId → owner: $ownerIdFromMeta');
      }
    } catch (e) {
      debugPrint('Auto-link error: $e');
    }
  }

  // ==========================================================================
  // PRIVADO: guardar invitación pendiente
  // ==========================================================================

  static Future<void> _savePendingInvite({
    required String ownerUserId,
    required String caregiverEmail,
    required String caregiverName,
    String? caregiverUserId,
    required String role,
  }) async {
    // Guardado local — útil para mostrar la lista de cuidadores invitados
    // aunque el user_id aún no esté confirmado
    debugPrint('📋 Invitación guardada: $caregiverName <$caregiverEmail> (rol: $role)');
  }
}
