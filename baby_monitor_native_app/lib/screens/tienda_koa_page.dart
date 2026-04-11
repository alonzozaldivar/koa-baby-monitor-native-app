// ============================================================================
// TIENDA KOA - Pantalla de KOA Puntos y recompensas
// ============================================================================
import 'package:flutter/material.dart';
import '../services/koa_points_service.dart';
import '../services/subscription_service.dart';

class TiendaKoaPage extends StatefulWidget {
  const TiendaKoaPage({super.key});

  @override
  State<TiendaKoaPage> createState() => _TiendaKoaPageState();
}

class _TiendaKoaPageState extends State<TiendaKoaPage>
    with SingleTickerProviderStateMixin {
  int _balance = 0;
  bool _dailyBonusAvailable = false;
  List<KoaPointsEntry> _history = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final balance = await KoaPointsService.getBalance();
    final bonusAvailable = await KoaPointsService.isDailyBonusAvailable();
    final history = await KoaPointsService.getHistory();
    if (mounted) {
      setState(() {
        _balance = balance;
        _dailyBonusAvailable = bonusAvailable;
        _history = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _claimDailyBonus() async {
    final earned = await KoaPointsService.claimDailyBonus();
    if (earned > 0) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⭐ +$earned KOA Punto ganado. ¡Vuelve mañana!'),
            backgroundColor: const Color(0xFF4F7A4A),
          ),
        );
      }
    }
  }

  Future<void> _redeem(int cost, String reward, String successMsg) async {
    if (_balance < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Necesitas $cost puntos. Te faltan ${cost - _balance}.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar canje'),
        content: Text('¿Canjear $cost KOA Puntos por:\n\n$reward?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF355334)),
            child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F7A4A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Canjear'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await KoaPointsService.redeemPoints(cost, reward);
    if (success) {
      // Si es 1 mes gratis, activar premium
      if (cost == KoaPointsService.costMonthFree) {
        await SubscriptionService.activatePremium();
      }
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎁 $successMsg'),
            backgroundColor: const Color(0xFF4F7A4A),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5FFF3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F7A4A),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Text('⭐ ', style: TextStyle(fontSize: 20)),
            Text(
              'Tienda KOA',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Tienda'),
            Tab(text: 'Cómo ganar'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Balance banner
                _buildBalanceBanner(isDark),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStoreTab(isDark),
                      _buildEarnTab(isDark),
                      _buildHistoryTab(isDark),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ── Balance banner ────────────────────────────────────────────────────────
  Widget _buildBalanceBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F7A4A), Color(0xFF7AAD6A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Text('⭐', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_balance',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const Text(
                  'KOA Puntos disponibles',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          // Bono diario
          if (_dailyBonusAvailable)
            ElevatedButton.icon(
              onPressed: _claimDailyBonus,
              icon: const Icon(Icons.card_giftcard, size: 16),
              label: const Text('Bono\ndiario', style: TextStyle(fontSize: 11, height: 1.2)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '✓ Bono\nreclamado',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.2),
              ),
            ),
        ],
      ),
    );
  }

  // ── Tab 1: Tienda / Premios ───────────────────────────────────────────────
  Widget _buildStoreTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🎁 Premios disponibles', isDark),
          const SizedBox(height: 12),
          _buildRewardCard(
            isDark: isDark,
            icon: '💰',
            title: 'MXN \$25 de descuento',
            subtitle: 'Descuento en tu próxima suscripción Premium mensual',
            cost: KoaPointsService.costDiscount25,
            canAfford: _balance >= KoaPointsService.costDiscount25,
            onRedeem: () => _redeem(
              KoaPointsService.costDiscount25,
              'MXN \$25 descuento en Premium',
              '¡Código generado! Aplica MXN \$25 en tu próxima compra.',
            ),
          ),
          _buildRewardCard(
            isDark: isDark,
            icon: '💎',
            title: 'MXN \$50 de descuento',
            subtitle: 'Descuento mayor en suscripción Premium mensual',
            cost: KoaPointsService.costDiscount50,
            canAfford: _balance >= KoaPointsService.costDiscount50,
            onRedeem: () => _redeem(
              KoaPointsService.costDiscount50,
              'MXN \$50 descuento en Premium',
              '¡Código generado! Aplica MXN \$50 en tu próxima compra.',
            ),
          ),
          _buildRewardCard(
            isDark: isDark,
            icon: '🌟',
            title: '1 mes Premium GRATIS',
            subtitle: 'Activa KOA Premium por 1 mes completo sin costo',
            cost: KoaPointsService.costMonthFree,
            canAfford: _balance >= KoaPointsService.costMonthFree,
            isHighlighted: true,
            onRedeem: () => _redeem(
              KoaPointsService.costMonthFree,
              '1 mes Premium gratis',
              '¡Premium activado por 1 mes! Disfruta todas las funciones.',
            ),
          ),
          _buildRewardCard(
            isDark: isDark,
            icon: '📅',
            title: '10% descuento en Plan Anual',
            subtitle: 'Reduce el Plan Anual de MXN \$1,499 a \$1,349',
            cost: KoaPointsService.costYearDiscount,
            canAfford: _balance >= KoaPointsService.costYearDiscount,
            onRedeem: () => _redeem(
              KoaPointsService.costYearDiscount,
              '10% descuento Plan Anual',
              '¡10% de descuento aplicado! Plan Anual: MXN \$1,349.',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252540) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18,
                    color: isDark ? Colors.white60 : Colors.grey[600]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '1 KOA Punto = MXN \$1 de descuento. '
                    'Mínimo 25 puntos para canjear.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard({
    required bool isDark,
    required String icon,
    required String title,
    required String subtitle,
    required int cost,
    required bool canAfford,
    required VoidCallback onRedeem,
    bool isHighlighted = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFF4F7A4A).withOpacity(0.08)
            : isDark
                ? const Color(0xFF252540)
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFF4F7A4A)
              : isDark
                  ? Colors.grey[700]!
                  : Colors.grey[200]!,
          width: isHighlighted ? 1.5 : 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: const Color(0xFF4F7A4A).withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: canAfford
                            ? const Color(0xFF4F7A4A).withOpacity(0.15)
                            : Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '⭐ $cost puntos',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: canAfford
                              ? const Color(0xFF4F7A4A)
                              : Colors.grey,
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: canAfford ? onRedeem : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAfford
                            ? const Color(0xFF4F7A4A)
                            : Colors.grey[300],
                        foregroundColor:
                            canAfford ? Colors.white : Colors.grey[600],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      child: Text(canAfford ? 'Canjear' : 'Sin pts'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Cómo ganar puntos ──────────────────────────────────────────────
  Widget _buildEarnTab(bool isDark) {
    final earning = [
      (_icon('🍼'), 'Registrar una toma', '+${KoaPointsService.ptsFeeding} pto'),
      (_icon('😴'), 'Completar sesión de sueño', '+${KoaPointsService.ptsSleep} pto'),
      (_icon('💉'), 'Marcar vacuna aplicada', '+${KoaPointsService.ptsVaccine} ptos'),
      (_icon('🏥'), 'Agendar cita médica', '+${KoaPointsService.ptsAppointment} ptos'),
      (_icon('📏'), 'Registrar medición', '+${KoaPointsService.ptsMeasurement} ptos'),
      (_icon('📸'), 'Agregar hito al diario', '+${KoaPointsService.ptsMilestone} ptos'),
      (_icon('👶'), 'Crear perfil de bebé', '+${KoaPointsService.ptsProfile} ptos'),
      (_icon('🎁'), 'Bono diario (cada día)', '+${KoaPointsService.ptsDailyBonus} pto'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('⭐ Cómo ganar KOA Puntos', isDark),
          const SizedBox(height: 4),
          Text(
            'Usa la app y acumula puntos automáticamente',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252540) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              children: earning.asMap().entries.map((e) {
                final isLast = e.key == earning.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Text(e.value.$1,
                              style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              e.value.$2,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F7A4A).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              e.value.$3,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4F7A4A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                          height: 1,
                          color: isDark
                              ? Colors.grey[800]
                              : Colors.grey[100]),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Bono diario CTA
          if (_dailyBonusAvailable)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _claimDailyBonus,
                icon: const Icon(Icons.card_giftcard),
                label: const Text('Reclamar bono diario ahora'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _icon(String emoji) => emoji;

  // ── Tab 3: Historial ──────────────────────────────────────────────────────
  Widget _buildHistoryTab(bool isDark) {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Sin movimientos aún',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Empieza a usar KOA para ganar puntos',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[100]),
      itemBuilder: (_, i) {
        final entry = _history[i];
        final isEarned = entry.isEarned;
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: isEarned
                ? const Color(0xFF4F7A4A).withOpacity(0.12)
                : Colors.orange.withOpacity(0.12),
            child: Text(
              isEarned ? '⭐' : '🎁',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          title: Text(
            entry.reason,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            '${entry.date.day}/${entry.date.month}/${entry.date.year}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.grey[500],
            ),
          ),
          trailing: Text(
            '${isEarned ? "+" : "-"}${entry.amount}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isEarned ? const Color(0xFF4F7A4A) : Colors.orange[700],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text, bool isDark) => Text(
        text,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF355334),
        ),
      );
}
