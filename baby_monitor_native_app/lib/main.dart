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
import 'package:local_auth/local_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:http/http.dart' as http;

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
      'main_sections': {'es': 'Apartados principales', 'en': 'Main sections'},
      'recent_activities': {'es': 'Últimas actividades', 'en': 'Recent activities'},
      'food': {'es': 'Comida', 'en': 'Food'},
      'food_desc': {'es': 'Registro de tomas, horarios y notas sobre la alimentación.', 'en': 'Feeding logs, schedules and nutrition notes.'},
      'camera': {'es': 'Monitor cámara', 'en': 'Camera monitor'},
      'camera_desc': {'es': 'Acceso al monitoreo visual de tu bebé.', 'en': 'Access visual monitoring of your baby.'},
      'health': {'es': 'Salud', 'en': 'Health'},
      'health_desc': {'es': 'Vacunas, peso, citas médicas y más.', 'en': 'Vaccines, weight, medical appointments and more.'},
      'diary': {'es': 'Diario de recuerdos', 'en': 'Memory diary'},
      'diary_desc': {'es': 'Momentos especiales y hitos de tu bebé.', 'en': 'Special moments and milestones.'},
      'activity_log': {'es': 'Registro de actividades', 'en': 'Activity log'},
      'no_activities': {'es': 'Aún no hay actividades registradas.', 'en': 'No activities recorded yet.'},
      'statistics': {'es': 'Estadísticas', 'en': 'Statistics'},
      'coming_soon': {'es': 'Próximamente', 'en': 'Coming soon'},
      'stats_desc': {'es': 'Aquí podrás ver gráficas y resúmenes de las actividades de tu bebé.', 'en': 'Here you will see charts and summaries of your baby\'s activities.'},
      'skip': {'es': 'Saltar', 'en': 'Skip'},
      'months': {'es': 'meses', 'en': 'months'},
      'days': {'es': 'días', 'en': 'days'},
      'old': {'es': 'de edad', 'en': 'old'},
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
    };
    return translations[key]?[isSpanish ? 'es' : 'en'] ?? key;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar MediaKit para streaming RTSP
  MediaKit.ensureInitialized();
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
            home: kIsWeb
                ? const ProfileSelectionPage()
                : const IntroVideoPage(),
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

  void _goNext() {
    if (_hasNavigated && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const ProfileSelectionPage(),
        ),
      );
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
  static const int _requiredFrames = 15; // ~0.5 seconds at 30fps
  bool _hasRegisteredFace = false;

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
    // Si no hay perfil de bebé, ir directo al registro
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

    // Verificar si hay rostro registrado
    final prefs = await SharedPreferences.getInstance();
    _hasRegisteredFace = prefs.getString('user_face_photo') != null;

    if (!_hasRegisteredFace) {
      // Si no hay rostro registrado, ir a registrarlo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const FaceRegistrationPage()),
          );
        }
      });
      return;
    }

    // Hay rostro registrado, iniciar autenticación facial
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
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

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
    setState(() {
      _isVerifying = true;
      _statusMessage = 'verifying';
    });

    await _cameraController?.stopImageStream();

    // Captura la foto actual para comparar
    try {
      final image = await _cameraController?.takePicture();
      if (image == null) {
        throw Exception('No se pudo capturar la imagen');
      }

      // Convertir la imagen capturada a InputImage para ML Kit
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector!.processImage(inputImage);

      if (faces.isEmpty) {
        throw Exception('No se detectó rostro en la captura');
      }

      // Comparar con el rostro registrado
      final prefs = await SharedPreferences.getInstance();
      final registeredFeaturesJson = prefs.getString('user_face_features');
      
      if (registeredFeaturesJson == null) {
        throw Exception('No hay características faciales registradas');
      }

      // Extraer características de la cara actual
      final currentFeatures = _extractFaceFeatures(faces.first);
      
      // Decodificar características registradas
      final registeredFeatures = Map<String, double>.from(
        jsonDecode(registeredFeaturesJson) as Map
      );

      // Comparar características faciales
      final similarity = _compareFaceFeatures(currentFeatures, registeredFeatures);
      
      // Umbral de similitud (0.0 a 1.0, donde 1.0 es idéntico)
      const double similarityThreshold = 0.75;
      
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) return;

      if (similarity >= similarityThreshold) {
        // Rostro verificado - permitir acceso
        setState(() {
          _authSuccess = true;
          _statusMessage = 'auth_success';
        });

        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) _goNext();
      } else {
        // Rostro NO coincide - denegar acceso
        throw Exception('Rostro no autorizado (similitud: ${(similarity * 100).toStringAsFixed(1)}%)');
      }
    } catch (e) {
      debugPrint('Error en verificación facial: $e');
      if (!mounted) return;
      setState(() {
        _authFailed = true;
        _statusMessage = 'auth_failed';
      });
    }
  }

  // Extrae características faciales únicas para comparación
  Map<String, double> _extractFaceFeatures(Face face) {
    final bounds = face.boundingBox;
    
    // Características básicas del rostro
    return {
      'width': bounds.width,
      'height': bounds.height,
      'aspect_ratio': bounds.width / bounds.height,
      'head_euler_y': face.headEulerAngleY ?? 0.0,
      'head_euler_z': face.headEulerAngleZ ?? 0.0,
      // Probabilidades de características (si están disponibles)
      'smiling_prob': face.smilingProbability ?? 0.5,
      'left_eye_open': face.leftEyeOpenProbability ?? 0.5,
      'right_eye_open': face.rightEyeOpenProbability ?? 0.5,
    };
  }

  // Compara dos conjuntos de características faciales
  // Retorna un valor de 0.0 a 1.0 indicando similitud
  double _compareFaceFeatures(Map<String, double> features1, Map<String, double> features2) {
    double totalDifference = 0.0;
    int count = 0;

    // Pesos para diferentes características (algunas son más importantes)
    final weights = {
      'aspect_ratio': 2.0,  // Proporción de la cara es muy importante
      'width': 1.0,
      'height': 1.0,
      'head_euler_y': 0.5,
      'head_euler_z': 0.5,
      'smiling_prob': 0.3,
      'left_eye_open': 0.3,
      'right_eye_open': 0.3,
    };

    for (final key in features1.keys) {
      if (features2.containsKey(key)) {
        final val1 = features1[key]!;
        final val2 = features2[key]!;
        final weight = weights[key] ?? 1.0;
        
        // Normalizar diferencias
        double normalizedDiff;
        if (key == 'aspect_ratio') {
          // Para aspect ratio, diferencias pequeñas son críticas
          normalizedDiff = (val1 - val2).abs() / 2.0;
        } else if (key.contains('euler')) {
          // Ángulos de rotación (normalizar a 0-1)
          normalizedDiff = (val1 - val2).abs() / 360.0;
        } else if (key.contains('prob') || key.contains('open')) {
          // Probabilidades ya están entre 0-1
          normalizedDiff = (val1 - val2).abs();
        } else {
          // Dimensiones (normalizar por la media)
          final mean = (val1 + val2) / 2;
          normalizedDiff = mean > 0 ? (val1 - val2).abs() / mean : 0.0;
        }
        
        totalDifference += normalizedDiff * weight;
        count++;
      }
    }

    if (count == 0) return 0.0;
    
    // Convertir diferencia a similitud (invertir y normalizar a 0-1)
    final avgDifference = totalDifference / count;
    final similarity = 1.0 - avgDifference.clamp(0.0, 1.0);
    
    return similarity.clamp(0.0, 1.0);
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

          // Top bar with title
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _skipAuth,
                      ),
                      const Spacer(),
                      Text(
                        appState.tr('face_auth'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
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
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Extraer características faciales de la imagen capturada
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector!.processImage(inputImage);
      
      if (faces.isEmpty) {
        throw Exception('No se detectó rostro en la captura');
      }

      // Extraer y guardar características del rostro
      final faceFeatures = _extractFaceFeatures(faces.first);
      final featuresJson = jsonEncode(faceFeatures);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_face_photo', base64Image);
      await prefs.setString('user_face_features', featuresJson);

      debugPrint('Rostro registrado con características: $faceFeatures');

      if (mounted) {
        setState(() {
          _registrationSuccess = true;
          _statusMessage = 'face_registered';
        });

        // Navegar después de 1.5 segundos
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNavigationPage()),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error al capturar y guardar rostro: $e');
      if (mounted) {
        setState(() => _statusMessage = 'error_capture');
        // Reintentar
        _startFaceDetection();
      }
    }
  }

  // Extrae características faciales únicas para comparación
  Map<String, double> _extractFaceFeatures(Face face) {
    final bounds = face.boundingBox;
    
    // Características básicas del rostro
    return {
      'width': bounds.width,
      'height': bounds.height,
      'aspect_ratio': bounds.width / bounds.height,
      'head_euler_y': face.headEulerAngleY ?? 0.0,
      'head_euler_z': face.headEulerAngleZ ?? 0.0,
      // Probabilidades de características (si están disponibles)
      'smiling_prob': face.smilingProbability ?? 0.5,
      'left_eye_open': face.leftEyeOpenProbability ?? 0.5,
      'right_eye_open': face.rightEyeOpenProbability ?? 0.5,
    };
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

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

  final List<Widget> _pages = const [
    HomeContent(),
    RegistroPage(),
    StatsPage(),
    SettingsPage(),
  ];

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

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? activeColor : inactiveColor, size: 24),
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
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

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
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CameraMonitorPage()),
                            );
                          },
                        ),
                        KoaFeatureCard(
                          icon: Icons.favorite,
                          title: appState.tr('health'),
                          description: appState.tr('health_desc'),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const HealthPage()),
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
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      appState.tr('recent_activities'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFB6D7A8) : const Color(0xFF4F7A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _RecentActivityList(),
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
// REGISTRO PAGE - Página de registro de actividades
// ============================================================================
class RegistroPage extends StatelessWidget {
  const RegistroPage({super.key});

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
                      appState.tr('activity_log'),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 22,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
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
// STATS PAGE - Página de estadísticas
// ============================================================================
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

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
                      appState.tr('statistics'),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 22,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.bar_chart,
                            size: 64,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            appState.tr('coming_soon'),
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
                              appState.tr('stats_desc'),
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
// SETTINGS PAGE - Página de ajustes
// ============================================================================
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
      // No borramos los datos del perfil, solo cerramos sesión
      // El perfil sigue existiendo para seleccionarlo después
      
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const ProfileSelectionPage(),
          ),
          (route) => false,
        );
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

                    // Sección Cuenta
                    _SectionTitle(title: appState.tr('account')),
                    const SizedBox(height: 8),
                    _SettingsTile(
                      icon: Icons.logout,
                      title: appState.tr('logout'),
                      iconColor: Colors.redAccent,
                      titleColor: Colors.redAccent,
                      onTap: () => _logout(context),
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
        final months = diff.inDays ~/ 30;
        final days = diff.inDays % 30;
        ageText = '$months months, $days days old';
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

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList();

  @override
  Widget build(BuildContext context) {
    // Por ahora es una lista de ejemplo; luego la conectaremos a datos reales.
    final mockItems = [
      'Stella had a wet diaper',
      'Stella nursed (9m left)',
      'Stella slept in her bed (1h 15m)',
      '14 oz expressed (8m)',
    ];

    return Column(
      children: [
        for (final text in mockItems)
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
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4F7A4A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '8:32 AM',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 24 * 2 - 16) / 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB6D7A8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF4F7A4A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F7A4A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6E8F6A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeedingEntry {
  FeedingEntry({
    required this.time,
    required this.amount,
    required this.type,
    this.notes,
  });

  final DateTime time;
  final double amount;
  final String type;
  final String? notes;
}

// Enumeración de etapas de alimentación
enum FeedingStage {
  exclusiveLactation, // 0-6 meses
  complementary,      // 6-12 meses
  transition,         // 12-24 meses
  familyFood,         // 24+ meses
}

// Modelos para la sección de Salud
class MedicalAppointment {
  MedicalAppointment({
    required this.type,
    required this.date,
    required this.time,
    this.notes,
    this.completed = false,
  });

  final String type; // 'Vacuna' o 'Cita médica'
  final DateTime date;
  final TimeOfDay time;
  final String? notes;
  bool completed;
}

class MedicineReminder {
  MedicineReminder({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    this.notes,
  });

  final String name;
  final String dosage;
  final int frequency; // veces al día
  final List<TimeOfDay> times;
  final String? notes;
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
  
  // Datos del bebé
  int _babyAgeInMonths = 0;
  String _babyName = 'tu bebé';
  FeedingStage _stage = FeedingStage.exclusiveLactation;
  List<String> _feedingTypes = [];

  @override
  void initState() {
    super.initState();
    _loadBabyData();
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

  void _addFeeding() {
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

    final next = _nextFeedingTime;
    if (next != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Toma registrada. Próxima toma sugerida a las ${_formatTime(next)}.'),
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
class CameraConfig {
  final String id;
  final String name;
  final String host;
  final int rtspPort;
  final String rtspPath;
  final String username;
  final String password;
  final int onvifPort;
  final bool hasPTZ;
  final bool hasAudio;

  CameraConfig({
    required this.id,
    required this.name,
    required this.host,
    this.rtspPort = 554,
    this.rtspPath = '/stream1',
    this.username = '',
    this.password = '',
    this.onvifPort = 80,
    this.hasPTZ = true,
    this.hasAudio = true,
  });

  String get rtspUrl {
    final auth = username.isNotEmpty ? '$username:$password@' : '';
    return 'rtsp://$auth$host:$rtspPort$rtspPath';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'host': host,
    'rtspPort': rtspPort,
    'rtspPath': rtspPath,
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
    rtspPort: json['rtspPort'] ?? 554,
    rtspPath: json['rtspPath'] ?? '/stream1',
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
      // Crear player y controller
      _player?.dispose();
      _player = Player();
      _videoController = VideoController(_player!);

      // Configurar opciones para RTSP
      await _player!.open(
        Media(_cameraConfig!.rtspUrl),
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
        if (_videoController != null) {
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

  @override
  void initState() {
    super.initState();
    if (widget.existingConfig != null) {
      final c = widget.existingConfig!;
      _nameController.text = c.name;
      _hostController.text = c.host;
      _portController.text = c.rtspPort.toString();
      _pathController.text = c.rtspPath;
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

    final config = CameraConfig(
      id: widget.existingConfig?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      host: _hostController.text.trim(),
      rtspPort: int.tryParse(_portController.text) ?? 554,
      rtspPath: _pathController.text.trim().isEmpty ? '/stream1' : _pathController.text.trim(),
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
            // Puerto y Ruta
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                    controller: _portController,
                    label: tr('rtsp_port'),
                    hint: '554',
                    icon: Icons.numbers,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _pathController,
                    label: tr('rtsp_path'),
                    hint: tr('rtsp_path_hint'),
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
                  const Text(
                    'URL RTSP:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
    final port = _portController.text.isEmpty ? '554' : _portController.text;
    final path = _pathController.text.isEmpty ? '/stream1' : _pathController.text;
    final user = _userController.text;
    final pass = _passController.text;
    final auth = user.isNotEmpty ? '$user:***@' : '';
    return 'rtsp://$auth$host:$port$path';
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
}

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<MedicalAppointment> _appointments = [];
  final List<MedicineReminder> _medicines = [];
  String _pediatricianName = '';
  String _pediatricianPhone = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPediatricianData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPediatricianData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pediatricianName = prefs.getString('pediatrician_name') ?? '';
      _pediatricianPhone = prefs.getString('pediatrician_phone') ?? '';
    });
  }

  Future<void> _savePediatricianData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pediatrician_name', _pediatricianName);
    await prefs.setString('pediatrician_phone', _pediatricianPhone);
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
            Tab(icon: Icon(Icons.phone), text: 'Pediatra'),
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
            _buildPediatricianTab(),
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
            onPressed: () {
              setState(() {
                apt.completed = true;
              });
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
            onPressed: () {
              if (type != null && selectedDate != null && selectedTime != null) {
                setState(() {
                  _appointments.add(MedicalAppointment(
                    type: type!,
                    date: selectedDate!,
                    time: selectedTime!,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  ));
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cita agregada')),
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
                onPressed: () {
                  setState(() => _medicines.remove(med));
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
            onPressed: () {
              if (nameController.text.trim().isNotEmpty &&
                  dosageController.text.trim().isNotEmpty) {
                setState(() {
                  _medicines.add(MedicineReminder(
                    name: nameController.text.trim(),
                    dosage: dosageController.text.trim(),
                    frequency: frequency,
                    times: times,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  ));
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medicamento agregado')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // TAB 3: Pediatra
  Widget _buildPediatricianTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(
                      Icons.medical_services,
                      size: 40,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Mi Pediatra',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4F7A4A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Nombre del pediatra',
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: const Color(0xFFF5FFF3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => _pediatricianName = value,
                    controller: TextEditingController(text: _pediatricianName)
                      ..selection = TextSelection.collapsed(
                          offset: _pediatricianName.length),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Número de teléfono',
                      prefixIcon: const Icon(Icons.phone),
                      filled: true,
                      fillColor: const Color(0xFFF5FFF3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (value) => _pediatricianPhone = value,
                    controller: TextEditingController(text: _pediatricianPhone)
                      ..selection = TextSelection.collapsed(
                          offset: _pediatricianPhone.length),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _savePediatricianData();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Datos guardados')),
                              );
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB6D7A8),
                            foregroundColor: const Color(0xFF355334),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botón de llamada
            if (_pediatricianPhone.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green[400]!,
                      Colors.green[600]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '¿Necesitas ayuda urgente?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _callPediatrician,
                      icon: const Icon(Icons.phone, size: 28),
                      label: Text(
                        _pediatricianName.isEmpty
                            ? 'Llamar al Pediatra'
                            : 'Llamar a $_pediatricianName',
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _callPediatrician() async {
    if (_pediatricianPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Primero ingresa el número del pediatra')),
      );
      return;
    }

    final phoneNumber = _pediatricianPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$phoneNumber');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No se puede realizar la llamada')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al llamar: $e')),
        );
      }
    }
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
