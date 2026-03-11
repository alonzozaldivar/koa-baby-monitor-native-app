import 'package:flutter/material.dart';
import '../services/subscription_service.dart';

class PremiumPaywallPage extends StatelessWidget {
  const PremiumPaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5FFF3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF4F7A4A), Color(0xFFB6D7A8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'KOA Premium',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4F7A4A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Desbloquea todas las funciones para el cuidado completo de tu bebé',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 32),

              // Free plan card
              _PlanCard(
                title: 'Plan Gratuito',
                icon: Icons.favorite_border,
                color: const Color(0xFF78909C),
                features: const [
                  '✅  Perfil del bebé',
                  '✅  Usuario principal',
                  '✅  Registro de comidas',
                  '✅  Seguimiento del sueño',
                  '✅  Medicinas y citas',
                  '✅  Diario de recuerdos',
                  '🔒  Cámara monitor',
                  '🔒  Cartilla de vacunación',
                  '🔒  Llamar al pediatra',
                  '🔒  Agregar cuidadores',
                  '🔒  Registro de actividades',
                  '🔒  Estadísticas',
                ],
                isDark: isDark,
                isCurrent: true,
              ),
              const SizedBox(height: 16),

              // Premium plan card
              _PlanCard(
                title: 'Plan Premium',
                icon: Icons.star_rounded,
                color: const Color(0xFF4F7A4A),
                features: const [
                  '✅  Todo lo del plan gratuito',
                  '✅  Cámara monitor',
                  '✅  Cartilla de vacunación',
                  '✅  Llamar al pediatra',
                  '✅  Agregar cuidadores',
                  '✅  Registro de actividades',
                  '✅  Estadísticas',
                ],
                isDark: isDark,
                isHighlighted: true,
              ),
              const SizedBox(height: 32),

              // Pricing box
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F7A4A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF4F7A4A), width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      'COP 14.900 / mes',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFFB6D7A8)
                            : const Color(0xFF4F7A4A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'o COP 99.900 / año  (ahorra 44%)',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Activate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await SubscriptionService.activatePremium();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              '🎉 ¡Premium activado! Bienvenido a KOA Premium'),
                          backgroundColor: Color(0xFF4F7A4A),
                        ),
                      );
                      Navigator.of(context).pop(true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F7A4A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('🌟  Activar Premium'),
                ),
              ),
              const SizedBox(height: 12),

              // Continue free button
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Continuar con plan gratuito',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El pago será procesado según las políticas de la tienda de aplicaciones.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal plan comparison card widget
// ---------------------------------------------------------------------------
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.features,
    required this.isDark,
    this.isCurrent = false,
    this.isHighlighted = false,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> features;
  final bool isDark;
  final bool isCurrent;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighlighted
            ? color.withOpacity(0.1)
            : isDark
                ? const Color(0xFF252540)
                : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlighted
              ? color
              : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Actual',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              if (isHighlighted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Recomendado',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4F7A4A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Feature list
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                f,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey[800],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
