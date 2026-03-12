import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'services/face_embedding_service.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Configuración
import 'config/supabase_config.dart';
import 'config/supabase_client.dart';

// Servicios personalizados
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/subscription_service.dart';
import 'screens/premium_paywall_page.dart';

// Pantallas de autenticación
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';

// Widgets
import 'widgets/koala_tip_widget.dart';

// Modelos
import 'models/app_models.dart' show Caregiver;

// Datos de referencia OMS
import 'data/who_standards.dart';
import 'data/vaccine_schedule.dart';

// ============================================================================
// APP STATE - Maneja tema oscuro, idioma y estado global
// ============================================================================
class AppState extends ChangeNotifier {
  bool _isDarkMode = false;
  Locale _locale = const Locale('es');
  int _profileRefreshKey = 0;

  bool get isDarkMode => _isDarkMode;
  Locale get locale => _locale;
  int get profileRefreshKey => _profileRefreshKey;

  // Llamar cuando se actualice el perfil del bebé
  void refreshProfile() {
    _profileRefreshKey++;
    notifyListeners();
  }

  AppState() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    final langCode = prefs.getString('language_code') ?? 'es';
    _locale = Locale(langCode);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
    notifyListeners();
  }

  // Traducciones simples
  String tr(String key) {
    final isSpanish = _locale.languageCode == 'es';
    final translations = <String, Map<String, String>>{
      'home': {'es': 'Inicio', 'en': 'Home'},
      'registry': {'es': 'Registro', 'en': 'Registry'},
      'stats': {'es': 'Estadísticas', 'en': 'Stats'},
      'settings': {'es': 'Ajustes', 'en': 'Settings'},
      'appearance': {'es': 'Apariencia', 'en': 'Appearance'},
      'dark_mode': {'es': 'Modo oscuro', 'en': 'Dark mode'},
      'language': {'es': 'Idioma', 'en': 'Language'},
      'spanish': {'es': 'Español', 'en': 'Spanish'},
      'english': {'es': 'Inglés', 'en': 'English'},
      'account': {'es': 'Cuenta', 'en': 'Account'},
      'logout': {'es': 'Cerrar sesión', 'en': 'Log out'},
      'logout_confirm': {'es': '¿Seguro que quieres cerrar sesión?', 'en': 'Are you sure you want to log out?'},
      'cancel': {'es': 'Cancelar', 'en': 'Cancel'},
      'confirm': {'es': 'Confirmar', 'en': 'Confirm'},
      'switch_account': {'es': 'Cambiar de cuenta', 'en': 'Switch account'},
      'switch_account_confirm': {'es': 'Se cerrará la sesión actual para iniciar con otra cuenta.', 'en': 'The current session will be closed to sign in with another account.'},
      'delete_account': {'es': 'Eliminar cuenta', 'en': 'Delete account'},
      'delete_account_title': {'es': 'Eliminar cuenta', 'en': 'Delete account'},
      'delete_account_warning': {'es': 'Esta acción es irreversible. Se eliminarán todos tus datos, perfiles de bebés, registros y configuraciones. \n\nEscribe ELIMINAR para confirmar.', 'en': 'This action is irreversible. All your data, baby profiles, records and settings will be deleted. \n\nType DELETE to confirm.'},
      'delete_account_confirm_word_es': {'es': 'ELIMINAR', 'en': 'DELETE'},
      'delete_account_success': {'es': 'Cuenta eliminada correctamente', 'en': 'Account deleted successfully'},
      'delete_account_error': {'es': 'Error al eliminar la cuenta. Intenta de nuevo.', 'en': 'Error deleting account. Please try again.'},
      'delete_account_wrong_word': {'es': 'Escribe ELIMINAR para confirmar', 'en': 'Type DELETE to confirm'},
      'main_sections': {'es': 'Apartados principales', 'en': 'Main sections'},
      'recent_activities': {'es': 'Últimas actividades', 'en': 'Recent activities'},
      'food': {'es': 'Comida', 'en': 'Food'},
      'food_desc': {'es': 'Registro de tomas, horarios y notas sobre la alimentación.', 'en': 'Feeding logs, schedules and nutrition notes.'},
      'camera': {'es': 'Monitor cámara', 'en': 'Camera monitor'},
      'camera_desc': {'es': 'Monitoreo visual en tiempo real.', 'en': 'Real-time visual monitoring.'},
      'health': {'es': 'Salud', 'en': 'Health'},
      'health_desc': {'es': 'Vacunas, peso, citas médicas y más.', 'en': 'Vaccines, weight, medical appointments and more.'},
      'diary': {'es': 'Diario de recuerdos', 'en': 'Memory diary'},
      'diary_desc': {'es': 'Hitos y momentos especiales.', 'en': 'Special moments and milestones.'},
      'sleep': {'es': 'Sueño', 'en': 'Sleep'},
      'sleep_desc': {'es': 'Registro y seguimiento de las horas de sueño.', 'en': 'Sleep tracking and monitoring.'},
      'activity_log': {'es': 'Registro de actividades', 'en': 'Activity log'},
      'no_activities': {'es': 'Aún no hay actividades registradas.', 'en': 'No activities recorded yet.'},
      'statistics': {'es': 'Estadísticas', 'en': 'Statistics'},
      'coming_soon': {'es': 'Próximamente', 'en': 'Coming soon'},
      'stats_desc': {'es': 'Aquí podrás ver gráficas y resúmenes de las actividades de tu bebé.', 'en': 'Here you will see charts and summaries of your baby\'s activities.'},
      'skip': {'es': 'Saltar', 'en': 'Skip'},
      'year': {'es': 'año', 'en': 'year'},
      'years': {'es': 'años', 'en': 'years'},
      'months': {'es': 'meses', 'en': 'months'},
      'month': {'es': 'mes', 'en': 'month'},
      'days': {'es': 'días', 'en': 'days'},
      'day': {'es': 'día', 'en': 'day'},
      'old': {'es': 'de edad', 'en': 'old'},
      'and': {'es': 'y', 'en': 'and'},
      // Facial auth translations
      'face_auth': {'es': 'Autenticación Facial', 'en': 'Facial Authentication'},
      'position_face': {'es': 'Posiciona tu rostro en el óvalo', 'en': 'Position your face in the oval'},
      'scanning': {'es': 'Escaneando...', 'en': 'Scanning...'},
      'face_detected': {'es': 'Rostro detectado', 'en': 'Face detected'},
      'no_face': {'es': 'No se detecta rostro', 'en': 'No face detected'},
      'auth_success': {'es': '¡Autenticación exitosa!', 'en': 'Authentication successful!'},
      'auth_failed': {'es': 'Rostro no autorizado. Acceso denegado.', 'en': 'Unauthorized face. Access denied.'},
      'register_face': {'es': 'Registrar rostro', 'en': 'Register face'},
      'face_registered': {'es': 'Rostro registrado correctamente', 'en': 'Face registered successfully'},
      'hold_still': {'es': 'Mantén la posición...', 'en': 'Hold still...'},
      'verifying': {'es': 'Verificando...', 'en': 'Verifying...'},
      'try_again': {'es': 'Intentar de nuevo', 'en': 'Try again'},
      'use_pin': {'es': 'Usar PIN', 'en': 'Use PIN'},
      'welcome_back': {'es': 'Bienvenido de nuevo', 'en': 'Welcome back'},
      'setup_face_id': {'es': 'Configurar Face ID', 'en': 'Setup Face ID'},
      'setup_face_desc': {'es': 'Registra tu rostro para acceder rápidamente a KOA', 'en': 'Register your face for quick access to KOA'},
      'skip_for_now': {'es': 'Omitir por ahora', 'en': 'Skip for now'},
      'camera_error': {'es': 'Error al acceder a la cámara', 'en': 'Error accessing camera'},
      'register_face_title': {'es': 'Registra tu rostro', 'en': 'Register your face'},
      'register_face_subtitle': {'es': 'Para acceso rápido y seguro a KOA', 'en': 'For quick and secure access to KOA'},
      'position_face_register': {'es': 'Coloca tu rostro dentro del óvalo', 'en': 'Place your face inside the oval'},
      'error_capture': {'es': 'Error al capturar. Intenta de nuevo.', 'en': 'Capture error. Try again.'},
      // Profile selection
      'select_profile': {'es': 'Selecciona un perfil', 'en': 'Select a profile'},
      'your_babies': {'es': 'Tus bebés', 'en': 'Your babies'},
      'add_new_baby': {'es': 'Agregar nuevo bebé', 'en': 'Add new baby'},
      'tap_to_access': {'es': 'Toca para acceder', 'en': 'Tap to access'},
      // Profile menu options
      'profile_options': {'es': 'Opciones del perfil', 'en': 'Profile options'},
      'change_photo': {'es': 'Cambiar foto', 'en': 'Change photo'},
      'edit_name': {'es': 'Editar nombre', 'en': 'Edit name'},
      'edit_birthdate': {'es': 'Editar fecha de nacimiento', 'en': 'Edit birthdate'},
      'edit_gender': {'es': 'Editar género', 'en': 'Edit gender'},
      'delete_profile': {'es': 'Eliminar perfil', 'en': 'Delete profile'},
      'delete_confirm': {'es': '¿Seguro que quieres eliminar este perfil?', 'en': 'Are you sure you want to delete this profile?'},
      'delete': {'es': 'Eliminar', 'en': 'Delete'},
      'save': {'es': 'Guardar', 'en': 'Save'},
      'enter_name': {'es': 'Ingresa el nombre', 'en': 'Enter name'},
      'profile_deleted': {'es': 'Perfil eliminado', 'en': 'Profile deleted'},
      'changes_saved': {'es': 'Cambios guardados', 'en': 'Changes saved'},
      // Diary translations
      'diary_title': {'es': 'Diario de Recuerdos', 'en': 'Memory Diary'},
      'milestones': {'es': 'Hitos', 'en': 'Milestones'},
      'add_milestone': {'es': 'Agregar hito', 'en': 'Add milestone'},
      'suggested_milestones': {'es': 'Hitos sugeridos', 'en': 'Suggested milestones'},
      'my_milestones': {'es': 'Mis hitos', 'en': 'My milestones'},
      'no_milestones': {'es': 'Aún no hay hitos registrados', 'en': 'No milestones recorded yet'},
      'add_first_milestone': {'es': 'Agrega el primer recuerdo especial', 'en': 'Add the first special memory'},
      'select_milestone': {'es': 'Selecciona un hito', 'en': 'Select a milestone'},
      'custom_milestone': {'es': 'Hito personalizado', 'en': 'Custom milestone'},
      'milestone_title': {'es': 'Título del hito', 'en': 'Milestone title'},
      'milestone_description': {'es': 'Descripción (opcional)', 'en': 'Description (optional)'},
      'milestone_date': {'es': 'Fecha del hito', 'en': 'Milestone date'},
      'add_photo': {'es': 'Agregar foto', 'en': 'Add photo'},
      'take_photo': {'es': 'Tomar foto', 'en': 'Take photo'},
      'choose_gallery': {'es': 'Elegir de galería', 'en': 'Choose from gallery'},
      'milestone_saved': {'es': 'Hito guardado', 'en': 'Milestone saved'},
      'milestone_deleted': {'es': 'Hito eliminado', 'en': 'Milestone deleted'},
      'delete_milestone': {'es': 'Eliminar hito', 'en': 'Delete milestone'},
      'delete_milestone_confirm': {'es': '¿Eliminar este recuerdo?', 'en': 'Delete this memory?'},
      'generate_album': {'es': 'Generar álbum', 'en': 'Generate album'},
      'download_album': {'es': 'Descargar álbum', 'en': 'Download album'},
      'share_album': {'es': 'Compartir álbum', 'en': 'Share album'},
      'album_preview': {'es': 'Vista previa del álbum', 'en': 'Album preview'},
      'album_generated': {'es': 'Álbum generado', 'en': 'Album generated'},
      'album_saved': {'es': 'Álbum guardado en Descargas', 'en': 'Album saved to Downloads'},
      'generating_album': {'es': 'Generando álbum...', 'en': 'Generating album...'},
      'age_stage_newborn': {'es': 'Recién nacido', 'en': 'Newborn'},
      'age_stage_baby': {'es': 'Bebé', 'en': 'Baby'},
      'age_stage_toddler': {'es': 'Niño pequeño', 'en': 'Toddler'},
      'age_stage_preschool': {'es': 'Preescolar', 'en': 'Preschooler'},
      // Milestone names
      'first_smile': {'es': 'Primera sonrisa', 'en': 'First smile'},
      'first_bath': {'es': 'Primer baño', 'en': 'First bath'},
      'held_head': {'es': 'Sostuvo su cabecita', 'en': 'Held head up'},
      'first_outing': {'es': 'Primer paseo', 'en': 'First outing'},
      'slept_through': {'es': 'Durmió toda la noche', 'en': 'Slept through the night'},
      'first_laugh': {'es': 'Primera carcajada', 'en': 'First laugh'},
      'first_tooth': {'es': 'Primer diente', 'en': 'First tooth'},
      'first_solids': {'es': 'Primeros sólidos', 'en': 'First solids'},
      'sat_alone': {'es': 'Se sentó solito', 'en': 'Sat alone'},
      'first_words': {'es': 'Primeras palabras', 'en': 'First words'},
      'first_steps': {'es': 'Primeros pasos', 'en': 'First steps'},
      'first_crawl': {'es': 'Empezó a gatear', 'en': 'Started crawling'},
      'waved_bye': {'es': 'Dijo adiós con la mano', 'en': 'Waved bye-bye'},
      'clapped_hands': {'es': 'Aplaudió', 'en': 'Clapped hands'},
      'first_birthday': {'es': 'Primer cumpleaños', 'en': 'First birthday'},
      'first_run': {'es': 'Corrió por primera vez', 'en': 'First run'},
      'first_sentences': {'es': 'Primeras oraciones', 'en': 'First sentences'},
      'playground_first': {'es': 'Primera vez en el parque', 'en': 'First playground visit'},
      'potty_trained': {'es': 'Aprendió a usar el baño', 'en': 'Potty trained'},
      'second_birthday': {'es': 'Segundo cumpleaños', 'en': 'Second birthday'},
      'first_school': {'es': 'Primer día de escuela', 'en': 'First day of school'},
      'first_friend': {'es': 'Primer amiguito', 'en': 'First friend'},
      'first_drawing': {'es': 'Primer dibujo', 'en': 'First drawing'},
      'learned_colors': {'es': 'Aprendió los colores', 'en': 'Learned colors'},
      'third_birthday': {'es': 'Tercer cumpleaños', 'en': 'Third birthday'},
      'first_pet': {'es': 'Primera mascota', 'en': 'First pet'},
      'first_trip': {'es': 'Primer viaje', 'en': 'First trip'},
      'special_moment': {'es': 'Momento especial', 'en': 'Special moment'},
      // Camera monitor translations
      'camera_monitor': {'es': 'Monitor de Cámara', 'en': 'Camera Monitor'},
      'no_camera_configured': {'es': 'No hay cámara configurada', 'en': 'No camera configured'},
      'add_camera': {'es': 'Agregar cámara', 'en': 'Add camera'},
      'configure_camera': {'es': 'Configurar cámara', 'en': 'Configure camera'},
      'camera_name': {'es': 'Nombre de la cámara', 'en': 'Camera name'},
      'camera_name_hint': {'es': 'Ej: Cuarto del bebé', 'en': 'Ex: Baby room'},
      'host_ip': {'es': 'IP o Host', 'en': 'IP or Host'},
      'host_ip_hint': {'es': 'Ej: 192.168.1.100', 'en': 'Ex: 192.168.1.100'},
      'rtsp_port': {'es': 'Puerto RTSP', 'en': 'RTSP Port'},
      'rtsp_path': {'es': 'Ruta RTSP', 'en': 'RTSP Path'},
      'rtsp_path_hint': {'es': 'Ej: /stream1 o /live/ch0', 'en': 'Ex: /stream1 or /live/ch0'},
      'username': {'es': 'Usuario', 'en': 'Username'},
      'password': {'es': 'Contraseña', 'en': 'Password'},
      'test_connection': {'es': 'Probar conexión', 'en': 'Test connection'},
      'connecting': {'es': 'Conectando...', 'en': 'Connecting...'},
      'connected': {'es': 'Conectado', 'en': 'Connected'},
      'disconnected': {'es': 'Desconectado', 'en': 'Disconnected'},
      'connection_error': {'es': 'Error de conexión', 'en': 'Connection error'},
      'connection_success': {'es': 'Conexión exitosa', 'en': 'Connection successful'},
      'live_view': {'es': 'Vista en vivo', 'en': 'Live view'},
      'fullscreen': {'es': 'Pantalla completa', 'en': 'Fullscreen'},
      'snapshot': {'es': 'Capturar imagen', 'en': 'Take snapshot'},
      'snapshot_saved': {'es': 'Imagen guardada', 'en': 'Snapshot saved'},
      'ptz_controls': {'es': 'Controles PTZ', 'en': 'PTZ Controls'},
      'zoom_in': {'es': 'Acercar', 'en': 'Zoom in'},
      'zoom_out': {'es': 'Alejar', 'en': 'Zoom out'},
      'camera_settings': {'es': 'Configuración de cámara', 'en': 'Camera settings'},
      'delete_camera': {'es': 'Eliminar cámara', 'en': 'Delete camera'},
      'delete_camera_confirm': {'es': '¿Eliminar esta cámara?', 'en': 'Delete this camera?'},
      'camera_deleted': {'es': 'Cámara eliminada', 'en': 'Camera deleted'},
      'camera_saved': {'es': 'Cámara guardada', 'en': 'Camera saved'},
      'stream_quality': {'es': 'Calidad del stream', 'en': 'Stream quality'},
      'high_quality': {'es': 'Alta calidad', 'en': 'High quality'},
      'low_quality': {'es': 'Baja calidad (ahorra datos)', 'en': 'Low quality (saves data)'},
      'audio_enabled': {'es': 'Audio habilitado', 'en': 'Audio enabled'},
      'retry_connection': {'es': 'Reintentar conexión', 'en': 'Retry connection'},
      'watching_baby': {'es': 'Vigilando a tu bebé', 'en': 'Watching your baby'},
      'tap_to_configure': {'es': 'Toca para configurar tu cámara', 'en': 'Tap to configure your camera'},
      // Caregivers
      'caregivers': {'es': 'Cuidadores', 'en': 'Caregivers'},
      'add_caregiver': {'es': 'Agregar cuidador', 'en': 'Add caregiver'},
      'caregiver_name': {'es': 'Nombre del cuidador', 'en': 'Caregiver name'},
      'caregiver_role': {'es': 'Rol / Relación', 'en': 'Role / Relation'},
      'no_caregivers': {'es': 'Agrega un cuidador para compartir el cuidado', 'en': 'Add a caregiver to share the care'},
      'delete_caregiver': {'es': 'Eliminar cuidador', 'en': 'Delete caregiver'},
      'delete_caregiver_confirm': {'es': '¿Eliminar a este cuidador?', 'en': 'Delete this caregiver?'},
      'caregiver_added': {'es': 'Cuidador agregado', 'en': 'Caregiver added'},
      'caregiver_deleted': {'es': 'Cuidador eliminado', 'en': 'Caregiver deleted'},
      'role_mom': {'es': 'Mamá', 'en': 'Mom'},
      'role_dad': {'es': 'Papá', 'en': 'Dad'},
      'role_grandparent': {'es': 'Abuelo/a', 'en': 'Grandparent'},
      'role_nanny': {'es': 'Niñera', 'en': 'Nanny'},
      'role_other': {'es': 'Otro', 'en': 'Other'},
    };
    return translations[key]?[isSpanish ? 'es' : 'en'] ?? key;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  debugPrint('✅ Supabase inicializado');
  
  // Inicializar MediaKit para streaming RTSP
  MediaKit.ensureInitialized();
  
  // Inicializar servicio de notificaciones
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  
  debugPrint('✅ Todos los servicios inicializados');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'KOA - Monitoreo de tu bebé',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('es'),
              Locale('en'),
            ],
            locale: appState.locale,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const InitialScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB6D7A8),
        primary: const Color(0xFFB6D7A8),
        secondary: const Color(0xFFCFE8C9),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5FFF3),
      cardColor: Colors.white,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4F7A4A),
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: Color(0xFF6E8F6A),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB6D7A8),
        primary: const Color(0xFFB6D7A8),
        secondary: const Color(0xFF4F7A4A),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      cardColor: const Color(0xFF252540),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFFB6D7A8),
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: Color(0xFFCFE8C9),
        ),
      ),
    );
  }
}

