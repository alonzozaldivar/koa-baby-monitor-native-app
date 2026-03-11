// ============================================================================
// APP MODELS - Modelos para todas las entidades de la app
// ============================================================================

// ============================================================================
// FEEDING ENTRY MODEL
// ============================================================================
class FeedingEntry {
  final String id;
  final String babyId;
  final String userId;
  final String type; // 'breast', 'bottle', 'solid'
  final String? amount;
  final String? notes;
  final DateTime timestamp;

  FeedingEntry({
    required this.id,
    required this.babyId,
    required this.userId,
    required this.type,
    this.amount,
    this.notes,
    required this.timestamp,
  });

  factory FeedingEntry.fromJson(Map<String, dynamic> json) => FeedingEntry(
        id: json['id'],
        babyId: json['baby_id'],
        userId: json['user_id'],
        type: json['type'],
        amount: json['amount'],
        notes: json['notes'],
        timestamp: DateTime.parse(json['timestamp']),
      );

  Map<String, dynamic> toJson() => {
        'baby_id': babyId,
        'user_id': userId,
        'type': type,
        'amount': amount,
        'notes': notes,
        'timestamp': timestamp.toIso8601String(),
      };
}

// ============================================================================
// MEDICAL APPOINTMENT MODEL
// ============================================================================
class MedicalAppointment {
  final String id;
  final String babyId;
  final String userId;
  final String title;
  final String? doctorName;
  final DateTime date;
  final String? notes;
  final bool completed;

  MedicalAppointment({
    required this.id,
    required this.babyId,
    required this.userId,
    required this.title,
    this.doctorName,
    required this.date,
    this.notes,
    this.completed = false,
  });

  factory MedicalAppointment.fromJson(Map<String, dynamic> json) =>
      MedicalAppointment(
        id: json['id'],
        babyId: json['baby_id'],
        userId: json['user_id'],
        title: json['title'],
        doctorName: json['doctor_name'],
        date: DateTime.parse(json['date']),
        notes: json['notes'],
        completed: json['completed'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'baby_id': babyId,
        'user_id': userId,
        'title': title,
        'doctor_name': doctorName,
        'date': date.toIso8601String(),
        'notes': notes,
        'completed': completed,
      };
}

// ============================================================================
// MEDICINE MODEL
// ============================================================================
class Medicine {
  final String id;
  final String babyId;
  final String userId;
  final String name;
  final String? dosage;
  final String? frequency;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? times;
  final bool active;

