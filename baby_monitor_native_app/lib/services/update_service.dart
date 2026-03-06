import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ============================================================================
// UPDATE SERVICE - Sistema de actualización automática desde GitHub Releases
// ============================================================================

class UpdateService {
  static const String githubRepo = 'alonzozaldivar/koa-baby-monitor-native-app';
  static const String githubApiUrl = 'https://api.github.com/repos/$githubRepo/releases/latest';
  
  final Dio _dio = Dio();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Callback para reportar progreso de descarga
  Function(double)? onDownloadProgress;
  
  UpdateService() {
    _initNotifications();
  }
  
  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }
  
  /// Verifica si hay una actualización disponible
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      // Obtener versión actual de la app
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      debugPrint('📱 Versión actual: $currentVersion');
      
      // Consultar última versión desde GitHub Releases
      final response = await _dio.get(githubApiUrl);
      
      if (response.statusCode == 200) {
        final data = response.data;
        final latestVersion = (data['tag_name'] as String).replaceAll('v', '');
        final downloadUrl = _findApkAsset(data['assets']);
        final releaseNotes = data['body'] as String? ?? 'Nueva versión disponible';
        
        debugPrint('🌐 Versión disponible: $latestVersion');
        
        // Comparar versiones
        if (_isNewerVersion(currentVersion, latestVersion) && downloadUrl != null) {
          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            downloadUrl: downloadUrl,
            releaseNotes: releaseNotes,
          );
        }
      }
      
      debugPrint('✅ App está actualizada');
      return null;
    } catch (e) {
      debugPrint('❌ Error verificando actualizaciones: $e');
      return null;
    }
  }
  
  /// Encuentra el archivo APK en los assets del release
  String? _findApkAsset(List<dynamic> assets) {
    for (var asset in assets) {
      final name = asset['name'] as String;
      if (name.endsWith('.apk') && name.contains('release')) {
        return asset['browser_download_url'] as String;
      }
    }
    return null;
  }
  
  /// Compara dos versiones en formato X.Y.Z
  bool _isNewerVersion(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }
  
  /// Descarga e instala la actualización
  Future<bool> downloadAndInstall(String downloadUrl) async {
    try {
      // Obtener directorio de descargas
      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/koa_update.apk';
      
      debugPrint('⬇️ Descargando actualización...');
      
      // Mostrar notificación de descarga
      await _showNotification(
        'Actualizando KOA',
        'Descargando nueva versión...',
      );
      
      // Descargar APK con progreso
      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onDownloadProgress?.call(progress);
            debugPrint('📥 Progreso: ${(progress * 100).toStringAsFixed(0)}%');
          }
        },
      );
      
      debugPrint('✅ Descarga completada');
      
      // Instalar APK
      await _installApk(filePath);
      return true;
    } catch (e) {
      debugPrint('❌ Error descargando/instalando: $e');
      await _showNotification(
        'Error de actualización',
        'No se pudo descargar la actualización',
      );
      return false;
    }
  }
  
  /// Instala el APK descargado
  Future<void> _installApk(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('APK no encontrado');
      }
      
      await _showNotification(
        'Actualización lista',
        'Toca para instalar',
      );
      
      // En Android, abrir el APK con el instalador del sistema
      if (Platform.isAndroid) {
        // Nota: Requiere configurar FileProvider en AndroidManifest.xml
        final result = await Process.run('am', [
          'start',
          '-a',
          'android.intent.action.VIEW',
          '-d',
          'file://$filePath',
          '-t',
          'application/vnd.android.package-archive',
        ]);
        
        if (result.exitCode != 0) {
          debugPrint('❌ Error instalando: ${result.stderr}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error en instalación: $e');
      rethrow;
    }
  }
  
  /// Muestra una notificación
  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'updates',
      'Actualizaciones',
      channelDescription: 'Notificaciones de actualizaciones de la app',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(0, title, body, details);
  }
}

// ============================================================================
// UPDATE INFO - Información de actualización disponible
// ============================================================================

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  
  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });
  
  @override
  String toString() => 'Actualización: $currentVersion → $latestVersion';
}
