/// Esquema de vacunación estándar recomendado por la OMS y organismos de salud
/// Este es un esquema general que puede variar según el país

class VaccineSchedule {
  /// Lista de vacunas estándar con edad recomendada de aplicación
  static final List<Map<String, dynamic>> standardVaccines = [
    // Recién nacido
    {
      'id': 'bcg_0',
      'name': 'BCG (Tuberculosis)',
      'ageInMonths': 0,
      'description': 'Protege contra formas graves de tuberculosis',
    },
    {
      'id': 'hepb_0',
      'name': 'Hepatitis B (1ra dosis)',
      'ageInMonths': 0,
      'description': 'Primera dosis de hepatitis B',
    },
    
    // 2 meses
    {
      'id': 'pentavalente_1',
      'name': 'Pentavalente (1ra dosis)',
      'ageInMonths': 2,
      'description': 'DPT + HepB + Hib',
    },
    {
      'id': 'polio_1',
      'name': 'Antipolio (1ra dosis)',
      'ageInMonths': 2,
      'description': 'Protege contra poliomielitis',
    },
    {
      'id': 'rotavirus_1',
      'name': 'Rotavirus (1ra dosis)',
      'ageInMonths': 2,
      'description': 'Previene gastroenteritis por rotavirus',
    },
    {
      'id': 'neumococo_1',
      'name': 'Neumocócica (1ra dosis)',
      'ageInMonths': 2,
      'description': 'Protege contra enfermedades neumocócicas',
    },
    
    // 4 meses
    {
      'id': 'pentavalente_2',
      'name': 'Pentavalente (2da dosis)',
      'ageInMonths': 4,
      'description': 'DPT + HepB + Hib',
    },
    {
      'id': 'polio_2',
      'name': 'Antipolio (2da dosis)',
      'ageInMonths': 4,
      'description': 'Protege contra poliomielitis',
    },
    {
      'id': 'rotavirus_2',
      'name': 'Rotavirus (2da dosis)',
      'ageInMonths': 4,
      'description': 'Previene gastroenteritis por rotavirus',
    },
    {
      'id': 'neumococo_2',
      'name': 'Neumocócica (2da dosis)',
      'ageInMonths': 4,
      'description': 'Protege contra enfermedades neumocócicas',
    },
    
    // 6 meses
    {
      'id': 'pentavalente_3',
      'name': 'Pentavalente (3ra dosis)',
      'ageInMonths': 6,
      'description': 'DPT + HepB + Hib',
    },
    {
      'id': 'polio_3',
      'name': 'Antipolio (3ra dosis)',
      'ageInMonths': 6,
      'description': 'Protege contra poliomielitis',
    },
    {
      'id': 'influenza_1',
      'name': 'Influenza (1ra dosis)',
      'ageInMonths': 6,
      'description': 'Protege contra gripe estacional',
    },
    
    // 7 meses
    {
      'id': 'influenza_2',
      'name': 'Influenza (2da dosis)',
      'ageInMonths': 7,
      'description': 'Refuerzo de influenza',
    },
    
    // 12 meses
    {
      'id': 'srp_1',
      'name': 'SRP (Sarampión, Rubéola, Paperas)',
      'ageInMonths': 12,
      'description': 'Triple viral',
    },
    {
      'id': 'neumococo_3',
      'name': 'Neumocócica (refuerzo)',
      'ageInMonths': 12,
      'description': 'Refuerzo de neumococo',
    },
    {
      'id': 'varicela_1',
      'name': 'Varicela',
      'ageInMonths': 12,
      'description': 'Protege contra varicela',
    },
    
    // 18 meses
    {
      'id': 'dpt_refuerzo1',
      'name': 'DPT (1er refuerzo)',
      'ageInMonths': 18,
      'description': 'Refuerzo de difteria, tos ferina y tétanos',
    },
    {
      'id': 'polio_refuerzo1',
      'name': 'Antipolio (1er refuerzo)',
      'ageInMonths': 18,
      'description': 'Refuerzo de polio',
    },
    {
      'id': 'hepatitisA_1',
      'name': 'Hepatitis A',
      'ageInMonths': 18,
      'description': 'Protege contra hepatitis A',
    },
    
    // 4 años (48 meses)
    {
      'id': 'dpt_refuerzo2',
      'name': 'DPT (2do refuerzo)',
      'ageInMonths': 48,
      'description': 'Segundo refuerzo de DPT',
    },
    {
      'id': 'polio_refuerzo2',
      'name': 'Antipolio (2do refuerzo)',
      'ageInMonths': 48,
      'description': 'Segundo refuerzo de polio',
    },
    
    // 6 años (72 meses)
    {
      'id': 'srp_2',
      'name': 'SRP (refuerzo)',
      'ageInMonths': 72,
      'description': 'Refuerzo de triple viral',
    },
  ];
  
  /// Obtiene las vacunas recomendadas para una edad específica (con margen de ±1 mes)
  static List<Map<String, dynamic>> getVaccinesForAge(int ageInMonths) {
    return standardVaccines.where((vaccine) {
      final vaccineAge = vaccine['ageInMonths'] as int;
      return (vaccineAge - ageInMonths).abs() <= 1;
    }).toList();
  }
  
  /// Obtiene todas las vacunas pendientes hasta cierta edad
  static List<Map<String, dynamic>> getVaccinesUpToAge(int ageInMonths) {
    return standardVaccines.where((vaccine) {
      return (vaccine['ageInMonths'] as int) <= ageInMonths;
    }).toList();
  }
}