// ============================================================================
// INITIAL SCREEN - Determina qué pantalla mostrar al iniciar
// ============================================================================
class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // 1. Verificar si hay sesión activa en Supabase
    final hasActiveSession = isAuthenticated;
    debugPrint('🔑 Sesión activa: $hasActiveSession');

    if (hasActiveSession) {
      // Usuario ya tiene sesión → ir directo a selección de perfil
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const ProfileSelectionPage(),
        ),
      );
      return;
    }

    // 2. Verificar si ya vio el video de intro
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro = prefs.getBool('has_seen_intro') ?? false;
    debugPrint('🎥 Ya vio intro: $hasSeenIntro');

    if (hasSeenIntro || kIsWeb) {
      // Ya vio el intro o está en web → ir a pantalla de bienvenida
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const WelcomeScreen(),
        ),
      );
    } else {
      // Primera vez en móvil → mostrar video intro
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const IntroVideoPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de carga mientras determina la ruta
    return Scaffold(
      backgroundColor: const Color(0xFFB6D7A8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.child_care,
                size: 60,
                color: Color(0xFF4F7A4A),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'KOA',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PROFILE SELECTION PAGE - Selección de perfil existente o crear nuevo
// ============================================================================
class ProfileSelectionPage extends StatefulWidget {
  const ProfileSelectionPage({super.key});

  @override
  State<ProfileSelectionPage> createState() => _ProfileSelectionPageState();
}

class _ProfileSelectionPageState extends State<ProfileSelectionPage> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  int _lastRefreshKey = -1;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);
    if (_lastRefreshKey != appState.profileRefreshKey) {
      _lastRefreshKey = appState.profileRefreshKey;
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Verificar si hay perfil por el flag O por datos existentes
    final hasProfileFlag = prefs.getBool('has_infant_profile') ?? false;
    final infantName = prefs.getString('infant_name');
    final hasProfile = hasProfileFlag || (infantName != null && infantName.isNotEmpty);
    
    // Si hay datos pero no hay flag, corregir el flag
    if (!hasProfileFlag && hasProfile) {
      await prefs.setBool('has_infant_profile', true);
    }
    
    debugPrint('=== ProfileSelectionPage._loadProfile ===');
    debugPrint('hasProfile: $hasProfile, name: $infantName');
    
    if (hasProfile) {
      final name = infantName ?? 'Bebé';
      final gender = prefs.getString('infant_gender') ?? 'otro';
      final photoBase64 = prefs.getString('infant_photo');
      final birthIso = prefs.getString('infant_birthdate');
      
      Uint8List? photoBytes;
      if (photoBase64 != null && photoBase64.isNotEmpty) {
        try {
          photoBytes = base64Decode(photoBase64);
        } catch (_) {}
      }

      String ageText = '';
      if (birthIso != null) {
        try {
          final birthDate = DateTime.parse(birthIso);
          final now = DateTime.now();
          final diff = now.difference(birthDate);
          final months = diff.inDays ~/ 30;
          final days = diff.inDays % 30;
          ageText = '$months meses, $days días';
        } catch (_) {}
      }

      setState(() {
        _profileData = {
          'name': name,
          'gender': gender,
          'photo': photoBytes,
          'age': ageText,
        };
        _isLoading = false;
      });
    } else {
      setState(() {
        _profileData = null;
        _isLoading = false;
      });
    }
  }

  void _selectProfile() {
    // Ir a autenticación facial
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const BiometricLoginPage(hasInfantProfile: true),
      ),
    );
  }

  void _createNewProfile() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const InfantRegistrationPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5FFF3),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFB6D7A8)),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.3),
            radius: 1.2,
            colors: isDark
                ? [const Color(0xFF252540), const Color(0xFF1A1A2E)]
                : [const Color(0xFFE8F7E4), const Color(0xFFCFE8C9), const Color(0xFFB6D7A8)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Logo
                Text(
                  'KOA',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: isDark ? const Color(0xFFB6D7A8) : const Color(0xFF4F7A4A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  appState.tr('select_profile'),
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.white70 : const Color(0xFF6E8F6A),
                  ),
                ),
                const SizedBox(height: 48),

                // Perfil existente
                if (_profileData != null) ...[
                  Text(
                    appState.tr('your_babies'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : const Color(0xFF6E8F6A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProfileCard(appState, isDark),
                  const SizedBox(height: 32),
                ],

                // Botón crear nuevo
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _createNewProfile,
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(appState.tr('add_new_baby')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFFB6D7A8) : const Color(0xFF4F7A4A),
                      side: BorderSide(
                        color: isDark ? const Color(0xFFB6D7A8) : const Color(0xFF4F7A4A),
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(AppState appState, bool isDark) {
    final gender = _profileData!['gender'] as String;
    final photoBytes = _profileData!['photo'] as Uint8List?;
    final name = _profileData!['name'] as String;
    final age = _profileData!['age'] as String;

    Color cardColor;
    Color avatarBg;
    switch (gender.toLowerCase()) {
      case 'masculino':
        cardColor = const Color(0xFFB3D9FF);
        avatarBg = const Color(0xFFE0F0FF);
        break;
      case 'femenino':
        cardColor = const Color(0xFFF7C7C7);
        avatarBg = const Color(0xFFFDEFEF);
        break;
      default:
        cardColor = const Color(0xFFFFF3B0);
        avatarBg = const Color(0xFFFFFDE7);
    }

    return GestureDetector(
      onTap: _selectProfile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: avatarBg,
              backgroundImage: photoBytes != null ? MemoryImage(photoBytes) : null,
              child: photoBytes == null
                  ? const Icon(Icons.child_care, size: 40, color: Color(0xFF4F7A4A))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4F4A4A),
                    ),
                  ),
                  if (age.isNotEmpty)
                    Text(
                      age,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6E6A6A),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    appState.tr('tap_to_access'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF4F4A4A),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class IntroVideoPage extends StatefulWidget {
  const IntroVideoPage({super.key});

  @override
  State<IntroVideoPage> createState() => _IntroVideoPageState();
}

class _IntroVideoPageState extends State<IntroVideoPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/videos/video_intro_koa.mp4',
    )
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.play();
        }
      });

    _controller.addListener(_onVideoProgress);
  }

  void _onVideoProgress() {
    if (_hasNavigated) return;
    if (_controller.value.position >= _controller.value.duration &&
        _controller.value.isInitialized) {
      _hasNavigated = true;
      // Diferir navegación para evitar conflicto con frame rendering
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goNext();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoProgress);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    if (_hasNavigated && mounted) {
      // Marcar que ya vio el video intro
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_intro', true);
      debugPrint('✅ Video intro completado');
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const WelcomeScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          Center(
            child: _isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : const CircularProgressIndicator(color: Colors.white),
          ),
          Positioned(
            right: 16,
            top: 40,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black.withOpacity(0.4),
              ),
              onPressed: _goNext,
              child: const Text('Saltar'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BIOMETRIC LOGIN PAGE - Autenticación facial estilo BBVA
// ============================================================================
class BiometricLoginPage extends StatefulWidget {
  const BiometricLoginPage({super.key, required this.hasInfantProfile});

  final bool hasInfantProfile;

  @override
  State<BiometricLoginPage> createState() => _BiometricLoginPageState();
}

class _BiometricLoginPageState extends State<BiometricLoginPage>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _faceDetected = false;
  bool _isVerifying = false;
  bool _authSuccess = false;
  bool _authFailed = false;
  String _statusMessage = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _faceDetectedFrames = 0;
  static const int _requiredFrames = 15;
  bool _hasRegisteredFace = false;
  List<List<double>> _storedEmbeddings = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkAndInitialize();
  }

  Future<void> _checkAndInitialize() async {
    if (!widget.hasInfantProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const InfantRegistrationPage()),
          );
        }
      });
      return;
    }

    // Inicializar modelo MobileFaceNet
    try {
      await FaceEmbeddingService.instance.initialize();
    } catch (e) {
      debugPrint('⚠️ No se pudo cargar FaceEmbeddingService: $e');
    }

    // 1. Intentar cargar embeddings desde Supabase
    try {
      final biometrics = await AuthService.getUserFaceBiometrics();
      _storedEmbeddings = biometrics
          .where((b) => b['face_encoding']?['vector'] != null)
          .map((b) => List<double>.from(b['face_encoding']['vector'] as List))
          .toList();
      debugPrint('📊 Embeddings Supabase: ${_storedEmbeddings.length}');
    } catch (e) {
      debugPrint('⚠️ Supabase no disponible: $e');
    }

    // 2. Si Supabase vacío, cargar embedding guardado localmente (fuente principal)
    final prefs = await SharedPreferences.getInstance();
    if (_storedEmbeddings.isEmpty) {
      try {
        final localJson = prefs.getString('face_embedding_local');
        if (localJson != null) {
          final localVec = List<double>.from(jsonDecode(localJson) as List);
          _storedEmbeddings = [localVec];
          debugPrint('📱 Embedding local cargado (${localVec.length} dims)');
        }
      } catch (e) {
        debugPrint('⚠️ Error cargando embedding local: $e');
      }
    }

    // 3. Si aún no hay embeddings, decidir qué hacer
    if (_storedEmbeddings.isEmpty) {
      _hasRegisteredFace = prefs.getBool('has_biometric_setup') ?? false;
      if (_hasRegisteredFace) {
        // Registrado con código antiguo (sin embedding guardado) → forzar re-registro
        await prefs.remove('has_biometric_setup');
        debugPrint('🔄 Re-registro requerido: sin embedding almacenado');
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const FaceRegistrationPage()),
          );
        }
      });
      return;
    }

    _initializeCamera();
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
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableLandmarks: false,
          performanceMode: FaceDetectorMode.fast,
        ),
      );

      if (mounted) {
        setState(() => _isInitialized = true);
        _startFaceDetection();
      }
    } catch (e) {
      if (mounted) {
        _showError();
      }
    }
  }

  void _startFaceDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isProcessing || _isVerifying || _authSuccess) return;
      _isProcessing = true;

      try {
        final inputImage = _convertCameraImage(image);
        if (inputImage == null) {
          _isProcessing = false;
          return;
        }

        final faces = await _faceDetector!.processImage(inputImage);
        
        if (!mounted) return;

        if (faces.isNotEmpty) {
          _faceDetectedFrames++;
          setState(() {
            _faceDetected = true;
            if (_faceDetectedFrames < _requiredFrames) {
              _statusMessage = 'hold_still';
            }
          });

          if (_faceDetectedFrames >= _requiredFrames && !_isVerifying) {
            _isVerifying = true; // Guard síncrono para evitar llamadas múltiples
            _verifyFace();
          }
        } else {
          _faceDetectedFrames = 0;
          setState(() {
            _faceDetected = false;
            _statusMessage = 'position_face';
          });
        }
      } catch (e) {
        // Ignore processing errors
      }

      _isProcessing = false;
    });
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final List<int> allBytes = [];
      for (final Plane plane in image.planes) {
        allBytes.addAll(plane.bytes);
      }
      final bytes = Uint8List.fromList(allBytes);

      final imageRotation = InputImageRotationValue.fromRawValue(
        _cameraController!.description.sensorOrientation,
      );
      if (imageRotation == null) return null;

      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
      if (inputImageFormat == null) return null;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _verifyFace() async {
    // _isVerifying ya fue seteado síncronamente en el stream callback
    setState(() => _statusMessage = 'verifying');

    try {
      await _cameraController?.stopImageStream();
    } catch (_) {}

    // Dar tiempo al stream para cerrarse completamente antes de capturar
    await Future.delayed(const Duration(milliseconds: 350));

    try {
      // 1. Capturar foto
      final photo = await _cameraController!.takePicture();
      final imageBytes = await photo.readAsBytes();

      // 2. Intentar obtener bounding box de la foto (no fatal si falla)
      Rect? faceBounds;
      try {
        final inputForDetection = InputImage.fromFilePath(photo.path);
        final detectedFaces =
            await _faceDetector!.processImage(inputForDetection);
        if (detectedFaces.isNotEmpty) faceBounds = detectedFaces.first.boundingBox;
      } catch (_) {
        debugPrint('⚠️ Detección en foto falló, usando imagen completa');
      }

      // 3. Generar embedding FaceNet (completamente opcional)
      List<double>? embedding;
      try {
        embedding = await FaceEmbeddingService.instance
            .generateEmbedding(imageBytes, faceBounds);
      } catch (_) {}

      if (!mounted) return;

      bool authenticated = false;

      if (embedding != null && _storedEmbeddings.isNotEmpty) {
        // ✅ Comparación real: embedding vs embedding guardado
        double bestSimilarity = 0.0;
        const double kThreshold = 0.60;
        for (final stored in _storedEmbeddings) {
          final sim = FaceEmbeddingService.cosineSimilarity(embedding, stored);
          debugPrint('🔬 Similitud facial: ${(sim * 100).toStringAsFixed(1)}%');
          if (sim > bestSimilarity) bestSimilarity = sim;
          if (sim >= kThreshold) { authenticated = true; break; }
        }
        final pct = (bestSimilarity * 100).toStringAsFixed(1);
        debugPrint(authenticated ? '✅ Acceso concedido ($pct%)' : '❌ Acceso denegado ($pct%)');
      } else if (embedding == null && _storedEmbeddings.isNotEmpty) {
        // TFLite falló en este intento pero hay embedding guardado → pedir reintento
        throw Exception('No se pudo analizar el rostro, intenta de nuevo');
      } else {
        // Sin embeddings almacenados: TFLite nunca funcionó en este dispositivo
        // Modo fallback solo para este caso excepcional
        final prefs = await SharedPreferences.getInstance();
        authenticated = prefs.getBool('has_biometric_setup') ?? false;
        debugPrint('⚠️ Sin embedding guardado — fallback: $authenticated');
      }

      if (!mounted) return;

      if (authenticated) {
        setState(() {
          _authSuccess = true;
          _statusMessage = 'auth_success';
        });
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) _goNext();
      } else {
        throw Exception('Rostro no reconocido');
      }
    } catch (e) {
      debugPrint('Error en verificación biométrica: $e');
      if (!mounted) return;
      setState(() {
        _authFailed = true;
        _statusMessage = 'auth_failed';
      });
    }
  }


  void _showError() {
    setState(() {
      _authFailed = true;
      _statusMessage = 'camera_error';
    });
  }

  void _retry() {
    setState(() {
      _authFailed = false;
      _isVerifying = false;
      _faceDetectedFrames = 0;
      _statusMessage = 'position_face';
    });
    _startFaceDetection();
  }

  void _goNext() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => widget.hasInfantProfile
            ? const MainNavigationPage()
            : const InfantRegistrationPage(),
      ),
    );
  }

  void _skipAuth() {
    _goNext();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final size = MediaQuery.of(context).size;
    final ovalWidth = size.width * 0.65;
    final ovalHeight = ovalWidth * 1.3;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _cameraController != null)
            Positioned.fill(
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _cameraController!.value.previewSize!.height,
                      height: _cameraController!.value.previewSize!.width,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFB6D7A8)),
            ),

          // Overlay oscuro con óvalo transparente
          if (_isInitialized)
            CustomPaint(
              size: size,
              painter: FaceOverlayPainter(
                ovalWidth: ovalWidth,
                ovalHeight: ovalHeight,
                faceDetected: _faceDetected,
                isSuccess: _authSuccess,
                isFailed: _authFailed,
              ),
            ),

          // Animated oval border
          if (_isInitialized && !_authSuccess && !_authFailed)
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _faceDetected ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: ovalWidth,
                      height: ovalHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(ovalWidth / 2),
                        border: Border.all(
                          color: _faceDetected
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFB6D7A8),
                          width: 4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Success checkmark
          if (_authSuccess)
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),

          // Top bar with logo and title
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _skipAuth,
                      ),
                      const Spacer(),
                      // Logo + title centrado
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/koa_logo.png',
                            height: 44,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appState.tr('face_auth'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom status and buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status indicator
                  if (_isVerifying)
                    const CircularProgressIndicator(
                      color: Color(0xFFB6D7A8),
                      strokeWidth: 3,
                    ),
                  const SizedBox(height: 16),

                  // Status message
                  Text(
                    _statusMessage.isNotEmpty
                        ? appState.tr(_statusMessage)
                        : appState.tr('position_face'),
                    style: TextStyle(
                      color: _authSuccess
                          ? const Color(0xFF4CAF50)
                          : _authFailed
                              ? Colors.redAccent
                              : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Retry button if failed
                  if (_authFailed) ...[
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: Text(appState.tr('try_again')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB6D7A8),
                        foregroundColor: const Color(0xFF1A1A2E),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Skip button
                  if (!_authSuccess)
                    TextButton(
                      onPressed: _skipAuth,
                      child: Text(
                        appState.tr('skip_for_now'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
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

// ============================================================================
// FACE REGISTRATION PAGE - Página para registrar rostro del usuario
// ============================================================================
class FaceRegistrationPage extends StatefulWidget {
  const FaceRegistrationPage({super.key});

  @override
  State<FaceRegistrationPage> createState() => _FaceRegistrationPageState();
}

class _FaceRegistrationPageState extends State<FaceRegistrationPage> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isInitialized = false;
  bool _faceDetected = false;
  bool _isProcessing = false;
  bool _registrationSuccess = false;
  String _statusMessage = '';
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableLandmarks: false,
          performanceMode: FaceDetectorMode.fast,
        ),
      );

      if (mounted) {
        setState(() => _isInitialized = true);
        _startFaceDetection();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'error_camera');
      }
    }
  }

  void _startFaceDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    _cameraController!.startImageStream((image) async {
      if (_isProcessing || _registrationSuccess) return;
      _isProcessing = true;

      try {
        final inputImage = _convertCameraImage(image);
        if (inputImage != null) {
          final faces = await _faceDetector!.processImage(inputImage);
          if (mounted && !_registrationSuccess) {
            final detected = faces.isNotEmpty;
            setState(() {
              _faceDetected = detected;
              if (detected && _countdown == 0) {
                _startCountdown();
              } else if (!detected) {
                _cancelCountdown();
              }
            });
          }
        }
      } catch (_) {}

      _isProcessing = false;
    });
  }

  void _startCountdown() {
    if (_countdown > 0) return;
    _countdown = 3;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          timer.cancel();
          _captureAndSaveFace();
        }
      });
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    if (mounted) {
      setState(() => _countdown = 0);
    }
  }

  Future<void> _captureAndSaveFace() async {
    if (_cameraController == null || _registrationSuccess) return;

    try {
      await _cameraController!.stopImageStream();

      // 1. Capturar foto
      final photo = await _cameraController!.takePicture();
      final imageBytes = await photo.readAsBytes();

      // 2. Intentar obtener bounding box de la foto (no fatal si falla)
      //    La foto estática puede tener rotación diferente al stream.
      Rect? faceBounds;
      try {
        final inputForDetection = InputImage.fromFilePath(photo.path);
        final detected = await _faceDetector!.processImage(inputForDetection);
        if (detected.isNotEmpty) faceBounds = detected.first.boundingBox;
      } catch (_) {
        debugPrint('⚠️ Detección en foto falló, usando imagen completa');
      }

      // 3. Generar embedding FaceNet (completamente opcional)
      List<double>? embedding;
      try {
        await FaceEmbeddingService.instance.initialize();
        embedding = await FaceEmbeddingService.instance
            .generateEmbedding(imageBytes, faceBounds);
      } catch (e) {
        debugPrint('⚠️ FaceEmbeddingService no disponible: $e');
      }

      // 4. Guardar siempre el flag de registro
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_biometric_setup', true);

      // 5. Guardar embedding localmente (CRÍTICO para comparación real)
      if (embedding != null) {
        await prefs.setString('face_embedding_local', jsonEncode(embedding));
        debugPrint('✅ Embedding guardado localmente (${embedding.length} dims)');

        // También subir a Supabase para acceso cross-device (opcional)
        try {
          await AuthService.registerFaceBiometric(
            faceEncoding: {'vector': embedding},
          );
          debugPrint('✅ Embedding también guardado en Supabase');
        } catch (e) {
          debugPrint('⚠️ Supabase no disponible (no crítico): $e');
        }
      } else {
        // TFLite falló — la próxima apertura de la app forzará re-registro
        await prefs.remove('face_embedding_local');
        debugPrint('⚠️ TFLite no generó embedding, se pedirá re-registro');
      }

      if (mounted) {
        setState(() {
          _registrationSuccess = true;
          _statusMessage = 'face_registered';
        });

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNavigationPage()),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error al registrar embedding facial: $e');
      if (mounted) {
        setState(() => _statusMessage = 'error_capture');
        _startFaceDetection();
      }
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final List<int> allBytes = [];
      for (final Plane plane in image.planes) {
        allBytes.addAll(plane.bytes);
      }
      final bytes = Uint8List.fromList(allBytes);

      final imageRotation = InputImageRotationValue.fromRawValue(
        _cameraController!.description.sensorOrientation,
      );
      if (imageRotation == null) return null;

      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
      if (inputImageFormat == null) return null;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  void _skipRegistration() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationPage()),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final size = MediaQuery.of(context).size;
    final ovalWidth = size.width * 0.65;
    final ovalHeight = ovalWidth * 1.35;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_isInitialized && _cameraController != null)
            ClipRect(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: size.width,
                    height: size.width * _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFB6D7A8)),
            ),

          // Face overlay
          CustomPaint(
            size: Size.infinite,
            painter: FaceOverlayPainter(
              ovalWidth: ovalWidth,
              ovalHeight: ovalHeight,
              faceDetected: _faceDetected,
              isSuccess: _registrationSuccess,
              isFailed: false,
            ),
          ),

          // Oval border
          Center(
            child: Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                width: ovalWidth,
                height: ovalHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(ovalWidth / 2, ovalHeight / 2),
                  ),
                  border: Border.all(
                    color: _registrationSuccess
                        ? const Color(0xFF4CAF50)
                        : _faceDetected
                            ? const Color(0xFFB6D7A8)
                            : Colors.white54,
                    width: _registrationSuccess ? 4 : 3,
                  ),
                ),
              ),
            ),
          ),

          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KOA',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB6D7A8),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appState.tr('register_face_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appState.tr('register_face_subtitle'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Countdown indicator
          if (_countdown > 0)
            Center(
              child: Transform.translate(
                offset: const Offset(0, -40),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB6D7A8).withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$_countdown',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success indicator
                  if (_registrationSuccess)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 64,
                    ),

                  const SizedBox(height: 16),

                  // Status message
                  Text(
                    _registrationSuccess
                        ? appState.tr('face_registered')
                        : _faceDetected
                            ? (_countdown > 0
                                ? appState.tr('hold_still')
                                : appState.tr('face_detected'))
                            : appState.tr('position_face_register'),
                    style: TextStyle(
                      color: _registrationSuccess
                          ? const Color(0xFF4CAF50)
                          : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Skip button
                  if (!_registrationSuccess)
                    TextButton(
                      onPressed: _skipRegistration,
                      child: Text(
                        appState.tr('skip_for_now'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
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

// Painter para el óvalo facial
class FaceOverlayPainter extends CustomPainter {
  final double ovalWidth;
  final double ovalHeight;
  final bool faceDetected;
  final bool isSuccess;
  final bool isFailed;

  FaceOverlayPainter({
    required this.ovalWidth,
    required this.ovalHeight,
    required this.faceDetected,
    required this.isSuccess,
    required this.isFailed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xDD1A1A2E);

    final center = Offset(size.width / 2, size.height / 2 - 40);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // Dibuja el fondo oscuro
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) {
    return oldDelegate.faceDetected != faceDetected ||
        oldDelegate.isSuccess != isSuccess ||
        oldDelegate.isFailed != isFailed;
  }
}

// ============================================================================
// MAIN NAVIGATION PAGE - Navegación principal con tabs
// ============================================================================
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  bool _isPremium = false;

  final List<Widget> _pages = const [
    HomeContent(),
    RegistroPage(),
    StatsPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadPremiumState();
  }

  Future<void> _loadPremiumState() async {
    final premium = await SubscriptionService.isPremium();
    if (mounted) setState(() => _isPremium = premium);
  }

  Future<void> _openPaywall() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PremiumPaywallPage()),
    );
    if (result == true) _loadPremiumState();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252540) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home, appState.tr('home')),
            _buildNavItem(1, Icons.list_alt, appState.tr('registry')),
            _buildNavItem(2, Icons.bar_chart, appState.tr('stats')),
            _buildNavItem(3, Icons.settings, appState.tr('settings')),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? const Color(0xFFB6D7A8) : const Color(0xFF4F7A4A);
    final inactiveColor = isDark ? Colors.grey[500] : const Color(0xFFB0B0B0);
    final bool isLockedTab = (index == 1 || index == 2) && !_isPremium;

    return InkWell(
      onTap: () {
        if (isLockedTab) {
          _openPaywall();
        } else {
          setState(() => _currentIndex = index);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: isActive ? activeColor : inactiveColor, size: 24),
                if (isLockedTab)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Icon(
                      Icons.lock_rounded,
                      size: 12,
                      color: Colors.orange[700],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HOME CONTENT - Contenido de la página de inicio
// ============================================================================
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadPremiumState();
  }

  Future<void> _loadPremiumState() async {
    final premium = await SubscriptionService.isPremium();
    if (mounted) setState(() => _isPremium = premium);
  }

  Future<void> _openPaywall() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PremiumPaywallPage()),
    );
    if (result == true) _loadPremiumState();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          const InfantProfileHeader(),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5FFF3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    // Tip del koala
                    KoalaTipWidget(
                      section: 'home',
                      languageCode: appState.locale.languageCode,
                    ),
                    // Cuidadores — funcionalidad Premium
                    if (_isPremium)
                      const CaregiversSection()
                    else
                      InkWell(
                        onTap: _openPaywall,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF252540)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 12),
                              Text(
                                appState.tr('caregivers'),
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F7A4A)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_rounded,
                                        size: 14,
                                        color: Color(0xFF4F7A4A)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Premium',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF4F7A4A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      appState.tr('main_sections'),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 22,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        KoaFeatureCard(
                          icon: Icons.restaurant,
                          title: appState.tr('food'),
                          description: appState.tr('food_desc'),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const FoodPage()),
                            );
                          },
                        ),
                        KoaFeatureCard(
                          icon: Icons.videocam,
                          title: appState.tr('camera'),
                          description: appState.tr('camera_desc'),
                          isLocked: !_isPremium,
                          onTap: _isPremium
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CameraMonitorPage()),
                                  )
                              : _openPaywall,
                        ),
                        KoaFeatureCard(
                          icon: Icons.favorite,
                          title: appState.tr('health'),
                          description: appState.tr('health_desc'),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const HealthPage()),
                            );
                          },
                        ),
                        KoaFeatureCard(
                          icon: Icons.book,
                          title: appState.tr('diary'),
                          description: appState.tr('diary_desc'),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MemoriesDiaryPage(),
                              ),
                            );
                          },
                        ),
                        KoaFeatureCard(
                          icon: Icons.bedtime,
                          title: appState.tr('sleep'),
                          description: appState.tr('sleep_desc'),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const SleepPage()),
                            );
                          },
                        ),
                        KoaFeatureCard(
                          icon: Icons.phone,
                          title: 'Llamar al Pediatra',
                          description:
                              'Contacta al medico de tu bebe directamente.',
                          isLocked: !_isPremium,
                          onTap: _isPremium
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const HealthPage(initialTab: 4),
                                    ),
                                  )
                              : _openPaywall,
                        ),
                      ],
                    ),
                  ],
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
// REGISTRO PAGE - Registro unificado de actividades
// ============================================================================
class _ActivityItem {
  final String type;
  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final Color color;

