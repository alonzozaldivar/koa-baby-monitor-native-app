// ============================================================================
// BABY PROFILE MODEL
// ============================================================================
class BabyProfile {
  final String id;
  final String userId;
  final String name;
  final DateTime birthdate;
  final String gender; // 'male', 'female', 'other'
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  BabyProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.birthdate,
    required this.gender,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Crear desde JSON (respuesta de Supabase)
  factory BabyProfile.fromJson(Map<String, dynamic> json) {
    return BabyProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      birthdate: DateTime.parse(json['birthdate'] as String),
      gender: json['gender'] as String,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convertir a JSON (para enviar a Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'birthdate': birthdate.toIso8601String().split('T')[0], // Solo fecha
      'gender': gender,
      'photo_url': photoUrl,
    };
  }

  // Crear copia con cambios
  BabyProfile copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? birthdate,
    String? gender,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BabyProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      birthdate: birthdate ?? this.birthdate,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calcular edad en meses
  int get ageInMonths {
    final now = DateTime.now();
    int months = (now.year - birthdate.year) * 12;
    months += now.month - birthdate.month;
    if (now.day < birthdate.day) months--;
    return months;
  }

  // Calcular edad en días
  int get ageInDays {
    final now = DateTime.now();
    return now.difference(birthdate).inDays;
  }
}
