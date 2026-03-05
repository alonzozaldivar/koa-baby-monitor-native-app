// ============================================================================
// SUPABASE SERVICE - Servicio centralizado para todas las operaciones CRUD
// ============================================================================
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/supabase_client.dart';
import '../models/baby_profile.dart';
import '../models/app_models.dart';

class SupabaseService {
  // ============================================================================
  // BABY PROFILES
  // ============================================================================
  
  /// Obtener todos los perfiles de bebés del usuario actual
  static Future<List<BabyProfile>> getBabyProfiles() async {
    try {
      final response = await supabase
          .from('baby_profiles')
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => BabyProfile.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting baby profiles: $e');
      rethrow;
    }
  }

  /// Crear un nuevo perfil de bebé
  static Future<BabyProfile> createBabyProfile(BabyProfile profile) async {
    try {
      final data = profile.toJson();
      data['user_id'] = currentUserId;
      
      final response = await supabase
          .from('baby_profiles')
          .insert(data)
          .select()
          .single();
      
      return BabyProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error creating baby profile: $e');
      rethrow;
    }
  }

  /// Actualizar perfil de bebé
  static Future<BabyProfile> updateBabyProfile(String id, BabyProfile profile) async {
    try {
      final response = await supabase
          .from('baby_profiles')
          .update(profile.toJson())
          .eq('id', id)
          .eq('user_id', currentUserId!)
          .select()
          .single();
      
      return BabyProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error updating baby profile: $e');
      rethrow;
    }
  }