  _ActivityItem({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.color,
  });
}

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  List<_ActivityItem> _activities = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  final List<Map<String, dynamic>> _filters = [
    {'key': 'all', 'label': 'Todos', 'icon': Icons.list_alt},
    {'key': 'food', 'label': 'Comida', 'icon': Icons.restaurant},
    {'key': 'sleep', 'label': 'Sueño', 'icon': Icons.bedtime},
    {'key': 'health', 'label': 'Salud', 'icon': Icons.monitor_weight},
    {'key': 'vaccine', 'label': 'Vacunas', 'icon': Icons.vaccines},
    {'key': 'appointment', 'label': 'Citas', 'icon': Icons.local_hospital},
  ];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    final List<_ActivityItem> items = [];

    try {
      final feedings = await StorageService.loadFeedingEntries();
      for (final f in feedings) {
        final typeLabel = f.type == 'breast'
            ? 'Lactancia'
            : f.type == 'bottle'
                ? 'Biberón'
                : 'Sólidos';
        items.add(_ActivityItem(
          type: 'food',
          icon: Icons.restaurant,
          title: 'Alimentación · $typeLabel',
          subtitle:
              '${f.amount.toStringAsFixed(0)} ml${f.notes != null && f.notes!.isNotEmpty ? ' · ${f.notes}' : ''}',
          timestamp: f.time,
          color: const Color(0xFFFF9800),
        ));
      }
    } catch (_) {}

    try {
      final sleeps = await StorageService.loadSleepSessions();
      for (final s in sleeps) {
        items.add(_ActivityItem(
          type: 'sleep',
          icon: Icons.bedtime,
          title: s.isOngoing ? 'Sueño en curso' : 'Sesión de sueño',
          subtitle: s.isOngoing ? 'En curso...' : 'Duración: ${s.durationFormatted}',
          timestamp: s.startTime,
          color: const Color(0xFF3F51B5),
        ));
      }
    } catch (_) {}

    try {
      final measurements = await StorageService.loadHealthMeasurements();
      for (final m in measurements) {
        items.add(_ActivityItem(
          type: 'health',
          icon: Icons.monitor_weight,
          title: 'Medición de salud',
          subtitle: '${m.weight} kg · ${m.height} cm',
          timestamp: m.date,
          color: const Color(0xFFE91E63),
        ));
      }
    } catch (_) {}

    try {
      final vaccines = await StorageService.loadVaccines();
      for (final v in vaccines) {
        if (v.isApplied && v.appliedDate != null) {
          items.add(_ActivityItem(
            type: 'vaccine',
            icon: Icons.vaccines,
            title: 'Vacuna aplicada',
            subtitle: v.name,
            timestamp: v.appliedDate!,
            color: const Color(0xFF4CAF50),
          ));
        }
      }
    } catch (_) {}

    try {
      final appointments = await StorageService.loadAppointments();
      for (final a in appointments) {
        items.add(_ActivityItem(
          type: 'appointment',
          icon: Icons.local_hospital,
          title: a.type,
          subtitle:
              '${a.completed ? '✓ Completada' : 'Pendiente'}${a.notes != null && a.notes!.isNotEmpty ? ' · ${a.notes}' : ''}',
          timestamp:
              DateTime(a.date.year, a.date.month, a.date.day, a.time.hour, a.time.minute),
          color: const Color(0xFF9C27B0),
        ));
      }
    } catch (_) {}

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (mounted) {
      setState(() {
        _activities = items;
        _isLoading = false;
      });
    }
  }

  List<_ActivityItem> get _filtered {
    if (_selectedFilter == 'all') return _activities;
    return _activities.where((a) => a.type == _selectedFilter).toList();
  }

  String _formatDateHeader(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) return 'Hoy';
    if (date == yesterday) return 'Ayer';
    return DateFormat("d 'de' MMMM yyyy", 'es').format(dt);
  }

  List<Widget> _buildGroupedList(List<_ActivityItem> items, bool isDark, AppState appState) {
    if (items.isEmpty) {
      return [
        const SizedBox(height: 48),
        Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                appState.tr('no_activities'),
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ];
    }

    final widgets = <Widget>[];
    String? lastDateHeader;

    for (final item in items) {
      final header = _formatDateHeader(item.timestamp);
      if (header != lastDateHeader) {
        lastDateHeader = header;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              header,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white54 : const Color(0xFF6E8F6A),
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }
      widgets.add(_buildActivityTile(item, isDark));
    }
    return widgets;
  }

  Widget _buildActivityTile(_ActivityItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, color: item.color, size: 22),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF333333),
          ),
        ),
        subtitle: Text(
          item.subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white54 : Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          DateFormat('HH:mm').format(item.timestamp),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white38 : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;

    return SafeArea(
      child: Column(
        children: [
          const InfantProfileHeader(),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5FFF3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                    child: Row(
                      children: [
                        Text(
                          appState.tr('activity_log'),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
                        ),
                        const Spacer(),
                        if (_activities.isNotEmpty)
                          Text(
                            '${filtered.length} registros',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white38 : Colors.grey[500],
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: _loadActivities,
                          color: isDark ? const Color(0xFFB6D7A8) : const Color(0xFF4F7A4A),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      children: _filters.map((f) {
                        final selected = _selectedFilter == f['key'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: Icon(
                              f['icon'] as IconData,
                              size: 14,
                              color: selected ? Colors.white : (isDark ? Colors.white54 : Colors.grey[700]),
                            ),
                            label: Text(f['label'] as String),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedFilter = f['key'] as String),
                            selectedColor: const Color(0xFF4F7A4A),
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(fontSize: 12, color: selected ? Colors.white : null),
                            backgroundColor: isDark ? const Color(0xFF252540) : null,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFB6D7A8)))
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            children: _buildGroupedList(filtered, isDark, appState),
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

// ============================================================================
// STATS PAGE - Página de estadísticas
// ============================================================================
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<HealthMeasurement> _measurements = [];
  String _gender = 'masculino'; // Por defecto

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final measurements = await StorageService.loadHealthMeasurements();
    final prefs = await SharedPreferences.getInstance();
    final gender = prefs.getString('infant_gender') ?? 'masculino';
    
    debugPrint('ℹ️ Mediciones cargadas: ${measurements.length}');
    for (var m in measurements) {
      debugPrint('  - ${m.date}: ${m.weight}kg, ${m.height}cm, ${m.ageInMonths}m');
    }
    debugPrint('ℹ️ Género: $gender');
    
    setState(() {
      _measurements = measurements;
      _gender = gender;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          const InfantProfileHeader(),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5FFF3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Estadísticas',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 22,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF4F7A4A),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF4F7A4A),
                    tabs: const [
                      Tab(text: 'Resumen'),
                      Tab(text: 'Crecimiento'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSummaryTab(isDark),
                        _buildGrowthTab(),
                      ],
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

  Widget _buildSummaryTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Próximamente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Aquí podrás ver estadísticas generales',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthTab() {
    if (_measurements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay datos de crecimiento',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega mediciones en la sección Salud',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Botón exportar PDF
          ElevatedButton.icon(
            onPressed: _exportGrowthPDF,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar informe PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F7A4A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          _buildWeightChart(),
          const SizedBox(height: 24),
          _buildHeightChart(),
          const SizedBox(height: 24),
          
          // Tabla de mediciones
          _buildMeasurementsTable(),
        ],
      ),
    );
  }

  Widget _buildWeightChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Peso vs Edad',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4F7A4A),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(
              _buildWeightChartData(),
            ),
          ),
          const SizedBox(height: 12),
          _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildHeightChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Talla vs Edad',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4F7A4A),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(
              _buildHeightChartData(),
            ),
          ),
          const SizedBox(height: 12),
          _buildChartLegend(),
        ],
      ),
    );
  }

  LineChartData _buildWeightChartData() {
    // Datos del bebé
    final babySpots = _measurements
        .map((m) => FlSpot(m.ageInMonths.toDouble(), m.weight))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    // Curvas OMS
    final whoData = _gender == 'femenino' ? whoWeightFemale : whoWeightMale;
    final p3Spots = <FlSpot>[];
    final p50Spots = <FlSpot>[];
    final p97Spots = <FlSpot>[];

    for (final entry in whoData.entries) {
      final month = entry.key;
      final values = entry.value;
      p3Spots.add(FlSpot(month.toDouble(), values['p3']!));
      p50Spots.add(FlSpot(month.toDouble(), values['p50']!));
      p97Spots.add(FlSpot(month.toDouble(), values['p97']!));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 2,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey[300]!,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text(
              '${value.toInt()} kg',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 6,
            getTitlesWidget: (value, meta) => Text(
              '${value.toInt()}m',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        // Curva P3 (rojo claro)
        LineChartBarData(
          spots: p3Spots,
          isCurved: true,
          color: Colors.red[300],
          barWidth: 2,
          dotData: const FlDotData(show: false),
          dashArray: [5, 5],
        ),
        // Curva P50 (verde)
        LineChartBarData(
          spots: p50Spots,
          isCurved: true,
          color: Colors.green[400],
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
        // Curva P97 (rojo claro)
        LineChartBarData(
          spots: p97Spots,
          isCurved: true,
          color: Colors.red[300],
          barWidth: 2,
          dotData: const FlDotData(show: false),
          dashArray: [5, 5],
        ),
        // Datos del bebé (azul)
        LineChartBarData(
          spots: babySpots,
          isCurved: true,
          color: Colors.blue[700],
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.blue[700]!,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
      ],
    );
  }

  LineChartData _buildHeightChartData() {
    // Datos del bebé
    final babySpots = _measurements
        .map((m) => FlSpot(m.ageInMonths.toDouble(), m.height))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    // Curvas OMS
    final whoData = _gender == 'femenino' ? whoHeightFemale : whoHeightMale;
    final p3Spots = <FlSpot>[];
    final p50Spots = <FlSpot>[];
    final p97Spots = <FlSpot>[];

    for (final entry in whoData.entries) {
      final month = entry.key;
      final values = entry.value;
      p3Spots.add(FlSpot(month.toDouble(), values['p3']!));
      p50Spots.add(FlSpot(month.toDouble(), values['p50']!));
      p97Spots.add(FlSpot(month.toDouble(), values['p97']!));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 5,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey[300]!,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text(
              '${value.toInt()} cm',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 6,
            getTitlesWidget: (value, meta) => Text(
              '${value.toInt()}m',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        // Curva P3
        LineChartBarData(
          spots: p3Spots,
          isCurved: true,
          color: Colors.red[300],
          barWidth: 2,
          dotData: const FlDotData(show: false),
          dashArray: [5, 5],
        ),
        // Curva P50
        LineChartBarData(
          spots: p50Spots,
          isCurved: true,
          color: Colors.green[400],
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
        // Curva P97
        LineChartBarData(
          spots: p97Spots,
          isCurved: true,
          color: Colors.red[300],
          barWidth: 2,
          dotData: const FlDotData(show: false),
          dashArray: [5, 5],
        ),
        // Datos del bebé
        LineChartBarData(
          spots: babySpots,
          isCurved: true,
          color: Colors.blue[700],
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.blue[700]!,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(color: Colors.blue[700]!, label: 'Tu bebé'),
        _LegendItem(color: Colors.green[400]!, label: 'P50 (OMS)'),
        _LegendItem(color: Colors.red[300]!, label: 'P3/P97 (OMS)', dashed: true),
      ],
    );
  }

  Widget _buildMeasurementsTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historial de mediciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4F7A4A),
            ),
          ),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(color: Colors.grey[300]!, width: 1),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: const Color(0xFF4F7A4A).withOpacity(0.1)),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Fecha', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Edad', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Peso', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Talla', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              ..._measurements.map((m) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('${m.date.day}/${m.date.month}/${m.date.year}'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('${m.ageInMonths}m'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('${m.weight.toStringAsFixed(1)} kg'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('${m.height.toStringAsFixed(1)} cm'),
                  ),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportGrowthPDF() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando PDF...')),
      );

      // Obtener datos del perfil
      final prefs = await SharedPreferences.getInstance();
      final babyName = prefs.getString('infant_name') ?? 'Mi bebé';

      // Crear el documento PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Título
            pw.Header(
              level: 0,
              child: pw.Text(
                'Informe de Crecimiento',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Bebé: $babyName',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 24),

            // Tabla de mediciones
            pw.Text(
              'Historial de mediciones',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Fecha', 'Edad (meses)', 'Peso (kg)', 'Talla (cm)'],
              data: _measurements.map((m) => [
                '${m.date.day}/${m.date.month}/${m.date.year}',
                m.ageInMonths.toString(),
                m.weight.toStringAsFixed(1),
                m.height.toStringAsFixed(1),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.center,
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Nota: Este informe incluye las mediciones registradas comparadas con los estándares de la OMS.',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      );

      // Guardar el PDF
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/informe_crecimiento_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());

      // Compartir el PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Informe de crecimiento - $babyName',
      );

      debugPrint('✅ PDF generado: ${file.path}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡PDF generado y compartido!')),
        );
      }
    } catch (e) {
      debugPrint('❌ Error al generar PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendItem({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: dashed ? null : color,
            border: dashed ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

// ============================================================================
// SETTINGS PAGE - Página de ajustes
// ============================================================================
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadPremiumState();
  }

  Future<void> _loadPremiumState() async {
    final premium = await SubscriptionService.isPremium();
    if (mounted) setState(() => _isPremium = premium);
  }

  Future<void> _logout(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appState.tr('logout')),
        content: Text(appState.tr('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(appState.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(appState.tr('confirm')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Cerrar sesión de Supabase
      await Supabase.instance.client.auth.signOut();
      debugPrint('✅ Sesión cerrada en Supabase');
      
      // Navegar a WelcomeScreen para permitir otro usuario iniciar sesión
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const WelcomeScreen(),
          ),
          (route) => false,
        );
      }
    }
  }

  Future<void> _switchAccount(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appState.tr('switch_account')),
        content: Text(appState.tr('switch_account_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(appState.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F7A4A),
              foregroundColor: Colors.white,
            ),
            child: Text(appState.tr('confirm')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final confirmWord = appState.locale.languageCode == 'es' ? 'ELIMINAR' : 'DELETE';
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[800], size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                appState.tr('delete_account_title'),
                style: TextStyle(color: Colors.red[800]),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              appState.tr('delete_account_warning'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: confirmWord,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.red[800]!),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(appState.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim() == confirmWord) {
                Navigator.of(ctx).pop(true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(appState.tr('delete_account_wrong_word')),
                    backgroundColor: Colors.red[800],
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
              foregroundColor: Colors.white,
            ),
            child: Text(appState.tr('delete_account')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await AuthService.deleteAccount();

        if (context.mounted) {
          Navigator.of(context).pop(); // Cerrar loading
          // Limpiar preferencias locales
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(appState.tr('delete_account_success')),
                backgroundColor: const Color(0xFF4F7A4A),
              ),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Cerrar loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(appState.tr('delete_account_error')),
              backgroundColor: Colors.red[800],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          const InfantProfileHeader(),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5FFF3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      appState.tr('settings'),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 22,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Sección Apariencia
                    _SectionTitle(title: appState.tr('appearance')),
                    const SizedBox(height: 8),
                    _SettingsTile(
                      icon: Icons.dark_mode,
                      title: appState.tr('dark_mode'),
                      trailing: Switch(
                        value: appState.isDarkMode,
                        onChanged: (_) => appState.toggleDarkMode(),
                        activeColor: const Color(0xFF4F7A4A),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sección Idioma
                    _SectionTitle(title: appState.tr('language')),
                    const SizedBox(height: 8),
                    _SettingsTile(
                      icon: Icons.language,
                      title: appState.tr('spanish'),
                      trailing: Radio<String>(
                        value: 'es',
                        groupValue: appState.locale.languageCode,
                        onChanged: (_) => appState.setLocale(const Locale('es')),
                        activeColor: const Color(0xFF4F7A4A),
                      ),
                      onTap: () => appState.setLocale(const Locale('es')),
                    ),
                    _SettingsTile(
                      icon: Icons.language,
                      title: appState.tr('english'),
                      trailing: Radio<String>(
                        value: 'en',
                        groupValue: appState.locale.languageCode,
                        onChanged: (_) => appState.setLocale(const Locale('en')),
                        activeColor: const Color(0xFF4F7A4A),
                      ),
                      onTap: () => appState.setLocale(const Locale('en')),
                    ),

                    const SizedBox(height: 24),

                    // Sección Mi Plan
                    const _SectionTitle(title: 'Mi Plan'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF252540)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isPremium
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: _isPremium
                                    ? const Color(0xFF4F7A4A)
                                    : Colors.grey,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isPremium ? 'Plan Premium' : 'Plan Gratuito',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _isPremium
                                      ? const Color(0xFF4F7A4A)
                                      : (isDark
                                          ? Colors.white
                                          : const Color(0xFF4F4A4A)),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _isPremium
                                      ? const Color(0xFF4F7A4A)
                                          .withOpacity(0.15)
                                      : Colors.grey.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _isPremium ? 'Activo' : 'Gratis',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _isPremium
                                        ? const Color(0xFF4F7A4A)
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!_isPremium) ...[                            
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result =
                                      await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PremiumPaywallPage(),
                                    ),
                                  );
                                  if (result == true) _loadPremiumState();
                                },
                                icon: const Icon(Icons.star_rounded, size: 18),
                                label: const Text('Mejorar a Premium'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F7A4A),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (_isPremium) ...[                            
                            const SizedBox(height: 8),
                            Text(
                              'Tienes acceso completo a todas las funciones de KOA.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sección Cuenta
                    _SectionTitle(title: appState.tr('account')),
                    const SizedBox(height: 8),
                    _SettingsTile(
                      icon: Icons.swap_horiz,
                      title: appState.tr('switch_account'),
                      onTap: () => _switchAccount(context),
                    ),
                    _SettingsTile(
                      icon: Icons.logout,
                      title: appState.tr('logout'),
                      iconColor: Colors.redAccent,
                      titleColor: Colors.redAccent,
                      onTap: () => _logout(context),
                    ),
                    const SizedBox(height: 8),
                    _SettingsTile(
                      icon: Icons.delete_forever,
                      title: appState.tr('delete_account'),
                      iconColor: Colors.red[800],
                      titleColor: Colors.red[800],
                      onTap: () => _deleteAccount(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultIconColor = isDark ? const Color(0xFFB6D7A8) : const Color(0xFF4F7A4A);
    final defaultTitleColor = isDark ? Colors.white : const Color(0xFF4F4A4A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252540) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? defaultIconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: titleColor ?? defaultTitleColor,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// Mantener compatibilidad con el nombre anterior
class KoaHomePage extends StatelessWidget {
  const KoaHomePage({super.key});
  @override
  Widget build(BuildContext context) => const MainNavigationPage();
}

class InfantProfileHeader extends StatefulWidget {
  const InfantProfileHeader({super.key});

  @override
  State<InfantProfileHeader> createState() => _InfantProfileHeaderState();
}

class _InfantProfileHeaderState extends State<InfantProfileHeader> {
  Map<String, dynamic>? _data;
  final ImagePicker _picker = ImagePicker();
  int _lastRefreshKey = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);
    if (_lastRefreshKey != appState.profileRefreshKey) {
      _lastRefreshKey = appState.profileRefreshKey;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('infant_name') ?? 'Tu bebé';
    final secondName = prefs.getString('infant2_name');
    final thirdName = prefs.getString('infant3_name');
    final birthIso = prefs.getString('infant_birthdate');
    final photoBase64 = prefs.getString('infant_photo');
    final gender = prefs.getString('infant_gender') ?? 'otro';

    Uint8List? photoBytes;
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      try {
        photoBytes = base64Decode(photoBase64);
      } catch (_) {}
    }

    String displayName = name;
    if (secondName != null && secondName.isNotEmpty && thirdName != null && thirdName.isNotEmpty) {
      displayName = '$name, $secondName y $thirdName';
    } else if (secondName != null && secondName.isNotEmpty) {
      displayName = '$name y $secondName';
    }

    String ageText = '';
    if (birthIso != null) {
      try {
        final birthDate = DateTime.parse(birthIso);
        final now = DateTime.now();
        final diff = now.difference(birthDate);
        final totalMonths = diff.inDays ~/ 30;
        final years = totalMonths ~/ 12;
        final months = totalMonths % 12;
        final days = diff.inDays % 30;
        
        // Obtener traducciones
        final appState = Provider.of<AppState>(context, listen: false);
        
        if (years >= 1) {
          // Mostrar en años
          final yearText = years == 1 ? appState.tr('year') : appState.tr('years');
          if (months > 0) {
            final monthText = months == 1 ? appState.tr('month') : appState.tr('months');
            ageText = '$years $yearText ${appState.tr('and')} $months $monthText ${appState.tr('old')}';
          } else {
            ageText = '$years $yearText ${appState.tr('old')}';
          }
        } else {
          // Mostrar en meses
          final monthText = totalMonths == 1 ? appState.tr('month') : appState.tr('months');
          final dayText = days == 1 ? appState.tr('day') : appState.tr('days');
          if (days > 0) {
            ageText = '$totalMonths $monthText ${appState.tr('and')} $days $dayText ${appState.tr('old')}';
          } else {
            ageText = '$totalMonths $monthText ${appState.tr('old')}';
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _data = {
          'name': displayName,
          'rawName': name,
          'age': ageText,
          'gender': gender,
          'photo': photoBytes,
          'birthIso': birthIso,
        };
      });
    }
  }

  void _showProfileMenu(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              appState.tr('profile_options'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4F4A4A),
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuOption(
              icon: Icons.photo_camera,
              label: appState.tr('change_photo'),
              onTap: () {
                Navigator.pop(ctx);
                _changePhoto();
              },
            ),
            _buildMenuOption(
              icon: Icons.edit,
              label: appState.tr('edit_name'),
              onTap: () {
                Navigator.pop(ctx);
                _editName(appState);
              },
            ),
            _buildMenuOption(
              icon: Icons.cake,
              label: appState.tr('edit_birthdate'),
              onTap: () {
                Navigator.pop(ctx);
                _editBirthdate();
              },
            ),
            _buildMenuOption(
              icon: Icons.wc,
              label: appState.tr('edit_gender'),
              onTap: () {
                Navigator.pop(ctx);
                _editGender(appState);
              },
            ),
            const Divider(height: 24),
            _buildMenuOption(
              icon: Icons.delete_outline,
              label: appState.tr('delete_profile'),
              color: Colors.red,
              onTap: () {
                Navigator.pop(ctx);
                _deleteProfile(appState);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF4F7A4A)),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          color: color ?? const Color(0xFF4F4A4A),
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _changePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('infant_photo', base64Encode(bytes));
      _loadData();
      if (mounted) {
        Provider.of<AppState>(context, listen: false).refreshProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada')),
        );
      }
    } catch (_) {}
  }

  Future<void> _editName(AppState appState) async {
    final controller = TextEditingController(text: _data?['rawName'] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appState.tr('edit_name')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: appState.tr('enter_name'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(appState.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB6D7A8),
            ),
            child: Text(appState.tr('save')),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('infant_name', result.trim());
      _loadData();
      appState.refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appState.tr('changes_saved'))),
        );
      }
    }
  }

  Future<void> _editBirthdate() async {
    final currentBirth = _data?['birthIso'] != null
        ? DateTime.tryParse(_data!['birthIso'])
        : null;
    final now = DateTime.now();
    
    final picked = await showDatePicker(
      context: context,
      initialDate: currentBirth ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      locale: const Locale('es'),
    );

    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('infant_birthdate', picked.toIso8601String());
      _loadData();
      if (mounted) {
        Provider.of<AppState>(context, listen: false).refreshProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fecha actualizada')),
        );
      }
    }
  }

  Future<void> _editGender(AppState appState) async {
    final current = _data?['gender'] ?? 'otro';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(appState.tr('edit_gender')),
        children: [
          RadioListTile<String>(
            title: const Text('Masculino'),
            value: 'masculino',
            groupValue: current,
            onChanged: (v) => Navigator.pop(ctx, v),
          ),
          RadioListTile<String>(
            title: const Text('Femenino'),
            value: 'femenino',
            groupValue: current,
            onChanged: (v) => Navigator.pop(ctx, v),
          ),
          RadioListTile<String>(
            title: const Text('Otro'),
            value: 'otro',
            groupValue: current,
            onChanged: (v) => Navigator.pop(ctx, v),
          ),
        ],
      ),
    );

    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('infant_gender', result);
      _loadData();
      appState.refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appState.tr('changes_saved'))),
        );
      }
    }
  }

  Future<void> _deleteProfile(AppState appState) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appState.tr('delete_profile')),
        content: Text(appState.tr('delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(appState.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(appState.tr('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('has_infant_profile');
      await prefs.remove('infant_name');
      await prefs.remove('infant2_name');
      await prefs.remove('infant3_name');
      await prefs.remove('infant_gender');
      await prefs.remove('infant_birthdate');
      await prefs.remove('infant_photo');
      await prefs.remove('user_face_photo');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ProfileSelectionPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Color(0xFFE8F7E4),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFB6D7A8)),
        ),
      );
    }

    final name = _data!['name'] as String;
    final age = _data!['age'] as String;
    final gender = _data!['gender'] as String;
    final photoBytes = _data!['photo'] as Uint8List?;

    Color headerColor;
    Color avatarBg;
    switch (gender.toLowerCase()) {
      case 'masculino':
        headerColor = const Color(0xFFB3D9FF);
        avatarBg = const Color(0xFFE0F0FF);
        break;
      case 'femenino':
        headerColor = const Color(0xFFF7C7C7);
        avatarBg = const Color(0xFFFDEFEF);
        break;
      default:
        headerColor = const Color(0xFFFFF3B0);
        avatarBg = const Color(0xFFFFFDE7);
    }

    return Container(
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: avatarBg,
            backgroundImage: photoBytes != null ? MemoryImage(photoBytes) : null,
            child: photoBytes == null
                ? const Icon(Icons.child_care, color: Color(0xFF4F7A4A), size: 32)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F4A4A),
                  ),
                ),
                if (age.isNotEmpty)
                  Text(
                    age,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6E6A6A),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF4F4A4A)),
            onPressed: () => _showProfileMenu(context),
          ),
        ],
      ),
    );
  }
}

