import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Servicio para persistir datos de la aplicación usando SharedPreferences
class StorageService {
  static const String _feedingEntriesKey = 'feeding_entries';
  static const String _appointmentsKey = 'medical_appointments';
  static const String _medicinesKey = 'medicine_reminders';
  static const String _healthMeasurementsKey = 'health_measurements';

  // ========== FEEDING ENTRIES ==========

  /// Guarda todas las entradas de alimentación
  static Future<void> saveFeedingEntries(List<FeedingEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_feedingEntriesKey, jsonEncode(jsonList));
  }

  /// Carga todas las entradas de alimentación guardadas
  static Future<List<FeedingEntry>> loadFeedingEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_feedingEntriesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => FeedingEntry.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error cargando entradas de alimentación: $e');
      return [];
    }
  }

  /// Elimina todas las entradas de alimentación
  static Future<void> clearFeedingEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_feedingEntriesKey);
  }

  // ========== MEDICAL APPOINTMENTS ==========

  /// Guarda todas las citas médicas
  static Future<void> saveAppointments(List<MedicalAppointment> appointments) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = appointments.map((a) => a.toJson()).toList();
    await prefs.setString(_appointmentsKey, jsonEncode(jsonList));
  }

  /// Carga todas las citas médicas guardadas
  static Future<List<MedicalAppointment>> loadAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_appointmentsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => MedicalAppointment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error cargando citas médicas: $e');
      return [];
    }
  }

  /// Elimina todas las citas médicas
  static Future<void> clearAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_appointmentsKey);
  }

  // ========== MEDICINE REMINDERS ==========

  /// Guarda todos los recordatorios de medicamentos
  static Future<void> saveMedicines(List<MedicineReminder> medicines) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = medicines.map((m) => m.toJson()).toList();
    await prefs.setString(_medicinesKey, jsonEncode(jsonList));
  }

  /// Carga todos los recordatorios de medicamentos guardados
  static Future<List<MedicineReminder>> loadMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_medicinesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => MedicineReminder.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error cargando medicamentos: $e');
      return [];
    }
  }

  /// Elimina todos los recordatorios de medicamentos
  static Future<void> clearMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_medicinesKey);
  }

  // ========== HEALTH MEASUREMENTS ==========

  /// Guarda todas las mediciones de salud (peso y talla)
  static Future<void> saveHealthMeasurements(List<HealthMeasurement> measurements) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = measurements.map((m) => m.toJson()).toList();
    await prefs.setString(_healthMeasurementsKey, jsonEncode(jsonList));
  }

  /// Carga todas las mediciones de salud guardadas
  static Future<List<HealthMeasurement>> loadHealthMeasurements() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_healthMeasurementsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => HealthMeasurement.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error cargando mediciones de salud: $e');
      return [];
    }
  }

  /// Elimina todas las mediciones de salud
  static Future<void> clearHealthMeasurements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_healthMeasurementsKey);
  }
}

// ========== MODELOS CON SERIALIZACIÓN ==========

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

  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(),
      'amount': amount,
      'type': type,
      'notes': notes,
    };
  }

  factory FeedingEntry.fromJson(Map<String, dynamic> json) {
    return FeedingEntry(
      time: DateTime.parse(json['time'] as String),
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      notes: json['notes'] as String?,
    );
  }
}

class MedicalAppointment {
  MedicalAppointment({
    required this.type,
    required this.date,
    required this.time,
    this.notes,
    this.completed = false,
    this.notificationId,
  });

  final String type; // 'Vacuna' o 'Cita médica'
  final DateTime date;
  final TimeOfDay time;
  final String? notes;
  bool completed;
  int? notificationId; // ID para cancelar notificación

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'date': date.toIso8601String(),
      'time': '${time.hour}:${time.minute}',
      'notes': notes,
      'completed': completed,
      'notificationId': notificationId,
    };
  }

  factory MedicalAppointment.fromJson(Map<String, dynamic> json) {
    final timeParts = (json['time'] as String).split(':');
    return MedicalAppointment(
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      notes: json['notes'] as String?,
      completed: json['completed'] as bool? ?? false,
      notificationId: json['notificationId'] as int?,
    );
  }
}

class MedicineReminder {
  MedicineReminder({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    this.notes,
    this.notificationIds = const [],
  });

  final String name;
  final String dosage;
  final int frequency; // veces al día
  final List<TimeOfDay> times;
  final String? notes;
  List<int> notificationIds; // IDs para cancelar notificaciones

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times.map((t) => '${t.hour}:${t.minute}').toList(),
      'notes': notes,
      'notificationIds': notificationIds,
    };
  }

  factory MedicineReminder.fromJson(Map<String, dynamic> json) {
    final timesList = (json['times'] as List).cast<String>();
    return MedicineReminder(
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as int,
      times: timesList.map((timeStr) {
        final parts = timeStr.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList(),
      notes: json['notes'] as String?,
      notificationIds: (json['notificationIds'] as List?)?.cast<int>() ?? [],
    );
  }
}

class HealthMeasurement {
  HealthMeasurement({
    required this.date,
    required this.weight,
    required this.height,
    required this.ageInMonths,
  });

  final DateTime date;
  final double weight; // en kilogramos
  final double height; // en centímetros
  final int ageInMonths; // edad al momento de la medición

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'weight': weight,
      'height': height,
      'ageInMonths': ageInMonths,
    };
  }

  factory HealthMeasurement.fromJson(Map<String, dynamic> json) {
    return HealthMeasurement(
      date: DateTime.parse(json['date'] as String),
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      ageInMonths: json['ageInMonths'] as int,
    );
  }
}
