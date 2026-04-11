// ============================================================================
// SUPABASE CLIENT HELPER
// ============================================================================
// Helper para acceder fácilmente al cliente de Supabase desde cualquier lugar

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Instancia global del cliente de Supabase
final supabase = Supabase.instance.client;

// Helper para obtener el usuario actual
User? get currentUser => supabase.auth.currentUser;

// Helper para obtener el ID del usuario actual
String? get currentUserId => supabase.auth.currentUser?.id;

// Helper para verificar si hay un usuario autenticado
bool get isAuthenticated => supabase.auth.currentUser != null;

// ============================================================================
// EFFECTIVE USER ID
// ============================================================================
// Si el usuario actual es un cuidador, el effectiveUserId es el ID del dueño.
// Si es el usuario principal, es su propio ID.
// Esto permite que los cuidadores lean/escriban datos del bebé del dueño.

String? _cachedEffectiveUserId;
bool _effectiveUserIdChecked = false;

/// Devuelve el ID efectivo para operaciones de datos.
/// - Si es cuidador: owner_user_id
/// - Si es principal: su propio ID
Future<String?> getEffectiveUserId() async {
  final myId = currentUserId;
  if (myId == null) return null;

  if (!_effectiveUserIdChecked) {
    _effectiveUserIdChecked = true;
    try {
      final link = await supabase
          .from('family_links')
          .select('owner_user_id')
          .eq('caregiver_user_id', myId)
          .maybeSingle();
      _cachedEffectiveUserId = link?['owner_user_id'] as String? ?? myId;
      if (_cachedEffectiveUserId != myId) {
        debugPrint('👥 Cuidador detectado → owner: $_cachedEffectiveUserId');
      }
    } catch (_) {
      _cachedEffectiveUserId = myId;
    }
  }
  return _cachedEffectiveUserId;
}

/// Limpia el caché del effectiveUserId (llamar al hacer logout).
void clearEffectiveUserId() {
  _cachedEffectiveUserId = null;
  _effectiveUserIdChecked = false;
  debugPrint('🔄 EffectiveUserId limpiado');
}