  /// Eliminar perfil de bebé
  static Future<void> deleteBabyProfile(String id) async {
    try {
      await supabase
          .from('baby_profiles')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUserId!);
    } catch (e) {
      debugPrint('Error deleting baby profile: $e');
      rethrow;
    }
  }

  // ============================================================================
  // FEEDING ENTRIES
  // ============================================================================
  
  /// Obtener registros de alimentación de un bebé
  static Future<List<FeedingEntry>> getFeedingEntries(String babyId) async {
    try {
      final response = await supabase
          .from('feeding_entries')
          .select()
          .eq('baby_id', babyId)
          .eq('user_id', currentUserId!)
          .order('timestamp', ascending: false);
      
      return (response as List)
          .map((json) => FeedingEntry.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting feeding entries: $e');
      rethrow;
    }
  }

  /// Crear registro de alimentación
  static Future<FeedingEntry> createFeedingEntry(FeedingEntry entry) async {
    try {
      final data = entry.toJson();
      data['user_id'] = currentUserId;
      
      final response = await supabase
          .from('feeding_entries')
          .insert(data)
          .select()
          .single();
      
      return FeedingEntry.fromJson(response);
    } catch (e) {
      debugPrint('Error creating feeding entry: $e');
      rethrow;
    }
  }

  /// Eliminar registro de alimentación
  static Future<void> deleteFeedingEntry(String id) async {
    try {
      await supabase
          .from('feeding_entries')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUserId!);
    } catch (e) {
      debugPrint('Error deleting feeding entry: $e');
      rethrow;
    }
  }

  // ============================================================================
  // MEDICAL APPOINTMENTS
  // ============================================================================
  
  /// Obtener citas médicas de un bebé
  static Future<List<MedicalAppointment>> getMedicalAppointments(String babyId) async {
    try {
      final response = await supabase
          .from('medical_appointments')
          .select()
          .eq('baby_id', babyId)
          .eq('user_id', currentUserId!)
          .order('date', ascending: true);
      
      return (response as List)
          .map((json) => MedicalAppointment.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting medical appointments: $e');
      rethrow;
    }
  }

  /// Crear cita médica
  static Future<MedicalAppointment> createMedicalAppointment(MedicalAppointment appointment) async {
    try {
      final data = appointment.toJson();
      data['user_id'] = currentUserId;
      
      final response = await supabase
          .from('medical_appointments')
          .insert(data)
          .select()
          .single();
      
      return MedicalAppointment.fromJson(response);
    } catch (e) {
      debugPrint('Error creating medical appointment: $e');
      rethrow;
    }
  }

  /// Actualizar cita médica
  static Future<MedicalAppointment> updateMedicalAppointment(String id, MedicalAppointment appointment) async {
    try {
      final response = await supabase
          .from('medical_appointments')
          .update(appointment.toJson())
          .eq('id', id)
          .eq('user_id', currentUserId!)
          .select()
          .single();
      
      return MedicalAppointment.fromJson(response);
    } catch (e) {
      debugPrint('Error updating medical appointment: $e');
      rethrow;
    }
  }

  /// Eliminar cita médica
  static Future<void> deleteMedicalAppointment(String id) async {
    try {
      await supabase
          .from('medical_appointments')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUserId!);
    } catch (e) {
      debugPrint('Error deleting medical appointment: $e');
      rethrow;
    }
  }

  // ============================================================================
  // MEDICINES
  // ============================================================================
  
  /// Obtener medicamentos de un bebé
  static Future<List<Medicine>> getMedicines(String babyId) async {
    try {
      final response = await supabase
          .from('medicines')
          .select()
          .eq('baby_id', babyId)
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => Medicine.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting medicines: $e');
      rethrow;
    }
  }

  /// Crear medicamento
  static Future<Medicine> createMedicine(Medicine medicine) async {
    try {
      final data = medicine.toJson();
      data['user_id'] = currentUserId;
      
      final response = await supabase
          .from('medicines')
          .insert(data)
          .select()
          .single();
      
      return Medicine.fromJson(response);
    } catch (e) {
      debugPrint('Error creating medicine: $e');
      rethrow;
    }
  }

  /// Actualizar medicamento
  static Future<Medicine> updateMedicine(String id, Medicine medicine) async {
    try {
      final response = await supabase
          .from('medicines')
          .update(medicine.toJson())
          .eq('id', id)
          .eq('user_id', currentUserId!)
          .select()
          .single();
      
      return Medicine.fromJson(response);
    } catch (e) {
      debugPrint('Error updating medicine: $e');
      rethrow;
    }
  }

  /// Eliminar medicamento
  static Future<void> deleteMedicine(String id) async {
    try {
      await supabase
          .from('medicines')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUserId!);
    } catch (e) {
      debugPrint('Error deleting medicine: $e');
      rethrow;
    }
  }

  // ============================================================================
  // VACCINE RECORDS
  // ============================================================================
  
  /// Obtener registros de vacunas de un bebé
  static Future<List<VaccineRecord>> getVaccineRecords(String babyId) async {
    try {
      final response = await supabase
          .from('vaccine_records')
          .select()
          .eq('baby_id', babyId)
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => VaccineRecord.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting vaccine records: $e');
      rethrow;
    }
  }

  /// Crear/actualizar registro de vacuna
  static Future<VaccineRecord> upsertVaccineRecord(VaccineRecord record) async {
    try {
      final data = record.toJson();
      data['user_id'] = currentUserId;
      
      final response = await supabase
          .from('vaccine_records')
          .upsert(data)
          .select()
          .single();
      
      return VaccineRecord.fromJson(response);
    } catch (e) {
      debugPrint('Error upserting vaccine record: $e');
      rethrow;
    }
  }

  // ============================================================================
  // SLEEP SESSIONS
  // ============================================================================
  
  /// Obtener sesiones de sueño de un bebé
  static Future<List<SleepSessionModel>> getSleepSessions(String babyId) async {
    try {
      final response = await supabase
          .from('sleep_sessions')
          .select()
          .eq('baby_id', babyId)
          .eq('user_id', currentUserId!)
          .order('start_time', ascending: false);
      
      return (response as List)
          .map((json) => SleepSessionModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting sleep sessions: $e');
      rethrow;
    }
  }

  /// Crear sesión de sueño
  static Future<SleepSessionModel> createSleepSession(SleepSessionModel session) async {
    try {
      final data = session.toJson();
      data['user_id'] = currentUserId;
      
      final response = await supabase
          .from('sleep_sessions')
          .insert(data)
          .select()
          .single();
      
      return SleepSessionModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating sleep session: $e');
      rethrow;
    }
  }

  /// Actualizar sesión de sueño
  static Future<SleepSessionModel> updateSleepSession(String id, SleepSessionModel session) async {
    try {
      final response = await supabase
          .from('sleep_sessions')
          .update(session.toJson())
          .eq('id', id)
          .eq('user_id', currentUserId!)
          .select()
          .single();
      
      return SleepSessionModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updating sleep session: $e');
      rethrow;
    }
  }

  /// Eliminar sesión de sueño
  static Future<void> deleteSleepSession(String id) async {
    try {
      await supabase
          .from('sleep_sessions')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUserId!);
    } catch (e) {
      debugPrint('Error deleting sleep session: $e');
      rethrow;
    }
  }

  // ============================================================================
  // DIARY MILESTONES
  // ============================================================================
  
  /// Obtener hitos del diario de un bebé
  static Future<List<DiaryMilestone>> getDiaryMilestones(String babyId) async {
    try {
      final response = await supabase
          .from('diary_milestones')
          .select()
          .eq('baby_id', babyId)
          .eq('user_id', currentUserId!)
          .order('date', ascending: false);
      
      return (response as List)
          .map((json) => DiaryMilestone.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting diary milestones: $e');
      rethrow;
    }
  }

  /// Crear hito del diario
  static Future<DiaryMilestone> createDiaryMilestone(DiaryMilestone milestone) async {
    try {
      final data = milestone.toJson();
      data['user_id'] = currentUserId;
      
      final response = await supabase
          .from('diary_milestones')
          .insert(data)
          .select()
          .single();
      
      return DiaryMilestone.fromJson(response);
    } catch (e) {
      debugPrint('Error creating diary milestone: $e');
      rethrow;
    }
  }

  /// Actualizar hito del diario
  static Future<DiaryMilestone> updateDiaryMilestone(String id, DiaryMilestone milestone) async {
    try {
      final response = await supabase
          .from('diary_milestones')
          .update(milestone.toJson())
          .eq('id', id)
          .eq('user_id', currentUserId!)
          .select()
          .single();
      
      return DiaryMilestone.fromJson(response);
    } catch (e) {
      debugPrint('Error updating diary milestone: $e');
      rethrow;
    }
  }

  /// Eliminar hito del diario
  static Future<void> deleteDiaryMilestone(String id) async {
    try {
      await supabase
          .from('diary_milestones')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUserId!);
    } catch (e) {
      debugPrint('Error deleting diary milestone: $e');
      rethrow;
    }
  }

  // ============================================================================
  // CAMERA CONFIGS
  // ============================================================================
  
  /// Obtener configuraciones de cámara del usuario
  static Future<List<CameraConfigModel>> getCameraConfigs() async {
    try {
      final response = await supabase
          .from('camera_configs')
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => CameraConfigModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting camera configs: $e');
      rethrow;
    }
  }

  /// Crear configuración de cámara
  static Future<CameraConfigModel> createCameraConfig(CameraConfigModel config) async {
    try {
      final data = config.toJson();
      data['user_id'] = currentUserId;
      
      final response = await supabase
          .from('camera_configs')
          .insert(data)
          .select()
          .single();
      
      return CameraConfigModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating camera config: $e');
      rethrow;
    }
  }

  /// Actualizar configuración de cámara
  static Future<CameraConfigModel> updateCameraConfig(String id, CameraConfigModel config) async {
    try {
      final response = await supabase
          .from('camera_configs')
          .update(config.toJson())
          .eq('id', id)
          .eq('user_id', currentUserId!)
          .select()
          .single();
      
      return CameraConfigModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updating camera config: $e');
      rethrow;
    }
  }

  /// Eliminar configuración de cámara
  static Future<void> deleteCameraConfig(String id) async {
    try {
      await supabase
          .from('camera_configs')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUserId!);
    } catch (e) {
      debugPrint('Error deleting camera config: $e');
      rethrow;
    }
  }

  // ============================================================================
  // STORAGE - Subida de imágenes
  // ============================================================================
  
  /// Subir foto de perfil de bebé
  static Future<String> uploadBabyPhoto(String babyId, File imageFile) async {
    try {
      final fileName = '${currentUserId}/${babyId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await supabase.storage
          .from('baby-photos')
          .upload(fileName, imageFile);
      
      final publicUrl = supabase.storage
          .from('baby-photos')
          .getPublicUrl(fileName);
      
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading baby photo: $e');
      rethrow;
    }
  }

  /// Subir foto de hito del diario
  static Future<String> uploadMilestonePhoto(String babyId, File imageFile) async {
    try {
      final fileName = '${currentUserId}/${babyId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await supabase.storage
          .from('milestone-photos')
          .upload(fileName, imageFile);
      
      final publicUrl = supabase.storage
          .from('milestone-photos')
          .getPublicUrl(fileName);
      
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading milestone photo: $e');
      rethrow;
    }
  }

  /// Eliminar imagen del storage
  static Future<void> deleteImage(String bucket, String path) async {
    try {
      await supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      debugPrint('Error deleting image: $e');
      rethrow;
    }
  }
}