class _BottomNavIcon extends StatelessWidget {
  const _BottomNavIcon({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF4F7A4A) : const Color(0xFFB0B0B0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
          ),
        ),
      ],
    );
  }
}

class KoaFeatureCard extends StatelessWidget {
  const KoaFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.isLocked = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isLocked;

  // Colores pastel adorables para cada tarjeta
  static final List<Map<String, Color>> _cuteColors = [
    {
      'bg': const Color(0xFFFFF8E7),       // Amarillo pastel
      'border': const Color(0xFFFFD54F),   // Amarillo brillante
      'icon': const Color(0xFFFFA726),     // Naranja cálido
    },
    {
      'bg': const Color(0xFFE8F5E9),       // Verde menta
      'border': const Color(0xFF81C784),   // Verde suave
      'icon': const Color(0xFF4CAF50),     // Verde brillante
    },
    {
      'bg': const Color(0xFFF3E5F5),       // Lavanda pastel
      'border': const Color(0xFFBA68C8),   // Púrpura suave
      'icon': const Color(0xFF9C27B0),     // Púrpura vibrante
    },
    {
      'bg': const Color(0xFFFFE0E6),       // Rosa pastel
      'border': const Color(0xFFFF80AB),   // Rosa brillante
      'icon': const Color(0xFFFF4081),     // Rosa fucsia
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Rotar colores según el título para que cada tarjeta tenga un color diferente
    final colorIndex = title.hashCode % _cuteColors.length;
    final colors = _cuteColors[colorIndex];

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 24 * 2 - 16) / 2,
      height: 200,
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A40) : colors['bg'],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFFB6D7A8) : colors['border']!,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? colors['border']! : colors['border']!)
                          .withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(isDark ? 0.05 : 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícono grande en un círculo adorable
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFFB6D7A8).withOpacity(0.2)
                            : Colors.white.withOpacity(0.9),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFB6D7A8)
                              : colors['icon']!,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark
                                    ? const Color(0xFFB6D7A8)
                                    : colors['icon']!)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 30,
                        color: isDark
                            ? const Color(0xFFB6D7A8)
                            : colors['icon'],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Título con fuente más grande y bold
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFFB6D7A8)
                            : const Color(0xFF4F4A4A),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Descripción más sutil
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: isDark
                            ? Colors.white.withOpacity(0.7)
                            : const Color(0xFF6E6A6A),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Lock overlay for Premium features
          if (isLocked)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    color: Colors.black.withOpacity(0.55),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_rounded,
                            color: Colors.white, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

// Enumeración de etapas de alimentación
enum FeedingStage {
  exclusiveLactation, // 0-6 meses
  complementary,      // 6-12 meses
  transition,         // 12-24 meses
  familyFood,         // 24+ meses
}

