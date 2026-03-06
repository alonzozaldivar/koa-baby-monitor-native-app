import 'package:flutter/material.dart';
import '../services/update_service.dart';

// ============================================================================
// UPDATE DIALOG - Diálogo de actualización disponible
// ============================================================================

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  
  const UpdateDialog({super.key, required this.updateInfo});
  
  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.system_update, color: Theme.of(context).primaryColor, size: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Actualización disponible',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Versiones
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Versión actual', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      widget.updateInfo.currentVersion,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward, color: Theme.of(context).primaryColor),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Nueva versión', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      widget.updateInfo.latestVersion,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notas de la versión
          const Text(
            'Novedades:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.updateInfo.releaseNotes,
              style: const TextStyle(fontSize: 14),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Barra de progreso
          if (_isDownloading) ...[
            const SizedBox(height: 16),
            Column(
              children: [
                LinearProgressIndicator(
                  value: _downloadProgress,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Descargando... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ahora no'),
          ),
        if (!_isDownloading)
          ElevatedButton.icon(
            onPressed: _downloadAndInstall,
            icon: const Icon(Icons.download),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }
  
  Future<void> _downloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });
    
    final updateService = UpdateService();
    updateService.onDownloadProgress = (progress) {
      setState(() {
        _downloadProgress = progress;
      });
    };
    
    final success = await updateService.downloadAndInstall(widget.updateInfo.downloadUrl);
    
    if (success && mounted) {
      // Cerrar diálogo después de iniciar instalación
      Navigator.of(context).pop();
      
      // Mostrar mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Actualización lista. Por favor instala el APK descargado.'),
          duration: Duration(seconds: 5),
        ),
      );
    } else if (mounted) {
      setState(() {
        _isDownloading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al descargar la actualización'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ============================================================================
// FUNCIÓN HELPER - Mostrar diálogo de actualización
// ============================================================================

Future<void> showUpdateDialog(BuildContext context, UpdateInfo updateInfo) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => UpdateDialog(updateInfo: updateInfo),
  );
}
