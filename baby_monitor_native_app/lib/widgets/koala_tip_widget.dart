import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/koala_tips.dart';

/// Widget que muestra un tip del koala según la edad del bebé y la sección actual.
/// Calcula automáticamente la edad del bebé desde SharedPreferences.
class KoalaTipWidget extends StatefulWidget {
  final String section; // 'home', 'food', 'sleep', 'health', 'diary'
  final String languageCode;

  const KoalaTipWidget({
    super.key,
    required this.section,
    required this.languageCode,
  });

  @override
  State<KoalaTipWidget> createState() => _KoalaTipWidgetState();
}

class _KoalaTipWidgetState extends State<KoalaTipWidget>
    with SingleTickerProviderStateMixin {
  KoalaStage? _stage;
  KoalaTipData? _tip;
  String _koalaImage = '';
  String _koalaName = '';
  bool _dismissed = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _loadTip();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadTip() async {
    final prefs = await SharedPreferences.getInstance();
    final birthIso = prefs.getString('infant_birthdate');

    if (birthIso == null) return;

    try {
      final birthDate = DateTime.parse(birthIso);
      final now = DateTime.now();
      final ageInYears = now.difference(birthDate).inDays ~/ 365;

      final stage = KoalaTips.getStage(ageInYears);
      final tip = KoalaTips.getTip(widget.section, stage);
      final image = KoalaTips.getKoalaImage(stage);
      final nameMap = KoalaTips.getKoalaName(stage);
      final name = widget.languageCode == 'es'
          ? nameMap['es']!
          : nameMap['en']!;

      if (tip != null && mounted) {
        setState(() {
          _stage = stage;
          _tip = tip;
          _koalaImage = image;
          _koalaName = name;
        });
        _animController.forward();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_tip == null || _dismissed) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tipText = widget.languageCode == 'es' ? _tip!.tipEs : _tip!.tipEn;

    // Color del burbuja según etapa
    final bubbleColor = _stage == KoalaStage.baby
        ? (isDark ? const Color(0xFF2A3A2A) : const Color(0xFFE8F5E9))
        : _stage == KoalaStage.nino
            ? (isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE3F2FD))
            : (isDark ? const Color(0xFF3A2A3A) : const Color(0xFFFFF3E0));

    final borderColor = _stage == KoalaStage.baby
        ? const Color(0xFFB6D7A8)
        : _stage == KoalaStage.nino
            ? const Color(0xFF90CAF9)
            : const Color(0xFFFFCC80);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Koala image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                _koalaImage,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.pets, size: 30, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Tip text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _koalaName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? borderColor : borderColor.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tipText,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            // Dismiss button
            GestureDetector(
              onTap: () => setState(() => _dismissed = true),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: isDark ? Colors.white38 : Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