  Medicine({
    required this.id,
    required this.babyId,
    required this.userId,
    required this.name,
    this.dosage,
    this.frequency,
    this.startDate,
    this.endDate,
    this.times,
    this.active = true,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
        id: json['id'],
        babyId: json['baby_id'],
        userId: json['user_id'],
        name: json['name'],
        dosage: json['dosage'],
        frequency: json['frequency'],
        startDate: json['start_date'] != null
            ? DateTime.parse(json['start_date'])
            : null,
        endDate:
            json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
        times: json['times'] != null
            ? List<String>.from(json['times'])
            : null,
        active: json['active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'baby_id': babyId,
        'user_id': userId,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'start_date': startDate?.toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'times': times,
        'active': active,
      };
}

// ============================================================================
// VACCINE RECORD MODEL
// ============================================================================
class VaccineRecord {
  final String id;
  final String babyId;
  final String userId;
  final String vaccineId;
  final String vaccineName;
  final bool applied;
  final DateTime? dateApplied;

  VaccineRecord({
    required this.id,
    required this.babyId,
    required this.userId,
    required this.vaccineId,
    required this.vaccineName,
    this.applied = false,
    this.dateApplied,
  });

  factory VaccineRecord.fromJson(Map<String, dynamic> json) => VaccineRecord(
        id: json['id'],
        babyId: json['baby_id'],
        userId: json['user_id'],
        vaccineId: json['vaccine_id'],
        vaccineName: json['vaccine_name'],
        applied: json['applied'] ?? false,
        dateApplied: json['date_applied'] != null
            ? DateTime.parse(json['date_applied'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'baby_id': babyId,
        'user_id': userId,
        'vaccine_id': vaccineId,
        'vaccine_name': vaccineName,
        'applied': applied,
        'date_applied': dateApplied?.toIso8601String().split('T')[0],
      };
}

// ============================================================================
// SLEEP SESSION MODEL  
// ============================================================================
class SleepSessionModel {
  final String id;
  final String babyId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;

  SleepSessionModel({
    required this.id,
    required this.babyId,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
  });

  factory SleepSessionModel.fromJson(Map<String, dynamic> json) =>
      SleepSessionModel(
        id: json['id'],
        babyId: json['baby_id'],
        userId: json['user_id'],
        startTime: DateTime.parse(json['start_time']),
        endTime:
            json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
        durationMinutes: json['duration_minutes'],
      );

  Map<String, dynamic> toJson() => {
        'baby_id': babyId,
        'user_id': userId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'duration_minutes': durationMinutes,
      };

  bool get isOngoing => endTime == null;
}

// ============================================================================
// DIARY MILESTONE MODEL
// ============================================================================
class DiaryMilestone {
  final String id;
  final String babyId;
  final String userId;
  final String title;
  final String? description;
  final DateTime date;
  final String? photoUrl;

  DiaryMilestone({
    required this.id,
    required this.babyId,
    required this.userId,
    required this.title,
    this.description,
    required this.date,
    this.photoUrl,
  });

  factory DiaryMilestone.fromJson(Map<String, dynamic> json) => DiaryMilestone(
        id: json['id'],
        babyId: json['baby_id'],
        userId: json['user_id'],
        title: json['title'],
        description: json['description'],
        date: DateTime.parse(json['date']),
        photoUrl: json['photo_url'],
      );

  Map<String, dynamic> toJson() => {
        'baby_id': babyId,
        'user_id': userId,
        'title': title,
        'description': description,
        'date': date.toIso8601String().split('T')[0],
        'photo_url': photoUrl,
      };
}

// ============================================================================
// CAMERA CONFIG MODEL (for Supabase)
// ============================================================================
class CameraConfigModel {
  final String id;
  final String userId;
  final String name;
  final String host;
  final String protocol; // 'rtsp' or 'http'
  final int rtspPort;
  final String rtspPath;
  final int httpPort;
  final String httpPath;
  final String? username;
  final String? password;
  final bool hasPTZ;
  final bool hasAudio;

  CameraConfigModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.host,
    this.protocol = 'rtsp',
    this.rtspPort = 554,
    this.rtspPath = '/stream1',
    this.httpPort = 4747,
    this.httpPath = '/video',
    this.username,
    this.password,
    this.hasPTZ = true,
    this.hasAudio = true,
  });

  factory CameraConfigModel.fromJson(Map<String, dynamic> json) =>
      CameraConfigModel(
        id: json['id'],
        userId: json['user_id'],
        name: json['name'],
        host: json['host'],
        protocol: json['protocol'] ?? 'rtsp',
        rtspPort: json['rtsp_port'] ?? 554,
        rtspPath: json['rtsp_path'] ?? '/stream1',
        httpPort: json['http_port'] ?? 4747,
        httpPath: json['http_path'] ?? '/video',
        username: json['username'],
        password: json['password'],
        hasPTZ: json['has_ptz'] ?? true,
        hasAudio: json['has_audio'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'host': host,
        'protocol': protocol,
        'rtsp_port': rtspPort,
        'rtsp_path': rtspPath,
        'http_port': httpPort,
        'http_path': httpPath,
        'username': username,
        'password': password,
        'has_ptz': hasPTZ,
        'has_audio': hasAudio,
      };

  String get streamUrl {
    if (protocol == 'http') {
      return 'http://$host:$httpPort$httpPath';
    } else {
      final auth = username != null && username!.isNotEmpty 
          ? '$username:$password@' 
          : '';
      return 'rtsp://$auth$host:$rtspPort$rtspPath';
    }
  }
}

// ============================================================================
// CAREGIVER MODEL
// ============================================================================
class Caregiver {
  final String id;
  final String name;
  final String role; // 'mamá', 'papá', 'abuelo/a', 'niñera', 'otro'
  final String? photoBase64;

  Caregiver({
    required this.id,
    required this.name,
    required this.role,
    this.photoBase64,
  });

  factory Caregiver.fromJson(Map<String, dynamic> json) => Caregiver(
        id: json['id'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        photoBase64: json['photo_base64'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'photo_base64': photoBase64,
      };
}

// ============================================================================
// FACE BIOMETRIC MODEL
// ============================================================================
class FaceBiometric {
  final String id;
  final String userId;
  final Map<String, dynamic> faceEncoding;
  final String? deviceId;
  final DateTime registeredAt;

  FaceBiometric({
    required this.id,
    required this.userId,
    required this.faceEncoding,
    this.deviceId,
    required this.registeredAt,
  });

  factory FaceBiometric.fromJson(Map<String, dynamic> json) => FaceBiometric(
        id: json['id'],
        userId: json['user_id'],
        faceEncoding: json['face_encoding'] as Map<String, dynamic>,
        deviceId: json['device_id'],
        registeredAt: DateTime.parse(json['registered_at']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'face_encoding': faceEncoding,
        'device_id': deviceId,
      };
}