class FoodPage extends StatefulWidget {
  const FoodPage({super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _feedingType;
  final List<FeedingEntry> _entries = [];
  int _intervalHours = 3;

  // Recordatorio manual
  TimeOfDay _reminderTime = TimeOfDay.now();
  String? _scheduledReminderLabel; // texto de confirmación visible al usuario
  
  // Datos del bebé
  int _babyAgeInMonths = 0;
  String _babyName = 'tu bebé';
  FeedingStage _stage = FeedingStage.exclusiveLactation;
  List<String> _feedingTypes = [];

  @override
  void initState() {
    super.initState();
    _loadBabyData();
    _loadFeedingEntries();
  }

  Future<void> _loadFeedingEntries() async {
    final entries = await StorageService.loadFeedingEntries();
    if (mounted) {
      setState(() {
        _entries.clear();
        _entries.addAll(entries);
        _entries.sort((a, b) => a.time.compareTo(b.time));
      });
    }
    debugPrint('✅ Cargadas ${entries.length} entradas de alimentación');
  }

  Future<void> _loadBabyData() async {
    final prefs = await SharedPreferences.getInstance();
    final birthIso = prefs.getString('infant_birthdate');
    final name = prefs.getString('infant_name') ?? 'tu bebé';
    
    int ageInMonths = 0;
    if (birthIso != null) {
      try {
        final birthDate = DateTime.parse(birthIso);
        final now = DateTime.now();
        ageInMonths = (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
        if (now.day < birthDate.day) ageInMonths--;
      } catch (_) {}
    }
    
    // Determinar etapa e intervalos según edad
    FeedingStage stage;
    List<String> types;
    int interval;
    
    if (ageInMonths < 6) {
      stage = FeedingStage.exclusiveLactation;
      types = ['Pecho izq', 'Pecho der', 'Biberón (fórmula)'];
      interval = ageInMonths < 2 ? 2 : 3;
    } else if (ageInMonths < 12) {
      stage = FeedingStage.complementary;
      types = ['Pecho', 'Biberón', 'Papilla de frutas', 'Papilla de verduras', 'Cereal', 'Puré'];
      interval = 3;
    } else if (ageInMonths < 24) {
      stage = FeedingStage.transition;
      types = ['Pecho', 'Leche', 'Desayuno', 'Almuerzo', 'Cena', 'Merienda', 'Snack'];
      interval = 4;
    } else {
      stage = FeedingStage.familyFood;
      types = ['Desayuno', 'Almuerzo', 'Cena', 'Merienda', 'Snack', 'Leche'];
      interval = 4;
    }
    
    if (mounted) {
      setState(() {
        _babyAgeInMonths = ageInMonths;
        _babyName = name;
        _stage = stage;
        _feedingTypes = types;
        _feedingType = types.first;
        _intervalHours = interval;
      });
    }
  }

  String get _stageName {
    switch (_stage) {
      case FeedingStage.exclusiveLactation:
        return 'Lactancia exclusiva';
      case FeedingStage.complementary:
        return 'Alimentación complementaria';
      case FeedingStage.transition:
        return 'Transición a sólidos';
      case FeedingStage.familyFood:
        return 'Alimentación familiar';
    }
  }

  String get _stageTip {
    switch (_stage) {
      case FeedingStage.exclusiveLactation:
        return '🍼 $_babyName está en etapa de lactancia exclusiva. Leche materna o fórmula cada $_intervalHours horas aproximadamente.';
      case FeedingStage.complementary:
        return '🍌 Es momento de introducir alimentos suaves! Comienza con papillas y purés, un alimento nuevo cada 3-4 días.';
      case FeedingStage.transition:
        return '🥗 $_babyName puede comer más variedad. Introduce texturas más sólidas y deja que explore con las manos.';
      case FeedingStage.familyFood:
        return '🍽️ $_babyName puede compartir las comidas familiares. Evita exceso de sal, azúcar y alimentos procesados.';
    }
  }

  Color get _stageColor {
    switch (_stage) {
      case FeedingStage.exclusiveLactation:
        return const Color(0xFFE3F2FD); // Azul claro
      case FeedingStage.complementary:
        return const Color(0xFFFFF3E0); // Naranja claro
      case FeedingStage.transition:
        return const Color(0xFFE8F5E9); // Verde claro
      case FeedingStage.familyFood:
        return const Color(0xFFFCE4EC); // Rosa claro
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime? get _lastFeedingTime => _entries.isEmpty ? null : _entries.last.time;

  DateTime? get _nextFeedingTime =>
      _lastFeedingTime != null ? _lastFeedingTime!.add(Duration(hours: _intervalHours)) : null;

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      helpText: 'Hora del recordatorio',
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
        _scheduledReminderLabel = null; // limpiar confirmación previa
      });
    }
  }

  Future<void> _scheduleCustomReminder() async {
    final now = DateTime.now();
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      _reminderTime.hour,
      _reminderTime.minute,
    );

    final success = await NotificationService.scheduleCustomFeedingReminder(
      scheduledTime: scheduledDate,
      babyName: _babyName,
    );

    if (!mounted) return;

    if (success) {
      final h = _reminderTime.hour.toString().padLeft(2, '0');
      final m = _reminderTime.minute.toString().padLeft(2, '0');
      setState(() => _scheduledReminderLabel = '🔔 Recordatorio programado para las $h:$m');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Recordatorio programado para las $h:$m'),
          backgroundColor: const Color(0xFF4F7A4A),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Esa hora ya pasó. Elige una hora futura.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _addFeeding() async {
    if (_feedingType == null) return;
    
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa la cantidad.')),
      );
      return;
    }

    final amount = double.tryParse(amountText.replaceAll(',', '.'));
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cantidad debe ser un número.')),
      );
      return;
    }

    final now = DateTime.now();
    final feedingDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    setState(() {
      _entries.add(
        FeedingEntry(
          time: feedingDateTime,
          amount: amount,
          type: _feedingType!,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        ),
      );
      _entries.sort((a, b) => a.time.compareTo(b.time));
      _amountController.clear();
      _notesController.clear();
      _selectedTime = TimeOfDay.now();
    });

    // Guardar en almacenamiento persistente
    await StorageService.saveFeedingEntries(_entries);
    debugPrint('✅ Entrada de alimentación guardada');

    final next = _nextFeedingTime;
    if (next != null) {
      // Programar notificación para próxima toma
      await NotificationService.scheduleNextFeedingNotification(
        nextFeedingTime: next,
        babyName: _babyName,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Toma registrada. Próxima toma sugerida a las ${_formatTime(next)}. 🔔 Notificación programada.'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = _nextFeedingTime;

    if (_feedingTypes.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFB6D7A8),
          title: const Text('Comida'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFB6D7A8)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB6D7A8),
        title: const Text('Comida'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.1),
            radius: 1.1,
            colors: [
              Color(0xFFE8F7E4),
              Color(0xFFCFE8C9),
              Color(0xFFB6D7A8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tip del koala
                KoalaTipWidget(
                  section: 'food',
                  languageCode: Localizations.localeOf(context).languageCode,
                ),
                // Tarjeta de etapa actual
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _stageColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _stageColor.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _stage == FeedingStage.exclusiveLactation
                                ? Icons.water_drop
                                : _stage == FeedingStage.complementary
                                    ? Icons.restaurant
                                    : Icons.lunch_dining,
                            color: const Color(0xFF4F7A4A),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _stageName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4F7A4A),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F7A4A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_babyAgeInMonths meses',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _stageTip,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Próxima toma
                if (next != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alarm, color: Color(0xFF4F7A4A)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Próxima comida sugerida a las ${_formatTime(next)} (cada $_intervalHours h).',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4F7A4A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                // ── Programar recordatorio manual ──
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.alarm_add, color: Color(0xFF4F7A4A), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Programar recordatorio',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4F7A4A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Recíbe una notificación a la hora exacta que elijas.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6E8F6A)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Selector de hora
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _pickReminderTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5FFF3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFB6D7A8),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF355334),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.access_time,
                                      color: Color(0xFF4F7A4A),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Botón programar
                          ElevatedButton.icon(
                            onPressed: _scheduleCustomReminder,
                            icon: const Icon(Icons.notifications_active, size: 18),
                            label: const Text('Recordar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F7A4A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_scheduledReminderLabel != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _scheduledReminderLabel!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Formulario de registro
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registrar comida',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4F7A4A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Tipo de comida (dinámico según etapa)
                      DropdownButtonFormField<String>(
                        value: _feedingType,
                        isExpanded: true,
                        items: _feedingTypes.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        )).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _feedingType = value);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Tipo de comida',
                          filled: true,
                          fillColor: Color(0xFFF5FFF3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: _stage == FeedingStage.exclusiveLactation
                                    ? 'ml o minutos'
                                    : 'Cantidad (g/ml)',
                                filled: true,
                                fillColor: const Color(0xFFF5FFF3),
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(16)),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _pickTime,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Hora',
                                  filled: true,
                                  fillColor: Color(0xFFF5FFF3),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(16)),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatTimeOfDay(_selectedTime)),
                                    const Icon(Icons.access_time, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notas (opcional)',
                          filled: true,
                          fillColor: Color(0xFFF5FFF3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB6D7A8),
                            foregroundColor: const Color(0xFF355334),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _addFeeding,
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Historial de hoy',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F7A4A),
                  ),
                ),
                const SizedBox(height: 8),
                if (_entries.isEmpty)
                  const Text(
                    'Aún no has registrado tomas para hoy.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6E8F6A)),
                  )
                else
                  Column(
                    children: [
                      for (final e in _entries)
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(0xFFB6D7A8),
                                child: Icon(
                                  Icons.local_drink,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${e.type} • ${e.amount.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF4F7A4A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (e.notes != null)
                                      Text(
                                        e.notes!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6E8F6A),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(e.time),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MODELO DE CONFIGURACIÓN DE CÁMARA
// ============================================================================
enum CameraProtocol { rtsp, http }

class CameraConfig {
  final String id;
  final String name;
  final String host;
  final CameraProtocol protocol;
  final int rtspPort;
  final String rtspPath;
  final int httpPort;
  final String httpPath;
  final String username;
  final String password;
  final int onvifPort;
  final bool hasPTZ;
  final bool hasAudio;

  CameraConfig({
    required this.id,
    required this.name,
    required this.host,
    this.protocol = CameraProtocol.rtsp,
    this.rtspPort = 554,
    this.rtspPath = '/stream1',
    this.httpPort = 4747,
    this.httpPath = '/video',
    this.username = '',
    this.password = '',
    this.onvifPort = 80,
    this.hasPTZ = true,
    this.hasAudio = true,
  });

  String get streamUrl {
    if (protocol == CameraProtocol.http) {
      // HTTP/MJPEG (para DroidCam y similares)
      return 'http://$host:$httpPort$httpPath';
    } else {
      // RTSP (cámaras IP tradicionales)
      final auth = username.isNotEmpty ? '$username:$password@' : '';
      return 'rtsp://$auth$host:$rtspPort$rtspPath';
    }
  }

  // Mantener compatibilidad con código existente
  String get rtspUrl => streamUrl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'host': host,
    'protocol': protocol.name,
    'rtspPort': rtspPort,
    'rtspPath': rtspPath,
    'httpPort': httpPort,
    'httpPath': httpPath,
    'username': username,
    'password': password,
    'onvifPort': onvifPort,
    'hasPTZ': hasPTZ,
    'hasAudio': hasAudio,
  };

  factory CameraConfig.fromJson(Map<String, dynamic> json) => CameraConfig(
    id: json['id'],
    name: json['name'],
    host: json['host'],
    protocol: json['protocol'] != null 
        ? CameraProtocol.values.firstWhere(
            (e) => e.name == json['protocol'],
            orElse: () => CameraProtocol.rtsp,
          )
        : CameraProtocol.rtsp,
    rtspPort: json['rtspPort'] ?? 554,
    rtspPath: json['rtspPath'] ?? '/stream1',
    httpPort: json['httpPort'] ?? 4747,
    httpPath: json['httpPath'] ?? '/video',
    username: json['username'] ?? '',
    password: json['password'] ?? '',
    onvifPort: json['onvifPort'] ?? 80,
    hasPTZ: json['hasPTZ'] ?? true,
    hasAudio: json['hasAudio'] ?? true,
  );
}

enum CameraConnectionState { disconnected, connecting, connected, error }

// ============================================================================
// CAMERA MONITOR PAGE - Página principal del monitor de cámara
// ============================================================================
class CameraMonitorPage extends StatefulWidget {
  const CameraMonitorPage({super.key});

  @override
  State<CameraMonitorPage> createState() => _CameraMonitorPageState();
}

class _CameraMonitorPageState extends State<CameraMonitorPage> {
  CameraConfig? _cameraConfig;
  CameraConnectionState _connectionState = CameraConnectionState.disconnected;
  String _errorMessage = '';
  bool _isLoading = true;
  bool _isFullscreen = false;
  bool _showControls = true;
  
  // Media Kit
  Player? _player;
  VideoController? _videoController;

  @override
  void initState() {
    super.initState();
    _loadCameraConfig();
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _loadCameraConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('camera_config');
    
    if (configJson != null) {
      try {
        final config = CameraConfig.fromJson(jsonDecode(configJson));
        setState(() {
          _cameraConfig = config;
          _isLoading = false;
        });
        // Auto-conectar si hay configuración guardada
        _connectToCamera();
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCameraConfig(CameraConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('camera_config', jsonEncode(config.toJson()));
    setState(() => _cameraConfig = config);
  }

  Future<void> _deleteCameraConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('camera_config');
    _disconnectCamera();
    setState(() => _cameraConfig = null);
  }

  Future<void> _connectToCamera() async {
    if (_cameraConfig == null) return;

    setState(() {
      _connectionState = CameraConnectionState.connecting;
      _errorMessage = '';
    });

    try {
      if (_cameraConfig!.protocol == CameraProtocol.http) {
        // Para HTTP/MJPEG (DroidCam), no usamos Media Kit
        // Solo marcamos como conectado para mostrar la imagen
        setState(() => _connectionState = CameraConnectionState.connected);
      } else {
        // RTSP: usar Media Kit
        _player?.dispose();
        _player = Player();
        _videoController = VideoController(_player!);

        await _player!.open(
          Media(_cameraConfig!.streamUrl),
          play: true,
        );

        // Escuchar errores
        _player!.stream.error.listen((error) {
          if (mounted) {
            setState(() {
              _connectionState = CameraConnectionState.error;
              _errorMessage = error;
            });
          }
        });

        // Escuchar cuando empiece a reproducir
        _player!.stream.playing.listen((playing) {
          if (mounted && playing) {
            setState(() => _connectionState = CameraConnectionState.connected);
          }
        });

        // Timeout de conexión
        Future.delayed(const Duration(seconds: 15), () {
          if (mounted && _connectionState == CameraConnectionState.connecting) {
            setState(() {
              _connectionState = CameraConnectionState.error;
              _errorMessage = 'Tiempo de espera agotado';
            });
          }
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionState = CameraConnectionState.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _disconnectCamera() {
    _player?.stop();
    _player?.dispose();
    _player = null;
    _videoController = null;
    if (mounted) {
      setState(() => _connectionState = CameraConnectionState.disconnected);
    }
  }

  void _showConfigSheet(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CameraConfigSheet(
        appState: appState,
        existingConfig: _cameraConfig,
        onSave: (config) async {
          Navigator.pop(ctx);
          await _saveCameraConfig(config);
          _connectToCamera();
        },
        onDelete: _cameraConfig != null ? () async {
          Navigator.pop(ctx);
          await _deleteCameraConfig();
        } : null,
      ),
    );
  }

  Future<void> _takeSnapshot() async {
    if (_player == null || _connectionState != CameraConnectionState.connected) return;
    
    try {
      // Capturar screenshot del video
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'snapshot_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '${directory.path}/$fileName';
      
      // media_kit screenshot retorna Uint8List?
      final screenshot = await _player!.screenshot();
      
      if (screenshot != null) {
        final file = File(path);
        await file.writeAsBytes(screenshot);
        
        if (mounted) {
          final appState = Provider.of<AppState>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(appState.tr('snapshot_saved')),
              backgroundColor: const Color(0xFF4F7A4A),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error taking snapshot: $e');
    }
  }

  // Enviar comando PTZ via ONVIF
  Future<void> _sendPTZCommand(String direction) async {
    if (_cameraConfig == null) return;
    
    // Valores de movimiento
    double x = 0, y = 0, zoom = 0;
    switch (direction) {
      case 'left': x = -0.5; break;
      case 'right': x = 0.5; break;
      case 'up': y = 0.5; break;
      case 'down': y = -0.5; break;
      case 'zoom_in': zoom = 0.5; break;
      case 'zoom_out': zoom = -0.5; break;
    }

    // SOAP request para ONVIF PTZ
    final soapBody = '''
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tt="http://www.onvif.org/ver10/schema">
  <soap:Body>
    <tptz:ContinuousMove>
      <tptz:ProfileToken>Profile_1</tptz:ProfileToken>
      <tptz:Velocity>
        <tt:PanTilt x="$x" y="$y"/>
        <tt:Zoom x="$zoom"/>
      </tptz:Velocity>
    </tptz:ContinuousMove>
  </soap:Body>
</soap:Envelope>
''';

    try {
      final url = 'http://${_cameraConfig!.host}:${_cameraConfig!.onvifPort}/onvif/ptz_service';
      await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/soap+xml; charset=utf-8',
        },
        body: soapBody,
      );
    } catch (e) {
      debugPrint('PTZ command error: $e');
    }
  }

  Future<void> _stopPTZ() async {
    if (_cameraConfig == null) return;

    final soapBody = '''
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl">
  <soap:Body>
    <tptz:Stop>
      <tptz:ProfileToken>Profile_1</tptz:ProfileToken>
      <tptz:PanTilt>true</tptz:PanTilt>
      <tptz:Zoom>true</tptz:Zoom>
    </tptz:Stop>
  </soap:Body>
</soap:Envelope>
''';

    try {
      final url = 'http://${_cameraConfig!.host}:${_cameraConfig!.onvifPort}/onvif/ptz_service';
      await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/soap+xml; charset=utf-8'},
        body: soapBody,
      );
    } catch (e) {
      debugPrint('PTZ stop error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5FFF3),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFB6D7A8)),
        ),
      );
    }

    // Si no hay cámara configurada, mostrar pantalla de configuración
    if (_cameraConfig == null) {
      return _buildNoCameraView(context, appState, isDark);
    }

    // Vista de monitoreo
    return _isFullscreen
        ? _buildFullscreenView(context, appState)
        : _buildNormalView(context, appState, isDark);
  }

  Widget _buildNoCameraView(BuildContext context, AppState appState, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5FFF3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB6D7A8),
        title: Text(appState.tr('camera_monitor')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFB6D7A8).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_off,
                  size: 80,
                  color: Color(0xFF4F7A4A),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                appState.tr('no_camera_configured'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF4F4A4A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                appState.tr('tap_to_configure'),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : const Color(0xFF9E9E9E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _showConfigSheet(context),
                icon: const Icon(Icons.add),
                label: Text(appState.tr('add_camera')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F7A4A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalView(BuildContext context, AppState appState, bool isDark) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _buildConnectionIndicator(),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _cameraConfig!.name,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showConfigSheet(context),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            // Video
            Center(
              child: _buildVideoWidget(),
            ),
            // Controles superpuestos
            if (_showControls) ...[
              // Botón pantalla completa
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  onPressed: () => setState(() => _isFullscreen = true),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fullscreen, color: Colors.white),
                  ),
                ),
              ),
              // Barra inferior de controles
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Snapshot
                      _buildControlButton(
                        Icons.camera_alt,
                        appState.tr('snapshot'),
                        _takeSnapshot,
                      ),
                      // Reconectar
                      if (_connectionState != CameraConnectionState.connected)
                        _buildControlButton(
                          Icons.refresh,
                          appState.tr('retry_connection'),
                          _connectToCamera,
                        ),
                    ],
                  ),
                ),
              ),
            ],
            // Controles PTZ (si la cámara los soporta)
            if (_showControls && _cameraConfig!.hasPTZ && _connectionState == CameraConnectionState.connected)
              Positioned(
                right: 16,
                bottom: 100,
                child: _buildPTZControls(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullscreenView(BuildContext context, AppState appState) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            Center(
              child: _buildVideoWidget(),
            ),
            if (_showControls)
              Positioned(
                top: 40,
                left: 16,
                child: IconButton(
                  onPressed: () => setState(() => _isFullscreen = false),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fullscreen_exit, color: Colors.white),
                  ),
                ),
              ),
            if (_showControls && _cameraConfig!.hasPTZ)
              Positioned(
                right: 16,
                bottom: 40,
                child: _buildPTZControls(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoWidget() {
    switch (_connectionState) {
      case CameraConnectionState.disconnected:
        return _buildStatusWidget(
          Icons.videocam_off,
          'Desconectado',
          Colors.grey,
        );
      case CameraConnectionState.connecting:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFFB6D7A8)),
            const SizedBox(height: 16),
            Text(
              Provider.of<AppState>(context).tr('connecting'),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        );
      case CameraConnectionState.error:
        return _buildStatusWidget(
          Icons.error_outline,
          _errorMessage.isNotEmpty ? _errorMessage : 'Error de conexión',
          Colors.redAccent,
        );
      case CameraConnectionState.connected:
        if (_cameraConfig!.protocol == CameraProtocol.http) {
          // HTTP/MJPEG stream
          return _MjpegWidget(url: _cameraConfig!.streamUrl);
        } else if (_videoController != null) {
          // RTSP con Media Kit
          return Video(
            controller: _videoController!,
            fit: BoxFit.contain,
          );
        }
        return const SizedBox();
    }
  }

  Widget _buildStatusWidget(IconData icon, String message, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: color),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(color: color, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConnectionIndicator() {
    Color color;
    switch (_connectionState) {
      case CameraConnectionState.connected:
        color = Colors.green;
        break;
      case CameraConnectionState.connecting:
        color = Colors.orange;
        break;
      case CameraConnectionState.error:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildPTZControls() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Arriba
          _buildPTZButton(Icons.keyboard_arrow_up, 'up'),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPTZButton(Icons.keyboard_arrow_left, 'left'),
              const SizedBox(width: 32),
              _buildPTZButton(Icons.keyboard_arrow_right, 'right'),
            ],
          ),
          // Abajo
          _buildPTZButton(Icons.keyboard_arrow_down, 'down'),
          const SizedBox(height: 8),
          // Zoom
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPTZButton(Icons.remove, 'zoom_out'),
              const SizedBox(width: 8),
              _buildPTZButton(Icons.add, 'zoom_in'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPTZButton(IconData icon, String direction) {
    return GestureDetector(
      onTapDown: (_) => _sendPTZCommand(direction),
      onTapUp: (_) => _stopPTZ(),
      onTapCancel: () => _stopPTZ(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

// ============================================================================
// MJPEG WIDGET - Widget para streams HTTP/MJPEG (DroidCam)
// ============================================================================
class _MjpegWidget extends StatefulWidget {
  final String url;

  const _MjpegWidget({required this.url});

  @override
  State<_MjpegWidget> createState() => _MjpegWidgetState();
}

class _MjpegWidgetState extends State<_MjpegWidget> {
  Uint8List? _currentFrame;
  bool _isLoading = true;
  String _errorMessage = '';
  StreamSubscription<List<int>>? _streamSubscription;
  http.Client? _httpClient;

  @override
  void initState() {
    super.initState();
    _startMjpegStream();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _httpClient?.close();
    super.dispose();
  }

  Future<void> _startMjpegStream() async {
    try {
      _httpClient = http.Client();
      final request = http.Request('GET', Uri.parse(widget.url));
      final response = await _httpClient!.send(request);

      if (response.statusCode == 200) {
        // Buffer para acumular bytes
        List<int> buffer = [];
        const jpegStart = [0xFF, 0xD8]; // Marcador de inicio JPEG
        const jpegEnd = [0xFF, 0xD9];   // Marcador de fin JPEG

        _streamSubscription = response.stream.listen(
          (List<int> chunk) {
            buffer.addAll(chunk);

            // Buscar inicio y fin de imagen JPEG
            int startIndex = -1;
            int endIndex = -1;

            for (int i = 0; i < buffer.length - 1; i++) {
              if (buffer[i] == jpegStart[0] && buffer[i + 1] == jpegStart[1]) {
                startIndex = i;
              }
              if (buffer[i] == jpegEnd[0] && buffer[i + 1] == jpegEnd[1]) {
                endIndex = i + 1;
                break;
              }
            }

            // Si encontramos una imagen completa
            if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
              final imageBytes = buffer.sublist(startIndex, endIndex + 1);
              if (mounted) {
                setState(() {
                  _currentFrame = Uint8List.fromList(imageBytes);
                  _isLoading = false;
                  _errorMessage = '';
                });
              }
              // Limpiar buffer
              buffer = buffer.sublist(endIndex + 1);
            }

            // Evitar que el buffer crezca demasiado
            if (buffer.length > 1024 * 1024) {
              buffer.clear();
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Error de stream: ${error.toString()}';
              });
            }
          },
          onDone: () {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Stream cerrado';
              });
            }
          },
        );
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Error HTTP: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error de conexión: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentFrame == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFB6D7A8)),
            SizedBox(height: 16),
            Text(
              'Conectando a stream HTTP...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'URL: ${widget.url}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_currentFrame != null) {
      return Image.memory(
        _currentFrame!,
        fit: BoxFit.contain,
        gaplessPlayback: true, // Transición suave entre frames
      );
    }

    return const SizedBox();
  }
}

// ============================================================================
// CAMERA CONFIG SHEET - Formulario de configuración de cámara
// ============================================================================
class _CameraConfigSheet extends StatefulWidget {
  const _CameraConfigSheet({
    required this.appState,
    required this.onSave,
    this.existingConfig,
    this.onDelete,
  });

  final AppState appState;
  final CameraConfig? existingConfig;
  final Function(CameraConfig) onSave;
  final VoidCallback? onDelete;

  @override
  State<_CameraConfigSheet> createState() => _CameraConfigSheetState();
}

class _CameraConfigSheetState extends State<_CameraConfigSheet> {
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _pathController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _showPassword = false;
  bool _hasPTZ = true;
  bool _hasAudio = true;
  CameraProtocol _protocol = CameraProtocol.rtsp;

  @override
  void initState() {
    super.initState();
    if (widget.existingConfig != null) {
      final c = widget.existingConfig!;
      _nameController.text = c.name;
      _hostController.text = c.host;
      _protocol = c.protocol;
      if (_protocol == CameraProtocol.http) {
        _portController.text = c.httpPort.toString();
        _pathController.text = c.httpPath;
      } else {
        _portController.text = c.rtspPort.toString();
        _pathController.text = c.rtspPath;
      }
      _userController.text = c.username;
      _passController.text = c.password;
      _hasPTZ = c.hasPTZ;
      _hasAudio = c.hasAudio;
    } else {
      _portController.text = '554';
      _pathController.text = '/stream1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _pathController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.isEmpty || _hostController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre e IP son requeridos'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final port = int.tryParse(_portController.text) ?? (_protocol == CameraProtocol.http ? 4747 : 554);
    final path = _pathController.text.trim().isEmpty 
        ? (_protocol == CameraProtocol.http ? '/video' : '/stream1') 
        : _pathController.text.trim();

    final config = CameraConfig(
      id: widget.existingConfig?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      host: _hostController.text.trim(),
      protocol: _protocol,
      rtspPort: _protocol == CameraProtocol.rtsp ? port : (widget.existingConfig?.rtspPort ?? 554),
      rtspPath: _protocol == CameraProtocol.rtsp ? path : (widget.existingConfig?.rtspPath ?? '/stream1'),
      httpPort: _protocol == CameraProtocol.http ? port : (widget.existingConfig?.httpPort ?? 4747),
      httpPath: _protocol == CameraProtocol.http ? path : (widget.existingConfig?.httpPath ?? '/video'),
      username: _userController.text.trim(),
      password: _passController.text,
      hasPTZ: _hasPTZ,
      hasAudio: _hasAudio,
    );

    widget.onSave(config);
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.appState.tr;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Título
            Row(
              children: [
                const Icon(Icons.videocam, color: Color(0xFF4F7A4A), size: 28),
                const SizedBox(width: 12),
                Text(
                  tr('configure_camera'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F4A4A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Nombre
            _buildTextField(
              controller: _nameController,
              label: tr('camera_name'),
              hint: tr('camera_name_hint'),
              icon: Icons.label,
            ),
            const SizedBox(height: 16),
            // IP
            _buildTextField(
              controller: _hostController,
              label: tr('host_ip'),
              hint: tr('host_ip_hint'),
              icon: Icons.router,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            // Selector de protocolo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings_input_antenna, color: const Color(0xFF4F7A4A), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Protocolo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F4A4A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildProtocolOption(
                          CameraProtocol.rtsp,
                          'RTSP',
                          'Cámaras IP tradicionales',
                          Icons.videocam,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildProtocolOption(
                          CameraProtocol.http,
                          'HTTP',
                          'DroidCam / MJPEG',
                          Icons.phone_android,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Puerto y Ruta (dinámicos según protocolo)
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                    controller: _portController,
                    label: _protocol == CameraProtocol.rtsp ? tr('rtsp_port') : 'Puerto HTTP',
                    hint: _protocol == CameraProtocol.rtsp ? '554' : '4747',
                    icon: Icons.numbers,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _pathController,
                    label: _protocol == CameraProtocol.rtsp ? tr('rtsp_path') : 'Ruta HTTP',
                    hint: _protocol == CameraProtocol.rtsp ? tr('rtsp_path_hint') : '/video',
                    icon: Icons.link,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Usuario
            _buildTextField(
              controller: _userController,
              label: tr('username'),
              hint: 'admin',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            // Contraseña
            _buildTextField(
              controller: _passController,
              label: tr('password'),
              hint: '••••••',
              icon: Icons.lock,
              obscure: !_showPassword,
              suffix: IconButton(
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            const SizedBox(height: 16),
            // Opciones
            SwitchListTile(
              value: _hasPTZ,
              onChanged: (v) => setState(() => _hasPTZ = v),
              title: Text(tr('ptz_controls')),
              subtitle: const Text('Pan/Tilt/Zoom'),
              activeColor: const Color(0xFF4F7A4A),
            ),
            SwitchListTile(
              value: _hasAudio,
              onChanged: (v) => setState(() => _hasAudio = v),
              title: Text(tr('audio_enabled')),
              activeColor: const Color(0xFF4F7A4A),
            ),
            const SizedBox(height: 16),
            // URL Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'URL ${_protocol == CameraProtocol.rtsp ? 'RTSP' : 'HTTP'}:',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _buildPreviewUrl(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Color(0xFF4F7A4A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Botones
            Row(
              children: [
                if (widget.onDelete != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(tr('delete_camera')),
                            content: Text(tr('delete_camera_confirm')),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(tr('cancel')),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  widget.onDelete!();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                child: Text(tr('delete')),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      label: Text(tr('delete'), style: const TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                if (widget.onDelete != null) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: Text(tr('save')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F7A4A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildPreviewUrl() {
    final host = _hostController.text.isEmpty ? 'IP' : _hostController.text;
    final defaultPort = _protocol == CameraProtocol.rtsp ? '554' : '4747';
    final defaultPath = _protocol == CameraProtocol.rtsp ? '/stream1' : '/video';
    final port = _portController.text.isEmpty ? defaultPort : _portController.text;
    final path = _pathController.text.isEmpty ? defaultPath : _pathController.text;
    
    if (_protocol == CameraProtocol.http) {
      return 'http://$host:$port$path';
    } else {
      final user = _userController.text;
      final pass = _passController.text;
      final auth = user.isNotEmpty ? '$user:***@' : '';
      return 'rtsp://$auth$host:$port$path';
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF4F7A4A)),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4F7A4A), width: 2),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildProtocolOption(
    CameraProtocol protocol,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _protocol == protocol;
    return InkWell(
      onTap: () {
        setState(() {
          _protocol = protocol;
          // Actualizar valores por defecto según el protocolo
          if (protocol == CameraProtocol.http) {
            _portController.text = '4747';
            _pathController.text = '/video';
          } else {
            _portController.text = '554';
            _pathController.text = '/stream1';
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F7A4A).withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFF4F7A4A) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF4F7A4A) : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? const Color(0xFF4F7A4A) : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SLEEP PAGE - Página de control de sueño
// ============================================================================
class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  List<SleepSession> _sessions = [];
  SleepSession? _ongoingSession;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await StorageService.loadSleepSessions();
    if (mounted) {
      setState(() {
        _sessions = sessions..sort((a, b) => b.startTime.compareTo(a.startTime));
        _ongoingSession = _sessions.firstWhere(
          (s) => s.isOngoing,
          orElse: () => SleepSession(startTime: DateTime.now()),
        );
        if (!_ongoingSession!.isOngoing) {
          _ongoingSession = null;
        }
      });
    }
    debugPrint('✅ Cargadas ${_sessions.length} sesiones de sueño');
  }

  Future<void> _startSleep() async {
    final session = SleepSession(startTime: DateTime.now());
    setState(() {
      _sessions.insert(0, session);
      _ongoingSession = session;
    });
    await StorageService.saveSleepSessions(_sessions);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sueño iniciado')),
    );
  }

  Future<void> _endSleep() async {
    if (_ongoingSession != null) {
      setState(() {
        _ongoingSession!.endTime = DateTime.now();
        _ongoingSession = null;
      });
      await StorageService.saveSleepSessions(_sessions);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sueño finalizado')),
      );
    }
  }

  Future<void> _deleteSession(SleepSession session) async {
    setState(() => _sessions.remove(session));
    await StorageService.saveSleepSessions(_sessions);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión eliminada')),
    );
  }

  // Calcular total de horas de sueño hoy
  double get _todayTotalHours {
    final today = DateTime.now();
    final todaySessions = _sessions.where((s) {
      return s.startTime.year == today.year &&
          s.startTime.month == today.month &&
          s.startTime.day == today.day &&
          s.durationInMinutes != null;
    });
    
    final totalMinutes = todaySessions.fold<int>(
      0,
      (sum, session) => sum + (session.durationInMinutes ?? 0),
    );
    
    return totalMinutes / 60.0;
  }

  // Calcular promedio de horas de sueño (últimos 7 días)
  double get _averageHours {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final recentSessions = _sessions.where((s) {
      return s.startTime.isAfter(weekAgo) && s.durationInMinutes != null;
    });
    
    if (recentSessions.isEmpty) return 0;
    
    final totalMinutes = recentSessions.fold<int>(
      0,
      (sum, session) => sum + (session.durationInMinutes ?? 0),
    );
    
    // Calcular días únicos
    final uniqueDays = recentSessions
        .map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
        .toSet()
        .length;
    
    return (totalMinutes / 60.0) / uniqueDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF9FA8DA),
        title: const Text('Control de Sueño'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8EAF6),
              Color(0xFFC5CAE9),
              Color(0xFF9FA8DA),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tip del koala
                KoalaTipWidget(
                  section: 'sleep',
                  languageCode: Localizations.localeOf(context).languageCode,
                ),
                // Estadísticas
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.bedtime, size: 48, color: Color(0xFF5C6BC0)),
                      const SizedBox(height: 12),
                      const Text(
                        'Estadísticas de Sueño',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3F51B5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Hoy',
                              '${_todayTotalHours.toStringAsFixed(1)}h',
                              Icons.today,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Promedio',
                              '${_averageHours.toStringAsFixed(1)}h',
                              Icons.trending_up,
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Botones de control
                if (_ongoingSession == null)
                  ElevatedButton.icon(
                    onPressed: _startSleep,
                    icon: const Icon(Icons.nightlight, size: 28),
                    label: const Text(
                      'Iniciar Sueño',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C6BC0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo[400]!,
                          Colors.indigo[600]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bedtime, color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Durmiendo...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Desde: ${_formatTime(_ongoingSession!.startTime)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _endSleep,
                          icon: const Icon(Icons.alarm),
                          label: const Text('Finalizar Sueño'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.indigo[700],
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Historial
                const Text(
                  'Historial de Sueño',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3F51B5),
                  ),
                ),
                const SizedBox(height: 12),

                if (_sessions.where((s) => !s.isOngoing).isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.bedtime_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay sesiones registradas',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._sessions
                      .where((s) => !s.isOngoing)
                      .map((session) => _buildSessionCard(session)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(SleepSession session) {
    final date = session.startTime;
    final isToday = DateTime.now().day == date.day &&
        DateTime.now().month == date.month &&
        DateTime.now().year == date.year;
    
    String dateText;
    if (isToday) {
      dateText = 'Hoy';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF9FA8DA).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bedtime,
              color: Color(0xFF5C6BC0),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F51B5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatTime(session.startTime)} - ${session.endTime != null ? _formatTime(session.endTime!) : "?"}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                session.durationFormatted,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5C6BC0),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                onPressed: () => _deleteSession(session),
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ============================================================================
// HEALTH PAGE - Página de salud
// ============================================================================
class HealthPage extends StatefulWidget {
  final int initialTab;
  const HealthPage({super.key, this.initialTab = 0});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<MedicalAppointment> _appointments = [];
  final List<MedicineReminder> _medicines = [];
  final List<HealthMeasurement> _measurements = [];
  final List<VaccineRecord> _vaccines = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
    _loadAppointments();
    _loadMedicines();
    _loadMeasurements();
    _loadVaccines();
  }

  Future<void> _loadAppointments() async {
    final appointments = await StorageService.loadAppointments();
    if (mounted) {
      setState(() {
        _appointments.clear();
        _appointments.addAll(appointments);
      });
    }
    debugPrint('✅ Cargadas ${appointments.length} citas médicas');
  }

  Future<void> _loadMedicines() async {
    final medicines = await StorageService.loadMedicines();
    if (mounted) {
      setState(() {
        _medicines.clear();
        _medicines.addAll(medicines);
      });
    }
    debugPrint('✅ Cargados ${medicines.length} medicamentos');
  }

  Future<void> _loadMeasurements() async {
    final measurements = await StorageService.loadHealthMeasurements();
    if (mounted) {
      setState(() {
        _measurements.clear();
        _measurements.addAll(measurements);
        _measurements.sort((a, b) => b.date.compareTo(a.date)); // Más recientes primero
      });
    }
    debugPrint('✅ Cargadas ${measurements.length} mediciones de salud');
  }

  Future<void> _loadVaccines() async {
    final vaccines = await StorageService.loadVaccines();
    if (mounted) {
      // Si no hay vacunas guardadas, inicializar con el esquema estándar
      if (vaccines.isEmpty) {
        final standardVaccines = VaccineSchedule.standardVaccines.map((v) {
          return VaccineRecord(
            vaccineId: v['id'] as String,
            name: v['name'] as String,
            ageInMonths: v['ageInMonths'] as int,
          );
        }).toList();
        setState(() {
          _vaccines.clear();
          _vaccines.addAll(standardVaccines);
        });
        await StorageService.saveVaccines(standardVaccines);
      } else {
        setState(() {
          _vaccines.clear();
          _vaccines.addAll(vaccines);
        });
      }
    }
    debugPrint('✅ Cargadas ${_vaccines.length} vacunas');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB6D7A8),
        title: const Text('Salud'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4F7A4A),
          labelColor: const Color(0xFF4F7A4A),
          unselectedLabelColor: const Color(0xFF6E8F6A),
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'Citas'),
            Tab(icon: Icon(Icons.medication), text: 'Medicinas'),
            Tab(icon: Icon(Icons.height), text: 'Crecimiento'),
            Tab(icon: Icon(Icons.vaccines), text: 'Vacunas'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.1),
            radius: 1.1,
            colors: [
              Color(0xFFE8F7E4),
              Color(0xFFCFE8C9),
              Color(0xFFB6D7A8),
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAppointmentsTab(),
            _buildMedicinesTab(),
            _buildGrowthTab(),
            _buildVaccinesTab(),
          ],
        ),
      ),
    );
  }

  // TAB 1: Citas Médicas y Vacunas
  Widget _buildAppointmentsTab() {
    final upcoming = _appointments.where((a) => !a.completed && a.date.isAfter(DateTime.now())).toList();
    upcoming.sort((a, b) => a.date.compareTo(b.date));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tip del koala
            KoalaTipWidget(
              section: 'health',
              languageCode: Localizations.localeOf(context).languageCode,
            ),
            // Botón agregar cita
            ElevatedButton.icon(
              onPressed: _addAppointment,
              icon: const Icon(Icons.add),
              label: const Text('Nueva Cita/Vacuna'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB6D7A8),
                foregroundColor: const Color(0xFF355334),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Próximas citas
            const Text(
              'Próximas citas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4F7A4A),
              ),
            ),
            const SizedBox(height: 12),

            if (upcoming.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay citas programadas',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...upcoming.map((apt) => _buildAppointmentCard(apt)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(MedicalAppointment apt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: apt.type == 'Vacuna'
                ? const Color(0xFFE3F2FD)
                : const Color(0xFFFFF3E0),
            child: Icon(
              apt.type == 'Vacuna' ? Icons.vaccines : Icons.local_hospital,
              color: apt.type == 'Vacuna' ? Colors.blue[700] : Colors.orange[700],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  apt.type,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F7A4A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${apt.date.day}/${apt.date.month}/${apt.date.year} • ${apt.time.format(context)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                if (apt.notes != null && apt.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      apt.notes!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Color(0xFF4F7A4A)),
            onPressed: () async {
              setState(() {
                apt.completed = true;
              });
              // Guardar cambios
              await StorageService.saveAppointments(_appointments);
              // Cancelar notificación si existe
              if (apt.notificationId != null) {
                await NotificationService.cancelNotification(apt.notificationId!);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cita marcada como completada')),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addAppointment() async {
    String? type;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Cita'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: ['Vacuna', 'Cita médica']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => type = val),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(
                    selectedDate == null
                        ? 'Seleccionar fecha'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                  ),
                  leading: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                ListTile(
                  title: Text(
                    selectedTime == null
                        ? 'Seleccionar hora'
                        : selectedTime!.format(context),
                  ),
                  leading: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (type != null && selectedDate != null && selectedTime != null) {
                // Programar notificación y obtener ID
                final notificationId = await NotificationService.scheduleAppointmentNotification(
                  type: type!,
                  date: selectedDate!,
                  time: selectedTime!,
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );

                setState(() {
                  _appointments.add(MedicalAppointment(
                    type: type!,
                    date: selectedDate!,
                    time: selectedTime!,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                    notificationId: notificationId,
                  ));
                });

                // Guardar en almacenamiento persistente
                await StorageService.saveAppointments(_appointments);
                debugPrint('✅ Cita guardada con notificación ID: $notificationId');

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cita agregada 🔔 Notificación programada'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // TAB 2: Medicinas
  Widget _buildMedicinesTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _addMedicine,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Medicamento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB6D7A8),
                foregroundColor: const Color(0xFF355334),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Medicamentos activos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4F7A4A),
              ),
            ),
            const SizedBox(height: 12),

            if (_medicines.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.medication, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay medicamentos registrados',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...(_medicines.map((med) => _buildMedicineCard(med))),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineCard(MedicineReminder med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE8F5E9),
                child: Icon(Icons.medical_services, color: Colors.green[700]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4F7A4A),
                      ),
                    ),
                    Text(
                      med.dosage,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  // Cancelar notificaciones
                  if (med.notificationIds.isNotEmpty) {
                    await NotificationService.cancelNotifications(med.notificationIds);
                  }
                  setState(() => _medicines.remove(med));
                  // Guardar cambios
                  await StorageService.saveMedicines(_medicines);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medicamento eliminado')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5FFF3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.alarm, size: 16, color: Color(0xFF4F7A4A)),
                    const SizedBox(width: 6),
                    Text(
                      '${med.frequency}x al día',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4F7A4A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: med.times
                      .map((t) => Chip(
                            label: Text(
                              t.format(context),
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: const Color(0xFFB6D7A8),
                            labelStyle: const TextStyle(color: Colors.white),
                          ))
                  .toList(),
                ),
                if (med.notes != null && med.notes!.isNotEmpty) const SizedBox(height: 8),
                if (med.notes != null && med.notes!.isNotEmpty)
                  Text(
                    med.notes!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMedicine() async {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final notesController = TextEditingController();
    int frequency = 1;
    final List<TimeOfDay> times = [TimeOfDay.now()];

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Medicamento'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del medicamento',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosis (ej: 5ml, 1 tableta)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: frequency,
                  decoration: const InputDecoration(labelText: 'Frecuencia diaria'),
                  items: [1, 2, 3, 4]
                      .map((f) => DropdownMenuItem(
                          value: f, child: Text('$f vez${f > 1 ? "es" : ""} al día')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        frequency = val;
                        times.clear();
                        for (int i = 0; i < val; i++) {
                          times.add(TimeOfDay.now());
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Horarios:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                ...List.generate(frequency, (i) {
                  return ListTile(
                    title: Text(
                      'Toma ${i + 1}: ${times[i].format(context)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: times[i],
                      );
                      if (time != null) {
                        setDialogState(() => times[i] = time);
                      }
                    },
                  );
                }),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty &&
                  dosageController.text.trim().isNotEmpty) {
                // Programar notificaciones recurrentes
                final notificationIds = await NotificationService.scheduleMedicineNotifications(
                  medicineName: nameController.text.trim(),
                  dosage: dosageController.text.trim(),
                  times: times,
                );

                setState(() {
                  _medicines.add(MedicineReminder(
                    name: nameController.text.trim(),
                    dosage: dosageController.text.trim(),
                    frequency: frequency,
                    times: times,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                    notificationIds: notificationIds,
                  ));
                });

                // Guardar en almacenamiento persistente
                await StorageService.saveMedicines(_medicines);
                debugPrint('✅ Medicamento guardado con ${notificationIds.length} notificaciones');

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Medicamento agregado 🔔 ${notificationIds.length} recordatorios programados'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // TAB 3: Crecimiento (Peso y Talla)
  Widget _buildGrowthTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botón agregar medición
            ElevatedButton.icon(
              onPressed: _addMeasurement,
              icon: const Icon(Icons.add),
              label: const Text('Nueva Medición'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB6D7A8),
                foregroundColor: const Color(0xFF355334),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Botón ver gráficas
            OutlinedButton.icon(
              onPressed: () {
                // Navegar a StatsPage (tab de estadísticas)
                Navigator.of(context).pop(); // Cerrar HealthPage
                // El usuario puede ir manualmente a Stats desde el bottom nav
              },
              icon: const Icon(Icons.show_chart),
              label: const Text('Ver Gráficas de Crecimiento'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4F7A4A),
                side: const BorderSide(color: Color(0xFF4F7A4A), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Historial de mediciones
            const Text(
              'Historial de mediciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4F7A4A),
              ),
            ),
            const SizedBox(height: 12),

            if (_measurements.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay mediciones registradas',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._measurements.map((m) => _buildMeasurementCard(m)),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementCard(HealthMeasurement measurement) {
    // Obtener género del bebé para percentiles
    // Por ahora usar 'masculino' por defecto, se puede mejorar
    final percentilePeso = 50.0; // Placeholder
    final percentileTalla = 50.0; // Placeholder
    
    final dateStr = '${measurement.date.day}/${measurement.date.month}/${measurement.date.year}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF4F7A4A)),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F7A4A),
                ),
              ),
              const Spacer(),
              Text(
                '${measurement.ageInMonths} meses',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricChip(
                  icon: Icons.monitor_weight,
                  label: 'Peso',
                  value: '${measurement.weight.toStringAsFixed(1)} kg',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricChip(
                  icon: Icons.height,
                  label: 'Talla',
                  value: '${measurement.height.toStringAsFixed(1)} cm',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMeasurement() async {
    final prefs = await SharedPreferences.getInstance();
    final birthIso = prefs.getString('infant_birthdate');
    
    if (birthIso == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró fecha de nacimiento del bebé')),
      );
      return;
    }

    DateTime? selectedDate = DateTime.now();
    final weightController = TextEditingController();
    final heightController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Medición'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    selectedDate == null
                        ? 'Seleccionar fecha'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                  ),
                  leading: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.parse(birthIso),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: heightController,
                  decoration: const InputDecoration(
                    labelText: 'Talla (cm)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.height),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final weight = double.tryParse(weightController.text.replaceAll(',', '.'));
              final height = double.tryParse(heightController.text.replaceAll(',', '.'));
              
              if (weight != null && height != null && selectedDate != null) {
                // Calcular edad en meses
                final birthDate = DateTime.parse(birthIso);
                final ageInMonths = ((selectedDate!.year - birthDate.year) * 12 + 
                    (selectedDate!.month - birthDate.month));
                
                setState(() {
                  _measurements.add(HealthMeasurement(
                    date: selectedDate!,
                    weight: weight,
                    height: height,
                    ageInMonths: ageInMonths,
                  ));
                  _measurements.sort((a, b) => b.date.compareTo(a.date));
                });
                
                // Guardar
                await StorageService.saveHealthMeasurements(_measurements);
                debugPrint('✅ Medición guardada');
                
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medición agregada')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // TAB 4: Vacunas
  Widget _buildVaccinesTab() {
    // Agrupar vacunas por edad
    final vaccinesByAge = <int, List<VaccineRecord>>{};
    for (final vaccine in _vaccines) {
      if (!vaccinesByAge.containsKey(vaccine.ageInMonths)) {
        vaccinesByAge[vaccine.ageInMonths] = [];
      }
      vaccinesByAge[vaccine.ageInMonths]!.add(vaccine);
    }
    final sortedAges = vaccinesByAge.keys.toList()..sort();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            const Text(
              'Cartilla de Vacunación',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4F7A4A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esquema de vacunación recomendado',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // Vacunas agrupadas por edad
            ...sortedAges.map((ageInMonths) {
              final vaccines = vaccinesByAge[ageInMonths]!;
              final applied = vaccines.where((v) => v.isApplied).length;
              final total = vaccines.length;
              
              String ageText;
              if (ageInMonths == 0) {
                ageText = 'Recién nacido';
              } else if (ageInMonths < 12) {
                ageText = '$ageInMonths ${ageInMonths == 1 ? "mes" : "meses"}';
              } else {
                final years = ageInMonths ~/ 12;
                final months = ageInMonths % 12;
                if (months == 0) {
                  ageText = '$years ${years == 1 ? "año" : "años"}';
                } else {
                  ageText = '$years ${years == 1 ? "año" : "años"} y $months ${months == 1 ? "mes" : "meses"}';
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: applied == total
                            ? const Color(0xFFB6D7A8).withOpacity(0.3)
                            : const Color(0xFFFFF3CD).withOpacity(0.5),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            applied == total
                                ? Icons.check_circle
                                : Icons.pending,
                            color: applied == total
                                ? Colors.green[700]
                                : Colors.orange[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ageText,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4F7A4A),
                                  ),
                                ),
                                Text(
                                  '$applied de $total aplicadas',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...vaccines.map((vaccine) => _buildVaccineItem(vaccine)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccineItem(VaccineRecord vaccine) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: vaccine.isApplied,
            onChanged: (value) async {
              if (value == true) {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  helpText: 'Fecha de aplicación',
                );
                if (date != null) {
                  setState(() {
                    vaccine.appliedDate = date;
                  });
                  await StorageService.saveVaccines(_vaccines);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vacuna marcada como aplicada')),
                  );
                }
              } else {
                setState(() {
                  vaccine.appliedDate = null;
                });
                await StorageService.saveVaccines(_vaccines);
              }
            },
            activeColor: const Color(0xFF4F7A4A),
          ),
          const SizedBox(width: 12),
          // Info de la vacuna
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vaccine.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: vaccine.isApplied
                        ? const Color(0xFF4F7A4A)
                        : Colors.black87,
                    decoration: vaccine.isApplied
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (vaccine.appliedDate != null)
                  Text(
                    'Aplicada: ${vaccine.appliedDate!.day}/${vaccine.appliedDate!.month}/${vaccine.appliedDate!.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          // Icono de estado
          if (vaccine.isApplied)
            Icon(
              Icons.check_circle,
              color: Colors.green[600],
              size: 24,
            )
          else
            Icon(
              Icons.radio_button_unchecked,
              color: Colors.grey[400],
              size: 24,
            ),
        ],
      ),
    );
  }

}

// ============================================================================
// MODELO DE HITO (MILESTONE)
// ============================================================================
enum MilestoneCategory { physical, social, cognitive, special }

class Milestone {
  final String id;
  final String titleKey;
  final String? customTitle;
  final String? description;
  final DateTime? date;
  final String? photoBase64;
  final int minAgeMonths;
  final int maxAgeMonths;
  final String iconName;
  final MilestoneCategory category;
  final bool isCompleted;

  Milestone({
    required this.id,
    required this.titleKey,
    this.customTitle,
    this.description,
    this.date,
    this.photoBase64,
    required this.minAgeMonths,
    required this.maxAgeMonths,
    required this.iconName,
    required this.category,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'titleKey': titleKey,
    'customTitle': customTitle,
    'description': description,
    'date': date?.toIso8601String(),
    'photoBase64': photoBase64,
    'minAgeMonths': minAgeMonths,
    'maxAgeMonths': maxAgeMonths,
    'iconName': iconName,
    'category': category.index,
    'isCompleted': isCompleted,
  };

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
    id: json['id'],
    titleKey: json['titleKey'],
    customTitle: json['customTitle'],
    description: json['description'],
    date: json['date'] != null ? DateTime.parse(json['date']) : null,
    photoBase64: json['photoBase64'],
    minAgeMonths: json['minAgeMonths'],
    maxAgeMonths: json['maxAgeMonths'],
    iconName: json['iconName'],
    category: MilestoneCategory.values[json['category']],
    isCompleted: json['isCompleted'] ?? false,
  );

  Milestone copyWith({
    String? id,
    String? titleKey,
    String? customTitle,
    String? description,
    DateTime? date,
    String? photoBase64,
    int? minAgeMonths,
    int? maxAgeMonths,
    String? iconName,
    MilestoneCategory? category,
    bool? isCompleted,
  }) => Milestone(
    id: id ?? this.id,
    titleKey: titleKey ?? this.titleKey,
    customTitle: customTitle ?? this.customTitle,
    description: description ?? this.description,
    date: date ?? this.date,
    photoBase64: photoBase64 ?? this.photoBase64,
    minAgeMonths: minAgeMonths ?? this.minAgeMonths,
    maxAgeMonths: maxAgeMonths ?? this.maxAgeMonths,
    iconName: iconName ?? this.iconName,
    category: category ?? this.category,
    isCompleted: isCompleted ?? this.isCompleted,
  );

  IconData get icon {
    switch (iconName) {
      case 'sentiment_very_satisfied': return Icons.sentiment_very_satisfied;
      case 'bathtub': return Icons.bathtub;
      case 'accessibility_new': return Icons.accessibility_new;
      case 'stroller': return Icons.stroller;
      case 'nightlight': return Icons.nightlight;
      case 'mood': return Icons.mood;
      case 'face': return Icons.face;
      case 'restaurant': return Icons.restaurant;
      case 'event_seat': return Icons.event_seat;
      case 'record_voice_over': return Icons.record_voice_over;
      case 'directions_walk': return Icons.directions_walk;
      case 'directions_run': return Icons.directions_run;
      case 'pan_tool': return Icons.pan_tool;
      case 'celebration': return Icons.celebration;
      case 'cake': return Icons.cake;
      case 'chat_bubble': return Icons.chat_bubble;
      case 'park': return Icons.park;
      case 'wc': return Icons.wc;
      case 'school': return Icons.school;
      case 'people': return Icons.people;
      case 'draw': return Icons.draw;
      case 'palette': return Icons.palette;
      case 'pets': return Icons.pets;
      case 'flight_takeoff': return Icons.flight_takeoff;
      case 'star': return Icons.star;
      default: return Icons.emoji_events;
    }
  }
}

// Lista de hitos predefinidos por etapa de edad
class MilestoneTemplates {
  static List<Milestone> getTemplatesForAge(int ageInMonths) {
    final List<Milestone> templates = [];
    
    // 0-6 meses - Recién nacido
    if (ageInMonths <= 12) {
      templates.addAll([
        Milestone(id: 'first_smile', titleKey: 'first_smile', minAgeMonths: 0, maxAgeMonths: 3, iconName: 'sentiment_very_satisfied', category: MilestoneCategory.social),
        Milestone(id: 'first_bath', titleKey: 'first_bath', minAgeMonths: 0, maxAgeMonths: 1, iconName: 'bathtub', category: MilestoneCategory.special),
        Milestone(id: 'held_head', titleKey: 'held_head', minAgeMonths: 1, maxAgeMonths: 4, iconName: 'accessibility_new', category: MilestoneCategory.physical),
        Milestone(id: 'first_outing', titleKey: 'first_outing', minAgeMonths: 0, maxAgeMonths: 2, iconName: 'stroller', category: MilestoneCategory.special),
        Milestone(id: 'slept_through', titleKey: 'slept_through', minAgeMonths: 2, maxAgeMonths: 6, iconName: 'nightlight', category: MilestoneCategory.physical),
        Milestone(id: 'first_laugh', titleKey: 'first_laugh', minAgeMonths: 2, maxAgeMonths: 5, iconName: 'mood', category: MilestoneCategory.social),
      ]);
    }
    
    // 6-12 meses - Bebé
    if (ageInMonths >= 4 && ageInMonths <= 18) {
      templates.addAll([
        Milestone(id: 'first_tooth', titleKey: 'first_tooth', minAgeMonths: 4, maxAgeMonths: 12, iconName: 'face', category: MilestoneCategory.physical),
        Milestone(id: 'first_solids', titleKey: 'first_solids', minAgeMonths: 4, maxAgeMonths: 7, iconName: 'restaurant', category: MilestoneCategory.physical),
        Milestone(id: 'sat_alone', titleKey: 'sat_alone', minAgeMonths: 5, maxAgeMonths: 9, iconName: 'event_seat', category: MilestoneCategory.physical),
        Milestone(id: 'first_words', titleKey: 'first_words', minAgeMonths: 8, maxAgeMonths: 14, iconName: 'record_voice_over', category: MilestoneCategory.cognitive),
        Milestone(id: 'first_crawl', titleKey: 'first_crawl', minAgeMonths: 6, maxAgeMonths: 10, iconName: 'directions_walk', category: MilestoneCategory.physical),
        Milestone(id: 'first_steps', titleKey: 'first_steps', minAgeMonths: 9, maxAgeMonths: 15, iconName: 'directions_walk', category: MilestoneCategory.physical),
        Milestone(id: 'waved_bye', titleKey: 'waved_bye', minAgeMonths: 8, maxAgeMonths: 12, iconName: 'pan_tool', category: MilestoneCategory.social),
        Milestone(id: 'clapped_hands', titleKey: 'clapped_hands', minAgeMonths: 8, maxAgeMonths: 12, iconName: 'celebration', category: MilestoneCategory.social),
        Milestone(id: 'first_birthday', titleKey: 'first_birthday', minAgeMonths: 12, maxAgeMonths: 12, iconName: 'cake', category: MilestoneCategory.special),
      ]);
    }
    
    // 12-24 meses - Niño pequeño
    if (ageInMonths >= 10 && ageInMonths <= 30) {
      templates.addAll([
        Milestone(id: 'first_run', titleKey: 'first_run', minAgeMonths: 14, maxAgeMonths: 20, iconName: 'directions_run', category: MilestoneCategory.physical),
        Milestone(id: 'first_sentences', titleKey: 'first_sentences', minAgeMonths: 18, maxAgeMonths: 26, iconName: 'chat_bubble', category: MilestoneCategory.cognitive),
        Milestone(id: 'playground_first', titleKey: 'playground_first', minAgeMonths: 12, maxAgeMonths: 24, iconName: 'park', category: MilestoneCategory.special),
        Milestone(id: 'potty_trained', titleKey: 'potty_trained', minAgeMonths: 18, maxAgeMonths: 36, iconName: 'wc', category: MilestoneCategory.physical),
        Milestone(id: 'second_birthday', titleKey: 'second_birthday', minAgeMonths: 24, maxAgeMonths: 24, iconName: 'cake', category: MilestoneCategory.special),
      ]);
    }
    
    // 24+ meses - Preescolar
    if (ageInMonths >= 20) {
      templates.addAll([
        Milestone(id: 'first_school', titleKey: 'first_school', minAgeMonths: 24, maxAgeMonths: 48, iconName: 'school', category: MilestoneCategory.special),
        Milestone(id: 'first_friend', titleKey: 'first_friend', minAgeMonths: 24, maxAgeMonths: 48, iconName: 'people', category: MilestoneCategory.social),
        Milestone(id: 'first_drawing', titleKey: 'first_drawing', minAgeMonths: 18, maxAgeMonths: 36, iconName: 'draw', category: MilestoneCategory.cognitive),
        Milestone(id: 'learned_colors', titleKey: 'learned_colors', minAgeMonths: 24, maxAgeMonths: 42, iconName: 'palette', category: MilestoneCategory.cognitive),
        Milestone(id: 'third_birthday', titleKey: 'third_birthday', minAgeMonths: 36, maxAgeMonths: 36, iconName: 'cake', category: MilestoneCategory.special),
        Milestone(id: 'first_pet', titleKey: 'first_pet', minAgeMonths: 24, maxAgeMonths: 72, iconName: 'pets', category: MilestoneCategory.special),
        Milestone(id: 'first_trip', titleKey: 'first_trip', minAgeMonths: 12, maxAgeMonths: 72, iconName: 'flight_takeoff', category: MilestoneCategory.special),
      ]);
    }
    
    // Eliminar duplicados por ID
    final Map<String, Milestone> unique = {};
    for (final m in templates) {
      unique[m.id] = m;
    }
    
    return unique.values.toList();
  }
}

// ============================================================================
// MEMORIES DIARY PAGE - Página principal del diario
// ============================================================================
class MemoriesDiaryPage extends StatefulWidget {
  const MemoriesDiaryPage({super.key});

  @override
  State<MemoriesDiaryPage> createState() => _MemoriesDiaryPageState();
}

class _MemoriesDiaryPageState extends State<MemoriesDiaryPage> with SingleTickerProviderStateMixin {
  List<Milestone> _savedMilestones = [];
  List<Milestone> _suggestedMilestones = [];
  int _babyAgeInMonths = 0;
  String _babyName = '';
  String _babyGender = 'otro';
  Uint8List? _babyPhoto;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Cargar datos del bebé
    final birthIso = prefs.getString('infant_birthdate');
    final name = prefs.getString('infant_name') ?? '';
    final gender = prefs.getString('infant_gender') ?? 'otro';
    final photoBase64 = prefs.getString('infant_photo');
    
    int ageInMonths = 0;
    if (birthIso != null) {
      try {
        final birthDate = DateTime.parse(birthIso);
        final now = DateTime.now();
        ageInMonths = (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
        if (now.day < birthDate.day) ageInMonths--;
      } catch (_) {}
    }
    
    Uint8List? photoBytes;
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      try {
        photoBytes = base64Decode(photoBase64);
      } catch (_) {}
    }
    
    // Cargar hitos guardados
    final savedJson = prefs.getString('diary_milestones');
    List<Milestone> saved = [];
    if (savedJson != null) {
      try {
        final List decoded = jsonDecode(savedJson);
        saved = decoded.map((e) => Milestone.fromJson(e)).toList();
      } catch (_) {}
    }
    
    // Obtener hitos sugeridos según la edad
    final templates = MilestoneTemplates.getTemplatesForAge(ageInMonths);
    // Filtrar los que ya fueron completados
    final savedIds = saved.map((m) => m.id).toSet();
    final suggested = templates.where((t) => !savedIds.contains(t.id)).toList();
    
    if (mounted) {
      setState(() {
        _babyAgeInMonths = ageInMonths;
        _babyName = name;
        _babyGender = gender;
        _babyPhoto = photoBytes;
        _savedMilestones = saved;
        _suggestedMilestones = suggested;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveMilestones() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_savedMilestones.map((m) => m.toJson()).toList());
    await prefs.setString('diary_milestones', json);
  }

  void _addMilestone(Milestone milestone) {
    setState(() {
      _savedMilestones.insert(0, milestone.copyWith(isCompleted: true, date: milestone.date ?? DateTime.now()));
      _suggestedMilestones.removeWhere((m) => m.id == milestone.id);
    });
    _saveMilestones();
  }

  void _deleteMilestone(String id) {
    setState(() {
      _savedMilestones.removeWhere((m) => m.id == id);
    });
    _saveMilestones();
    _loadData(); // Recargar sugerencias
  }

  Color get _themeColor {
    switch (_babyGender.toLowerCase()) {
      case 'masculino': return const Color(0xFFB3D9FF);
      case 'femenino': return const Color(0xFFF7C7C7);
      default: return const Color(0xFFB6D7A8);
    }
  }

  Color get _accentColor {
    switch (_babyGender.toLowerCase()) {
      case 'masculino': return const Color(0xFF5B9BD5);
      case 'femenino': return const Color(0xFFE8A0A0);
      default: return const Color(0xFF4F7A4A);
    }
  }

  String _getAgeStageLabel(AppState appState) {
    if (_babyAgeInMonths < 6) return appState.tr('age_stage_newborn');
    if (_babyAgeInMonths < 12) return appState.tr('age_stage_baby');
    if (_babyAgeInMonths < 24) return appState.tr('age_stage_toddler');
    return appState.tr('age_stage_preschool');
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5FFF3),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFB6D7A8)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFFDF7),
      appBar: AppBar(
        backgroundColor: _themeColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF4F4A4A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          appState.tr('diary_title'),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF4F4A4A),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_savedMilestones.isNotEmpty)
            IconButton(
              icon: Icon(Icons.photo_album, color: isDark ? Colors.white : const Color(0xFF4F4A4A)),
              tooltip: appState.tr('generate_album'),
              onPressed: () => _showAlbumOptions(context, appState),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? Colors.white : const Color(0xFF4F4A4A),
          unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF9E9E9E),
          indicatorColor: _accentColor,
          tabs: [
            Tab(text: appState.tr('my_milestones')),
            Tab(text: appState.tr('suggested_milestones')),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tip del koala
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: KoalaTipWidget(
              section: 'diary',
              languageCode: appState.locale.languageCode,
            ),
          ),
          // Header con info del bebé
          _buildBabyHeader(appState),
          // Tabs content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyMilestonesTab(appState, isDark),
                _buildSuggestedMilestonesTab(appState, isDark),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMilestoneSheet(context, appState),
        backgroundColor: _accentColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(appState.tr('add_milestone'), style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildBabyHeader(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _themeColor.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: _themeColor,
            backgroundImage: _babyPhoto != null ? MemoryImage(_babyPhoto!) : null,
            child: _babyPhoto == null
                ? Icon(Icons.child_care, color: _accentColor, size: 32)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _babyName.isNotEmpty ? _babyName : 'Mi bebé',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_getAgeStageLabel(appState)} · $_babyAgeInMonths ${appState.tr('months')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Icon(Icons.emoji_events, color: _accentColor, size: 28),
              Text(
                '${_savedMilestones.length}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _accentColor,
                ),
              ),
              Text(
                appState.tr('milestones'),
                style: TextStyle(
                  fontSize: 10,
                  color: _accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyMilestonesTab(AppState appState, bool isDark) {
    if (_savedMilestones.isEmpty) {
      return _buildEmptyState(appState, isDark);
    }

    // Ordenar por fecha (más reciente primero)
    final sorted = List<Milestone>.from(_savedMilestones)
      ..sort((a, b) => (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now()));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        return _MilestoneCard(
          milestone: sorted[index],
          appState: appState,
          themeColor: _themeColor,
          accentColor: _accentColor,
          onDelete: () => _confirmDeleteMilestone(context, appState, sorted[index].id),
          onTap: () => _showMilestoneDetail(context, appState, sorted[index]),
        );
      },
    );
  }

  Widget _buildSuggestedMilestonesTab(AppState appState, bool isDark) {
    if (_suggestedMilestones.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: _accentColor),
            const SizedBox(height: 16),
            Text(
              '¡Has completado todos los hitos!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF4F4A4A),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suggestedMilestones.length,
      itemBuilder: (context, index) {
        final milestone = _suggestedMilestones[index];
        return _SuggestedMilestoneCard(
          milestone: milestone,
          appState: appState,
          themeColor: _themeColor,
          accentColor: _accentColor,
          babyAgeInMonths: _babyAgeInMonths,
          onAdd: () => _showAddMilestoneSheet(context, appState, template: milestone),
        );
      },
    );
  }

  Widget _buildEmptyState(AppState appState, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _themeColor.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories,
                size: 64,
                color: _accentColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              appState.tr('no_milestones'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF4F4A4A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              appState.tr('add_first_milestone'),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : const Color(0xFF9E9E9E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _tabController.animateTo(1); // Ir a sugerencias
              },
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(appState.tr('suggested_milestones')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMilestoneSheet(BuildContext context, AppState appState, {Milestone? template}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddMilestoneSheet(
        appState: appState,
        template: template,
        themeColor: _themeColor,
        accentColor: _accentColor,
        onSave: (milestone) {
          _addMilestone(milestone);
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(appState.tr('milestone_saved')),
              backgroundColor: _accentColor,
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteMilestone(BuildContext context, AppState appState, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appState.tr('delete_milestone')),
        content: Text(appState.tr('delete_milestone_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(appState.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteMilestone(id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(appState.tr('milestone_deleted')),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(appState.tr('delete')),
          ),
        ],
      ),
    );
  }

  void _showMilestoneDetail(BuildContext context, AppState appState, Milestone milestone) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _MilestoneDetailPage(
          milestone: milestone,
          appState: appState,
          themeColor: _themeColor,
          accentColor: _accentColor,
          babyName: _babyName,
        ),
      ),
    );
  }

  void _showAlbumOptions(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              appState.tr('generate_album'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4F4A4A),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _themeColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.download, color: _accentColor),
              ),
              title: Text(appState.tr('download_album')),
              subtitle: const Text('PDF con diseño cute'),
              onTap: () {
                Navigator.pop(ctx);
                _generateAndSaveAlbum(context, appState);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _themeColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.share, color: _accentColor),
              ),
              title: Text(appState.tr('share_album')),
              subtitle: const Text('Compartir con familia'),
              onTap: () {
                Navigator.pop(ctx);
                _generateAndShareAlbum(context, appState);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndSaveAlbum(BuildContext context, AppState appState) async {
    _showLoadingDialog(context, appState.tr('generating_album'));
    
    try {
      final pdfBytes = await _generatePdfAlbum(appState);
      
      // Solicitar permiso de almacenamiento
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (mounted) Navigator.pop(context);
          return;
        }
      }
      
      // Guardar en descargas
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'album_${_babyName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appState.tr('album_saved')),
            backgroundColor: _accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _generateAndShareAlbum(BuildContext context, AppState appState) async {
    _showLoadingDialog(context, appState.tr('generating_album'));
    
    try {
      final pdfBytes = await _generatePdfAlbum(appState);
      
      final directory = await getTemporaryDirectory();
      final fileName = 'album_${_babyName.replaceAll(' ', '_')}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      
      if (mounted) {
        Navigator.pop(context);
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Álbum de recuerdos de $_babyName 💕',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: _accentColor),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _generatePdfAlbum(AppState appState) async {
    final pdf = pw.Document();
    
    // Colores cute según género
    PdfColor mainColor;
    PdfColor lightColor;
    switch (_babyGender.toLowerCase()) {
      case 'masculino':
        mainColor = const PdfColor.fromInt(0xFF5B9BD5);
        lightColor = const PdfColor.fromInt(0xFFE8F4FD);
        break;
      case 'femenino':
        mainColor = const PdfColor.fromInt(0xFFE8A0A0);
        lightColor = const PdfColor.fromInt(0xFFFFF0F0);
        break;
      default:
        mainColor = const PdfColor.fromInt(0xFF4F7A4A);
        lightColor = const PdfColor.fromInt(0xFFE8F7E4);
    }

    // Portada
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            color: lightColor,
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: mainColor,
                      borderRadius: pw.BorderRadius.circular(100),
                    ),
                    child: pw.Text(
                      '👶',
                      style: const pw.TextStyle(fontSize: 60),
                    ),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'Álbum de Recuerdos',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: mainColor,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    _babyName,
                    style: pw.TextStyle(
                      fontSize: 28,
                      color: mainColor,
                    ),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    '✨ ${_savedMilestones.length} momentos especiales ✨',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: mainColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // Páginas de hitos
    final sorted = List<Milestone>.from(_savedMilestones)
      ..sort((a, b) => (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

    for (var i = 0; i < sorted.length; i++) {
      final milestone = sorted[i];
      final title = milestone.customTitle ?? appState.tr(milestone.titleKey);
      final dateStr = milestone.date != null
          ? DateFormat('dd MMMM yyyy', appState.locale.languageCode).format(milestone.date!)
          : '';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Header decorativo
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: lightColor,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      '⭐ Momento #${i + 1} ⭐',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: mainColor,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  // Título
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: mainColor,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 10),
                  // Fecha
                  if (dateStr.isNotEmpty)
                    pw.Text(
                      '📅 $dateStr',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                  pw.SizedBox(height: 30),
                  // Foto
                  if (milestone.photoBase64 != null)
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: mainColor, width: 4),
                        borderRadius: pw.BorderRadius.circular(20),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 16,
                        verticalRadius: 16,
                        child: pw.Image(
                          pw.MemoryImage(base64Decode(milestone.photoBase64!)),
                          width: 350,
                          height: 350,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    pw.Container(
                      width: 350,
                      height: 350,
                      decoration: pw.BoxDecoration(
                        color: lightColor,
                        borderRadius: pw.BorderRadius.circular(20),
                        border: pw.Border.all(color: mainColor, width: 2),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          '📷',
                          style: const pw.TextStyle(fontSize: 80),
                        ),
                      ),
                    ),
                  pw.SizedBox(height: 20),
                  // Descripción
                  if (milestone.description != null && milestone.description!.isNotEmpty)
                    pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: lightColor,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Text(
                        milestone.description!,
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey800,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  pw.Spacer(),
                  // Footer cute
                  pw.Text(
                    '💕 Con amor, para $_babyName 💕',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: mainColor,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }
}

// ============================================================================
// MILESTONE CARD - Tarjeta de hito completado
// ============================================================================
class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.milestone,
    required this.appState,
    required this.themeColor,
    required this.accentColor,
    required this.onDelete,
    required this.onTap,
  });

  final Milestone milestone;
  final AppState appState;
  final Color themeColor;
  final Color accentColor;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = milestone.customTitle ?? appState.tr(milestone.titleKey);
    final dateStr = milestone.date != null
        ? DateFormat('dd MMM yyyy', appState.locale.languageCode).format(milestone.date!)
        : '';
    final hasPhoto = milestone.photoBase64 != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto o placeholder
              if (hasPhoto)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.memory(
                    base64Decode(milestone.photoBase64!),
                    fit: BoxFit.cover,
                  ),
                )
              else
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [themeColor.withValues(alpha: 0.5), themeColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        milestone.icon,
                        size: 64,
                        color: accentColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              // Info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(milestone.icon, color: accentColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                          if (dateStr.isNotEmpty)
                            Text(
                              '📅 $dateStr',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SUGGESTED MILESTONE CARD - Tarjeta de hito sugerido
// ============================================================================
class _SuggestedMilestoneCard extends StatelessWidget {
  const _SuggestedMilestoneCard({
    required this.milestone,
    required this.appState,
    required this.themeColor,
    required this.accentColor,
    required this.babyAgeInMonths,
    required this.onAdd,
  });

  final Milestone milestone;
  final AppState appState;
  final Color themeColor;
  final Color accentColor;
  final int babyAgeInMonths;
  final VoidCallback onAdd;

  String _getAgeRangeText() {
    if (milestone.minAgeMonths == milestone.maxAgeMonths) {
      return '${milestone.minAgeMonths} meses';
    }
    return '${milestone.minAgeMonths}-${milestone.maxAgeMonths} meses';
  }

  bool get _isInRange => 
      babyAgeInMonths >= milestone.minAgeMonths && 
      babyAgeInMonths <= milestone.maxAgeMonths;

  @override
  Widget build(BuildContext context) {
    final title = appState.tr(milestone.titleKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: _isInRange
            ? Border.all(color: accentColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isInRange
                ? accentColor.withValues(alpha: 0.2)
                : themeColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            milestone.icon,
            color: _isInRange ? accentColor : Colors.grey[600],
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _isInRange ? accentColor : Colors.grey[700],
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.schedule,
              size: 14,
              color: _isInRange ? accentColor : Colors.grey[500],
            ),
            const SizedBox(width: 4),
            Text(
              _getAgeRangeText(),
              style: TextStyle(
                fontSize: 12,
                color: _isInRange ? accentColor : Colors.grey[500],
              ),
            ),
            if (_isInRange) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '¡Ahora!',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          onPressed: onAdd,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ADD MILESTONE SHEET - Bottom sheet para agregar hito
// ============================================================================
class _AddMilestoneSheet extends StatefulWidget {
  const _AddMilestoneSheet({
    required this.appState,
    required this.themeColor,
    required this.accentColor,
    required this.onSave,
    this.template,
  });

  final AppState appState;
  final Milestone? template;
  final Color themeColor;
  final Color accentColor;
  final Function(Milestone) onSave;

  @override
  State<_AddMilestoneSheet> createState() => _AddMilestoneSheetState();
}

class _AddMilestoneSheetState extends State<_AddMilestoneSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  DateTime _selectedDate = DateTime.now();
  Uint8List? _photoBytes;
  bool _isCustom = false;

  @override
  void initState() {
    super.initState();
    if (widget.template == null) {
      _isCustom = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() => _photoBytes = bytes);
    } catch (_) {}
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera, color: widget.accentColor),
              title: Text(widget.appState.tr('take_photo')),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: widget.accentColor),
              title: Text(widget.appState.tr('choose_gallery')),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: widget.appState.locale,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _save() {
    final title = _isCustom ? _titleController.text.trim() : null;
    if (_isCustom && title!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.appState.tr('milestone_title')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final milestone = Milestone(
      id: _isCustom
          ? 'custom_${DateTime.now().millisecondsSinceEpoch}'
          : widget.template!.id,
      titleKey: _isCustom ? 'special_moment' : widget.template!.titleKey,
      customTitle: _isCustom ? title : null,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      date: _selectedDate,
      photoBase64: _photoBytes != null ? base64Encode(_photoBytes!) : null,
      minAgeMonths: _isCustom ? 0 : widget.template!.minAgeMonths,
      maxAgeMonths: _isCustom ? 120 : widget.template!.maxAgeMonths,
      iconName: _isCustom ? 'star' : widget.template!.iconName,
      category: _isCustom ? MilestoneCategory.special : widget.template!.category,
      isCompleted: true,
    );

    widget.onSave(milestone);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.template != null
        ? widget.appState.tr(widget.template!.titleKey)
        : widget.appState.tr('custom_milestone');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.themeColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.template?.icon ?? Icons.star,
                    color: widget.accentColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _isCustom ? widget.appState.tr('custom_milestone') : title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: widget.accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Foto
            GestureDetector(
              onTap: _showPhotoOptions,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: widget.themeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.accentColor.withValues(alpha: 0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _photoBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.memory(_photoBytes!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 48,
                            color: widget.accentColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.appState.tr('add_photo'),
                            style: TextStyle(
                              color: widget.accentColor.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // Título personalizado
            if (_isCustom) ...[
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: widget.appState.tr('milestone_title'),
                  labelStyle: TextStyle(color: widget.accentColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.accentColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Descripción
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: widget.appState.tr('milestone_description'),
                labelStyle: TextStyle(color: widget.accentColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.accentColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Fecha
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: widget.accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.appState.tr('milestone_date'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            DateFormat('dd MMMM yyyy', widget.appState.locale.languageCode)
                                .format(_selectedDate),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: widget.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: widget.accentColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Botón guardar
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                widget.appState.tr('save'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MILESTONE DETAIL PAGE - Página de detalle del hito
// ============================================================================
class _MilestoneDetailPage extends StatelessWidget {
  const _MilestoneDetailPage({
    required this.milestone,
    required this.appState,
    required this.themeColor,
    required this.accentColor,
    required this.babyName,
  });

  final Milestone milestone;
  final AppState appState;
  final Color themeColor;
  final Color accentColor;
  final String babyName;

  @override
  Widget build(BuildContext context) {
    final title = milestone.customTitle ?? appState.tr(milestone.titleKey);
    final dateStr = milestone.date != null
        ? DateFormat('dd MMMM yyyy', appState.locale.languageCode).format(milestone.date!)
        : '';
    final hasPhoto = milestone.photoBase64 != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      body: CustomScrollView(
        slivers: [
          // AppBar con foto
          SliverAppBar(
            expandedHeight: hasPhoto ? 350 : 200,
            pinned: true,
            backgroundColor: themeColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: accentColor),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: hasPhoto
                  ? Image.memory(
                      base64Decode(milestone.photoBase64!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [themeColor.withValues(alpha: 0.5), themeColor],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          milestone.icon,
                          size: 100,
                          color: accentColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
            ),
          ),
          // Contenido
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              transform: Matrix4.translationValues(0, -30, 0),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono y título
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(milestone.icon, color: accentColor, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                              ),
                            ),
                            if (dateStr.isNotEmpty)
                              Text(
                                '📅 $dateStr',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Descripción
                  if (milestone.description != null &&
                      milestone.description!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📝 Nota',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            milestone.description!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4F4A4A),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Footer cute
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '💕 Recuerdo especial de $babyName 💕',
                        style: TextStyle(
                          fontSize: 14,
                          color: accentColor,
                          fontWeight: FontWeight.w500,
                        ),
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

// ============================================================================
// CAREGIVERS SECTION - Sección de cuidadores en la pantalla de inicio
// ============================================================================
class CaregiversSection extends StatefulWidget {
  const CaregiversSection({super.key});

  @override
  State<CaregiversSection> createState() => _CaregiversSectionState();
}

class _CaregiversSectionState extends State<CaregiversSection> {
  List<Caregiver> _caregivers = [];

  @override
  void initState() {
    super.initState();
    _loadCaregivers();
  }

  Future<void> _loadCaregivers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('caregivers_json');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        setState(() {
          _caregivers = list
              .map((e) => Caregiver.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      } catch (_) {}
    }
  }

  Future<void> _saveCaregivers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'caregivers_json',
      jsonEncode(_caregivers.map((c) => c.toJson()).toList()),
    );
  }

  void _showAddCaregiver() async {
    final result = await showModalBottomSheet<Caregiver>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddCaregiverBottomSheet(),
    );
    if (result != null) {
      setState(() => _caregivers.add(result));
      await _saveCaregivers();
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appState.tr('caregiver_added'))),
        );
      }
    }
  }

  void _showCaregiverOptions(Caregiver caregiver) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252540) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              caregiver.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF4F4A4A),
              ),
            ),
            Text(
              caregiver.role,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                appState.tr('delete_caregiver'),
                style: const TextStyle(color: Colors.red),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: Text(appState.tr('delete_caregiver')),
                    content:
                        Text(appState.tr('delete_caregiver_confirm')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(d, false),
                        child: Text(appState.tr('cancel')),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(d, true),
                        child: Text(appState.tr('delete')),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && mounted) {
                  setState(() =>
                      _caregivers.removeWhere((c) => c.id == caregiver.id));
                  await _saveCaregivers();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(appState.tr('caregiver_deleted'))),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              appState.tr('caregivers'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 22,
                  ),
            ),
            TextButton.icon(
              onPressed: _showAddCaregiver,
              icon: const Icon(Icons.add, size: 18),
              label: Text(appState.tr('add_caregiver')),
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? const Color(0xFFB6D7A8)
                    : const Color(0xFF4F7A4A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_caregivers.isEmpty)
          GestureDetector(
            onTap: _showAddCaregiver,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF252540)
                    : const Color(0xFFEBF7E8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFB6D7A8).withValues(alpha: 0.3)
                      : const Color(0xFFB6D7A8),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFB6D7A8).withValues(alpha: 0.15)
                          : const Color(0xFFB6D7A8).withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1,
                      color: Color(0xFF4F7A4A),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      appState.tr('no_caregivers'),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF6E8F6A),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color:
                        isDark ? Colors.white38 : const Color(0xFFB6D7A8),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._caregivers.map((c) => _buildCaregiverAvatar(c, isDark)),
                _buildAddButton(isDark),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCaregiverAvatar(Caregiver c, bool isDark) {
    Uint8List? photoBytes;
    if (c.photoBase64 != null && c.photoBase64!.isNotEmpty) {
      try {
        photoBytes = base64Decode(c.photoBase64!);
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => _showCaregiverOptions(c),
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isDark
                  ? const Color(0xFF4F7A4A)
                  : const Color(0xFFB6D7A8),
              backgroundImage:
                  photoBytes != null ? MemoryImage(photoBytes) : null,
              child: photoBytes == null
                  ? Text(
                      c.name.isNotEmpty
                          ? c.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              c.name.split(' ').first,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? Colors.white70 : const Color(0xFF4F4A4A),
              ),
            ),
            Text(
              c.role,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? Colors.white38
                    : const Color(0xFF6E8F6A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(bool isDark) {
    return GestureDetector(
      onTap: _showAddCaregiver,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isDark
                  ? const Color(0xFF252540)
                  : const Color(0xFFEBF7E8),
              child: Icon(
                Icons.add,
                color: isDark
                    ? const Color(0xFFB6D7A8)
                    : const Color(0xFF4F7A4A),
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Agregar',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFFB6D7A8)
                    : const Color(0xFF4F7A4A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ADD CAREGIVER BOTTOM SHEET
// ============================================================================
class AddCaregiverBottomSheet extends StatefulWidget {
  const AddCaregiverBottomSheet({super.key});

  @override
  State<AddCaregiverBottomSheet> createState() =>
      _AddCaregiverBottomSheetState();
}

class _AddCaregiverBottomSheetState extends State<AddCaregiverBottomSheet> {
  final _nameController = TextEditingController();
  String _selectedRole = 'Mamá';
  Uint8List? _photoBytes;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> _roles = [
    {'key': 'role_mom', 'label': 'Mamá'},
    {'key': 'role_dad', 'label': 'Papá'},
    {'key': 'role_grandparent', 'label': 'Abuelo/a'},
    {'key': 'role_nanny', 'label': 'Niñera'},
    {'key': 'role_other', 'label': 'Otro'},
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar rol traducido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        setState(() {
          _selectedRole = appState.tr('role_mom');
          for (final r in _roles) {
            r['label'] = appState.tr(r['key']!);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked =
          await _picker.pickImage(source: source, imageQuality: 75);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() => _photoBytes = bytes);
    } catch (_) {}
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final caregiver = Caregiver(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      role: _selectedRole,
      photoBase64:
          _photoBytes != null ? base64Encode(_photoBytes!) : null,
    );
    Navigator.of(context).pop(caregiver);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            appState.tr('add_caregiver'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF4F4A4A),
            ),
          ),
          const SizedBox(height: 20),

          // Photo + name row
          Row(
            children: [
              GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: isDark
                          ? const Color(0xFF4F7A4A)
                          : const Color(0xFFB6D7A8),
                      backgroundImage: _photoBytes != null
                          ? MemoryImage(_photoBytes!)
                          : null,
                      child: _photoBytes == null
                          ? const Icon(Icons.person,
                              size: 32, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4F7A4A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: appState.tr('caregiver_name'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark
                              ? Colors.white24
                              : Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF4F7A4A), width: 2),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1A1A2E)
                        : const Color(0xFFF5FFF3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Role label
          Text(
            appState.tr('caregiver_role'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF4F4A4A),
            ),
          ),
          const SizedBox(height: 10),

          // Role chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _roles.map((r) {
              final label = r['label']!;
              final selected = _selectedRole == label;
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => setState(() => _selectedRole = label),
                selectedColor: const Color(0xFF4F7A4A),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : null,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor:
                    isDark ? const Color(0xFF1A1A2E) : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F7A4A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                appState.tr('save'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleSectionScaffold extends StatelessWidget {
  const _SimpleSectionScaffold({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB6D7A8),
        title: Text(title),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.1),
            radius: 1.1,
            colors: [
              Color(0xFFE8F7E4),
              Color(0xFFCFE8C9),
              Color(0xFFB6D7A8),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 56,
                  color: const Color(0xFF4F7A4A),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F7A4A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6E8F6A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfantRegistrationPage extends StatefulWidget {
  const InfantRegistrationPage({super.key});

  @override
  State<InfantRegistrationPage> createState() => _InfantRegistrationPageState();
}

class _InfantRegistrationPageState extends State<InfantRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _secondNameController = TextEditingController();
  final _thirdNameController = TextEditingController();
  DateTime? _birthDate;
  String? _gender;
  int _babiesCount = 1; // 1, 2 (gemelos), 3 (trillizos)

  final ImagePicker _picker = ImagePicker();
  Uint8List? _photoBytes;

  @override
  void dispose() {
    _nameController.dispose();
    _secondNameController.dispose();
    _thirdNameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _photoBytes = bytes;
      });
    } catch (_) {
      // En caso de error simplemente no actualizamos la foto.
    }
  }

  Future<void> _pickBirthDate() async {
    // Diferir para evitar conflicto con Navigator lock
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final now = DateTime.now();
    final initialDate = _birthDate ?? now;
    // Permite registrar bebés/niños hasta 10 años atrás
    final firstDate = DateTime(now.year - 10);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now,
      helpText: 'Fecha de nacimiento del bebé',
      locale: const Locale('es', ''),
    );

    if (picked != null && mounted) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _birthDate == null || _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los datos del bebé.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    
    // Debug: mostrar qué se está guardando
    debugPrint('=== InfantRegistrationPage._submit ===');
    debugPrint('Guardando: name=${_nameController.text.trim()}, gender=$_gender, birthDate=$_birthDate');
    
    await prefs.setBool('has_infant_profile', true);
    await prefs.setString('infant_name', _nameController.text.trim());
    if (_babiesCount >= 2) {
      await prefs.setString('infant2_name', _secondNameController.text.trim());
    } else {
      await prefs.remove('infant2_name');
    }
    if (_babiesCount >= 3) {
      await prefs.setString('infant3_name', _thirdNameController.text.trim());
    } else {
      await prefs.remove('infant3_name');
    }
    await prefs.setString('infant_gender', _gender!);
    await prefs.setString('infant_birthdate', _birthDate!.toIso8601String());
    if (_photoBytes != null) {
      await prefs.setString('infant_photo', base64Encode(_photoBytes!));
    }

    if (!mounted) return;

    // Navegar a registro facial
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const FaceRegistrationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.1),
            radius: 1.1,
            colors: [
              Color(0xFFE8F7E4),
              Color(0xFFCFE8C9),
              Color(0xFFB6D7A8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: const [
                    Text(
                      'KOA',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Color(0xFF4F7A4A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tu acompañante en el cuidado de tu bebé',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6E8F6A),
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
                Text(
                  'Registra a tu bebé',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Foto del infante
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFFE8F7E4),
                              backgroundImage:
                                  _photoBytes != null ? MemoryImage(_photoBytes!) : null,
                              child: _photoBytes == null
                                  ? const Icon(
                                      Icons.child_care,
                                      size: 40,
                                      color: Color(0xFF4F7A4A),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _pickPhoto(ImageSource.camera),
                                  icon: const Icon(Icons.photo_camera),
                                  label: const Text('Tomar foto'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _pickPhoto(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Elegir foto'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del bebé',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el nombre.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Número de bebés:'),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: _babiesCount,
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('1')),
                              DropdownMenuItem(value: 2, child: Text('Gemelos')),
                              DropdownMenuItem(value: 3, child: Text('Trillizos')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _babiesCount = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      if (_babiesCount >= 2) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _secondNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del bebé 2',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (_babiesCount >= 2 && (value == null || value.trim().isEmpty)) {
                              return 'Ingresa el nombre del bebé 2.';
                            }
                            return null;
                          },
                        ),
                      ],
                      if (_babiesCount >= 3) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _thirdNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del bebé 3',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (_babiesCount >= 3 && (value == null || value.trim().isEmpty)) {
                              return 'Ingresa el nombre del bebé 3.';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickBirthDate,
                        borderRadius: BorderRadius.circular(16),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de nacimiento',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _birthDate == null
                                    ? 'Selecciona la fecha'
                                    : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                                style: TextStyle(
                                  color: _birthDate == null
                                      ? Colors.grey[600]
                                      : Colors.black87,
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Género',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'femenino',
                            child: Text('Femenino'),
                          ),
                          DropdownMenuItem(
                            value: 'masculino',
                            child: Text('Masculino'),
                          ),
                          DropdownMenuItem(
                            value: 'otro',
                            child: Text('Otro / Prefiero no decir'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _gender = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Selecciona una opción.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB6D7A8),
                            foregroundColor: const Color(0xFF355334),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _submit,
                          child: const Text(
                            'Guardar perfil',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
