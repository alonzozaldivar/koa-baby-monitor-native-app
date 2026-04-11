// ============================================================================
// KOA POINTS SERVICE - Sistema de puntos y recompensas KOA
// ============================================================================
// 1 punto KOA = MXN $1 de descuento en la Tienda KOA
// 25 puntos mínimo para canjear en la tienda
// ============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KoaPointsEntry {
  final int amount;
  final String reason;
  final DateTime date;
  final bool isEarned; // true = ganado, false = canjeado

  KoaPointsEntry({
    required this.amount,
    required this.reason,
    required this.date,
    required this.isEarned,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'reason': reason,
        'date': date.toIso8601String(),
        'isEarned': isEarned,
      };

  factory KoaPointsEntry.fromJson(Map<String, dynamic> json) => KoaPointsEntry(
        amount: json['amount'] as int,
        reason: json['reason'] as String,
        date: DateTime.parse(json['date'] as String),
        isEarned: json['isEarned'] as bool,
      );
}

class KoaPointsService {
  static const String _balanceKey = 'koa_points_balance';
  static const String _historyKey = 'koa_points_history';
  static const String _lastBonusKey = 'koa_points_last_daily_bonus';

  // ── Cuánto vale cada acción ───────────────────────────────────────────────
  static const int ptsFeeding      = 1;  // Registrar toma
  static const int ptsSleep        = 1;  // Sesión de sueño completada
  static const int ptsVaccine      = 2;  // Marcar vacuna aplicada
  static const int ptsAppointment  = 2;  // Agendar cita médica
  static const int ptsMeasurement  = 2;  // Registrar medición de peso/talla
  static const int ptsMilestone    = 3;  // Agregar hito al diario
  static const int ptsDailyBonus   = 1;  // Bono diario de bienvenida
  static const int ptsProfile      = 5;  // Crear perfil de bebé (primera vez)

  // ── Costo de los premios ──────────────────────────────────────────────────
  static const int costDiscount25   = 25;   // MXN $25 descuento en Premium
  static const int costDiscount50   = 50;   // MXN $50 descuento en Premium
  static const int costMonthFree    = 199;  // 1 mes Premium gratis
  static const int costYearDiscount = 100;  // 10% descuento en Plan Anual

  // =========================================================================
  // CONSULTAR SALDO
  // =========================================================================

  static Future<int> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_balanceKey) ?? 0;
  }

  // =========================================================================
  // GANAR PUNTOS
  // =========================================================================

  static Future<int> addPoints(int amount, String reason) async {
    if (amount <= 0) return await getBalance();
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_balanceKey) ?? 0;
    final newBalance = current + amount;
    await prefs.setInt(_balanceKey, newBalance);
    await _addHistoryEntry(KoaPointsEntry(
      amount: amount,
      reason: reason,
      date: DateTime.now(),
      isEarned: true,
    ));
    debugPrint('⭐ KOA Puntos +$amount ($reason) → Total: $newBalance');
    return newBalance;
  }

  // =========================================================================
  // CANJEAR PUNTOS
  // =========================================================================

  /// Retorna true si el canje fue exitoso, false si no hay suficientes puntos.
  static Future<bool> redeemPoints(int cost, String reward) async {
    final balance = await getBalance();
    if (balance < cost) {
      debugPrint('❌ KOA Puntos insuficientes: tienes $balance, necesitas $cost');
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    final newBalance = balance - cost;
    await prefs.setInt(_balanceKey, newBalance);
    await _addHistoryEntry(KoaPointsEntry(
      amount: cost,
      reason: reward,
      date: DateTime.now(),
      isEarned: false,
    ));
    debugPrint('🎁 KOA Puntos canjeados: -$cost ($reward) → Total: $newBalance');
    return true;
  }

  // =========================================================================
  // BONO DIARIO
  // =========================================================================

  /// Reclama el bono diario. Retorna los puntos ganados (0 si ya fue reclamado hoy).
  static Future<int> claimDailyBonus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBonus = prefs.getString(_lastBonusKey);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    if (lastBonus == todayStr) {
      return 0; // Ya reclamado hoy
    }

    await prefs.setString(_lastBonusKey, todayStr);
    await addPoints(ptsDailyBonus, 'Bono diario de bienvenida');
    return ptsDailyBonus;
  }

  /// Verifica si el bono diario está disponible hoy.
  static Future<bool> isDailyBonusAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBonus = prefs.getString(_lastBonusKey);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    return lastBonus != todayStr;
  }

  // =========================================================================
  // HISTORIAL
  // =========================================================================

  static Future<List<KoaPointsEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final list = jsonDecode(jsonString) as List;
      return list
          .map((e) => KoaPointsEntry.fromJson(e as Map<String, dynamic>))
          .toList()
          .reversed
          .toList(); // más recientes primero
    } catch (e) {
      return [];
    }
  }

  static Future<void> _addHistoryEntry(KoaPointsEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    final list = <Map<String, dynamic>>[];
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        list.addAll((jsonDecode(jsonString) as List).cast<Map<String, dynamic>>());
      } catch (_) {}
    }
    list.add(entry.toJson());
    // Mantener solo los últimos 50 registros
    if (list.length > 50) list.removeRange(0, list.length - 50);
    await prefs.setString(_historyKey, jsonEncode(list));
  }

  // =========================================================================
  // UTILIDADES
  // =========================================================================

  /// Texto descriptivo del saldo.
  static String balanceLabel(int balance) {
    if (balance == 0) return 'Sin puntos aún';
    if (balance == 1) return '1 KOA Punto';
    return '$balance KOA Puntos';
  }

  /// Color según el saldo.
  static bool canRedeem(int balance) => balance >= costDiscount25;
}
