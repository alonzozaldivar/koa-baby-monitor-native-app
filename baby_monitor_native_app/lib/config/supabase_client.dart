// ============================================================================
// SUPABASE CLIENT HELPER
// ============================================================================
// Helper para acceder fácilmente al cliente de Supabase desde cualquier lugar

import 'package:supabase_flutter/supabase_flutter.dart';

// Instancia global del cliente de Supabase
final supabase = Supabase.instance.client;

// Helper para obtener el usuario actual
User? get currentUser => supabase.auth.currentUser;

// Helper para obtener el ID del usuario actual
String? get currentUserId => supabase.auth.currentUser?.id;

// Helper para verificar si hay un usuario autenticado
bool get isAuthenticated => supabase.auth.currentUser != null;
