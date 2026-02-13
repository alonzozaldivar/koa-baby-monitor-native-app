/// Datos de referencia de la OMS para crecimiento infantil (0-60 meses)
/// Fuente: WHO Child Growth Standards
/// https://www.who.int/tools/child-growth-standards

class WHOStandards {
  /// Obtiene el percentil de peso para la edad
  static double getWeightPercentile({
    required double weight,
    required int ageInMonths,
    required String gender, // 'masculino' o 'femenino'
  }) {
    final data = gender.toLowerCase() == 'masculino' 
        ? _weightBoysData 
        : _weightGirlsData;
    
    if (ageInMonths >= data.length) {
      ageInMonths = data.length - 1;
    }
    
    final percentiles = data[ageInMonths];
    
    if (weight < percentiles['p3']!) return 3.0;
    if (weight < percentiles['p15']!) return 15.0;
    if (weight < percentiles['p50']!) return 50.0;
    if (weight < percentiles['p85']!) return 85.0;
    if (weight < percentiles['p97']!) return 97.0;
    return 97.0;
  }

  /// Obtiene el percentil de talla para la edad
  static double getHeightPercentile({
    required double height,
    required int ageInMonths,
    required String gender, // 'masculino' o 'femenino'
  }) {
    final data = gender.toLowerCase() == 'masculino' 
        ? _heightBoysData 
        : _heightGirlsData;
    
    if (ageInMonths >= data.length) {
      ageInMonths = data.length - 1;
    }
    
    final percentiles = data[ageInMonths];
    
    if (height < percentiles['p3']!) return 3.0;
    if (height < percentiles['p15']!) return 15.0;
    if (height < percentiles['p50']!) return 50.0;
    if (height < percentiles['p85']!) return 85.0;
    if (height < percentiles['p97']!) return 97.0;
    return 97.0;
  }

  /// Obtiene los percentiles de peso para graficar
  static Map<String, double> getWeightPercentilesForAge(int ageInMonths, String gender) {
    final data = gender.toLowerCase() == 'masculino' 
        ? _weightBoysData 
        : _weightGirlsData;
    
    if (ageInMonths >= data.length) {
      ageInMonths = data.length - 1;
    }
    
    return data[ageInMonths];
  }

  /// Obtiene los percentiles de talla para graficar
  static Map<String, double> getHeightPercentilesForAge(int ageInMonths, String gender) {
    final data = gender.toLowerCase() == 'masculino' 
        ? _heightBoysData 
        : _heightGirlsData;
    
    if (ageInMonths >= data.length) {
      ageInMonths = data.length - 1;
    }
    
    return data[ageInMonths];
  }

  // ========== DATOS DE PESO - NIÑOS (kg) ==========
  static final List<Map<String, double>> _weightBoysData = [
    {'p3': 2.5, 'p15': 2.9, 'p50': 3.3, 'p85': 3.9, 'p97': 4.4}, // 0 meses
    {'p3': 3.4, 'p15': 3.9, 'p50': 4.5, 'p85': 5.1, 'p97': 5.8}, // 1 mes
    {'p3': 4.3, 'p15': 4.9, 'p50': 5.6, 'p85': 6.3, 'p97': 7.1}, // 2 meses
    {'p3': 5.0, 'p15': 5.7, 'p50': 6.4, 'p85': 7.2, 'p97': 8.0}, // 3 meses
    {'p3': 5.6, 'p15': 6.2, 'p50': 7.0, 'p85': 7.8, 'p97': 8.7}, // 4 meses
    {'p3': 6.0, 'p15': 6.7, 'p50': 7.5, 'p85': 8.4, 'p97': 9.3}, // 5 meses
    {'p3': 6.4, 'p15': 7.1, 'p50': 7.9, 'p85': 8.8, 'p97': 9.8}, // 6 meses
    {'p3': 6.7, 'p15': 7.4, 'p50': 8.3, 'p85': 9.2, 'p97': 10.3}, // 7 meses
    {'p3': 6.9, 'p15': 7.7, 'p50': 8.6, 'p85': 9.6, 'p97': 10.7}, // 8 meses
    {'p3': 7.1, 'p15': 8.0, 'p50': 8.9, 'p85': 9.9, 'p97': 11.0}, // 9 meses
    {'p3': 7.4, 'p15': 8.2, 'p50': 9.2, 'p85': 10.2, 'p97': 11.4}, // 10 meses
    {'p3': 7.6, 'p15': 8.4, 'p50': 9.4, 'p85': 10.5, 'p97': 11.7}, // 11 meses
    {'p3': 7.7, 'p15': 8.6, 'p50': 9.6, 'p85': 10.8, 'p97': 12.0}, // 12 meses (1 año)
    // Continuación cada 3 meses hasta 60 meses
    {'p3': 8.2, 'p15': 9.2, 'p50': 10.3, 'p85': 11.5, 'p97': 12.9}, // 15 meses
    {'p3': 8.8, 'p15': 9.8, 'p50': 11.0, 'p85': 12.3, 'p97': 13.8}, // 18 meses
    {'p3': 9.3, 'p15': 10.4, 'p50': 11.6, 'p85': 13.0, 'p97': 14.6}, // 21 meses
    {'p3': 9.7, 'p15': 10.8, 'p50': 12.2, 'p85': 13.6, 'p97': 15.3}, // 24 meses (2 años)
    {'p3': 10.7, 'p15': 11.9, 'p50': 13.3, 'p85': 14.9, 'p97': 16.8}, // 30 meses
    {'p3': 11.6, 'p15': 12.9, 'p50': 14.3, 'p85': 16.2, 'p97': 18.3}, // 36 meses (3 años)
    {'p3': 12.4, 'p15': 13.8, 'p50': 15.3, 'p85': 17.3, 'p97': 19.6}, // 42 meses
    {'p3': 13.1, 'p15': 14.6, 'p50': 16.3, 'p85': 18.5, 'p97': 21.0}, // 48 meses (4 años)
    {'p3': 13.9, 'p15': 15.5, 'p50': 17.3, 'p85': 19.7, 'p97': 22.4}, // 54 meses
    {'p3': 14.6, 'p15': 16.3, 'p50': 18.3, 'p85': 20.8, 'p97': 23.7}, // 60 meses (5 años)
  ];

  // ========== DATOS DE PESO - NIÑAS (kg) ==========
  static final List<Map<String, double>> _weightGirlsData = [
    {'p3': 2.4, 'p15': 2.8, 'p50': 3.2, 'p85': 3.7, 'p97': 4.2}, // 0 meses
    {'p3': 3.2, 'p15': 3.6, 'p50': 4.2, 'p85': 4.8, 'p97': 5.5}, // 1 mes
    {'p3': 3.9, 'p15': 4.5, 'p50': 5.1, 'p85': 5.8, 'p97': 6.6}, // 2 meses
    {'p3': 4.5, 'p15': 5.2, 'p50': 5.8, 'p85': 6.6, 'p97': 7.5}, // 3 meses
    {'p3': 5.0, 'p15': 5.7, 'p50': 6.4, 'p85': 7.3, 'p97': 8.2}, // 4 meses
    {'p3': 5.4, 'p15': 6.1, 'p50': 6.9, 'p85': 7.8, 'p97': 8.8}, // 5 meses
    {'p3': 5.7, 'p15': 6.5, 'p50': 7.3, 'p85': 8.2, 'p97': 9.3}, // 6 meses
    {'p3': 6.0, 'p15': 6.8, 'p50': 7.6, 'p85': 8.6, 'p97': 9.8}, // 7 meses
    {'p3': 6.3, 'p15': 7.0, 'p50': 7.9, 'p85': 9.0, 'p97': 10.2}, // 8 meses
    {'p3': 6.5, 'p15': 7.3, 'p50': 8.2, 'p85': 9.3, 'p97': 10.5}, // 9 meses
    {'p3': 6.7, 'p15': 7.5, 'p50': 8.5, 'p85': 9.6, 'p97': 10.9}, // 10 meses
    {'p3': 6.9, 'p15': 7.7, 'p50': 8.7, 'p85': 9.9, 'p97': 11.2}, // 11 meses
    {'p3': 7.0, 'p15': 7.9, 'p50': 8.9, 'p85': 10.1, 'p97': 11.5}, // 12 meses (1 año)
    {'p3': 7.5, 'p15': 8.4, 'p50': 9.6, 'p85': 10.9, 'p97': 12.4}, // 15 meses
    {'p3': 8.1, 'p15': 9.1, 'p50': 10.2, 'p85': 11.6, 'p97': 13.2}, // 18 meses
    {'p3': 8.6, 'p15': 9.6, 'p50': 10.9, 'p85': 12.3, 'p97': 14.0}, // 21 meses
    {'p3': 9.0, 'p15': 10.2, 'p50': 11.5, 'p85': 13.0, 'p97': 14.8}, // 24 meses (2 años)
    {'p3': 10.0, 'p15': 11.2, 'p50': 12.7, 'p85': 14.4, 'p97': 16.4}, // 30 meses
    {'p3': 10.8, 'p15': 12.2, 'p50': 13.9, 'p85': 15.8, 'p97': 18.1}, // 36 meses (3 años)
    {'p3': 11.6, 'p15': 13.0, 'p50': 14.9, 'p85': 17.0, 'p97': 19.6}, // 42 meses
    {'p3': 12.3, 'p15': 13.9, 'p50': 15.9, 'p85': 18.2, 'p97': 21.0}, // 48 meses (4 años)
    {'p3': 13.1, 'p15': 14.7, 'p50': 16.9, 'p85': 19.4, 'p97': 22.5}, // 54 meses
    {'p3': 13.9, 'p15': 15.6, 'p50': 17.9, 'p85': 20.6, 'p97': 23.9}, // 60 meses (5 años)
  ];

  // ========== DATOS DE TALLA - NIÑOS (cm) ==========
  static final List<Map<String, double>> _heightBoysData = [
    {'p3': 46.1, 'p15': 48.0, 'p50': 49.9, 'p85': 51.8, 'p97': 53.7}, // 0 meses
    {'p3': 50.8, 'p15': 52.8, 'p50': 54.7, 'p85': 56.7, 'p97': 58.6}, // 1 mes
    {'p3': 54.4, 'p15': 56.4, 'p50': 58.4, 'p85': 60.4, 'p97': 62.4}, // 2 meses
    {'p3': 57.3, 'p15': 59.4, 'p50': 61.4, 'p85': 63.5, 'p97': 65.5}, // 3 meses
    {'p3': 59.7, 'p15': 61.8, 'p50': 63.9, 'p85': 66.0, 'p97': 68.0}, // 4 meses
    {'p3': 61.7, 'p15': 63.8, 'p50': 65.9, 'p85': 68.0, 'p97': 70.1}, // 5 meses
    {'p3': 63.3, 'p15': 65.5, 'p50': 67.6, 'p85': 69.8, 'p97': 71.9}, // 6 meses
    {'p3': 64.8, 'p15': 67.0, 'p50': 69.2, 'p85': 71.3, 'p97': 73.5}, // 7 meses
    {'p3': 66.2, 'p15': 68.4, 'p50': 70.6, 'p85': 72.8, 'p97': 75.0}, // 8 meses
    {'p3': 67.5, 'p15': 69.7, 'p50': 72.0, 'p85': 74.2, 'p97': 76.5}, // 9 meses
    {'p3': 68.7, 'p15': 71.0, 'p50': 73.3, 'p85': 75.6, 'p97': 77.9}, // 10 meses
    {'p3': 69.9, 'p15': 72.2, 'p50': 74.5, 'p85': 76.9, 'p97': 79.2}, // 11 meses
    {'p3': 71.0, 'p15': 73.4, 'p50': 75.7, 'p85': 78.1, 'p97': 80.5}, // 12 meses (1 año)
    {'p3': 73.6, 'p15': 76.0, 'p50': 78.6, 'p85': 81.2, 'p97': 83.7}, // 15 meses
    {'p3': 76.0, 'p15': 78.6, 'p50': 81.3, 'p85': 83.9, 'p97': 86.5}, // 18 meses
    {'p3': 78.0, 'p15': 80.8, 'p50': 83.5, 'p85': 86.3, 'p97': 89.0}, // 21 meses
    {'p3': 80.0, 'p15': 82.9, 'p50': 85.7, 'p85': 88.6, 'p97': 91.4}, // 24 meses (2 años)
    {'p3': 83.6, 'p15': 86.7, 'p50': 89.7, 'p85': 92.8, 'p97': 95.8}, // 30 meses
    {'p3': 87.1, 'p15': 90.3, 'p50': 93.6, 'p85': 96.8, 'p97': 100.0}, // 36 meses (3 años)
    {'p3': 90.3, 'p15': 93.7, 'p50': 97.1, 'p85': 100.6, 'p97': 104.0}, // 42 meses
    {'p3': 93.4, 'p15': 96.9, 'p50': 100.5, 'p85': 104.1, 'p97': 107.7}, // 48 meses (4 años)
    {'p3': 96.3, 'p15': 100.0, 'p50': 103.8, 'p85': 107.5, 'p97': 111.3}, // 54 meses
    {'p3': 99.1, 'p15': 103.0, 'p50': 107.0, 'p85': 110.9, 'p97': 114.8}, // 60 meses (5 años)
  ];

  // ========== DATOS DE TALLA - NIÑAS (cm) ==========
  static final List<Map<String, double>> _heightGirlsData = [
    {'p3': 45.4, 'p15': 47.3, 'p50': 49.1, 'p85': 51.0, 'p97': 52.9}, // 0 meses
    {'p3': 49.8, 'p15': 51.7, 'p50': 53.7, 'p85': 55.6, 'p97': 57.6}, // 1 mes
    {'p3': 53.0, 'p15': 55.0, 'p50': 57.1, 'p85': 59.1, 'p97': 61.1}, // 2 meses
    {'p3': 55.6, 'p15': 57.7, 'p50': 59.8, 'p85': 61.9, 'p97': 64.0}, // 3 meses
    {'p3': 57.8, 'p15': 59.9, 'p50': 62.1, 'p85': 64.3, 'p97': 66.4}, // 4 meses
    {'p3': 59.6, 'p15': 61.8, 'p50': 64.0, 'p85': 66.2, 'p97': 68.5}, // 5 meses
    {'p3': 61.2, 'p15': 63.5, 'p50': 65.7, 'p85': 68.0, 'p97': 70.3}, // 6 meses
    {'p3': 62.7, 'p15': 65.0, 'p50': 67.3, 'p85': 69.6, 'p97': 71.9}, // 7 meses
    {'p3': 64.0, 'p15': 66.4, 'p50': 68.7, 'p85': 71.1, 'p97': 73.5}, // 8 meses
    {'p3': 65.3, 'p15': 67.7, 'p50': 70.1, 'p85': 72.6, 'p97': 75.0}, // 9 meses
    {'p3': 66.5, 'p15': 69.0, 'p50': 71.5, 'p85': 74.0, 'p97': 76.4}, // 10 meses
    {'p3': 67.7, 'p15': 70.3, 'p50': 72.8, 'p85': 75.3, 'p97': 77.8}, // 11 meses
    {'p3': 68.9, 'p15': 71.4, 'p50': 74.0, 'p85': 76.6, 'p97': 79.2}, // 12 meses (1 año)
    {'p3': 71.6, 'p15': 74.3, 'p50': 77.1, 'p85': 79.9, 'p97': 82.7}, // 15 meses
    {'p3': 74.0, 'p15': 76.9, 'p50': 79.9, 'p85': 82.8, 'p97': 85.7}, // 18 meses
    {'p3': 76.0, 'p15': 79.1, 'p50': 82.2, 'p85': 85.3, 'p97': 88.4}, // 21 meses
    {'p3': 78.0, 'p15': 81.3, 'p50': 84.5, 'p85': 87.7, 'p97': 90.8}, // 24 meses (2 años)
    {'p3': 81.7, 'p15': 85.1, 'p50': 88.5, 'p85': 91.9, 'p97': 95.4}, // 30 meses
    {'p3': 85.1, 'p15': 88.7, 'p50': 92.3, 'p85': 95.9, 'p97': 99.5}, // 36 meses (3 años)
    {'p3': 88.4, 'p15': 92.1, 'p50': 95.9, 'p85': 99.7, 'p97': 103.5}, // 42 meses
    {'p3': 91.5, 'p15': 95.4, 'p50': 99.4, 'p85': 103.4, 'p97': 107.4}, // 48 meses (4 años)
    {'p3': 94.4, 'p15': 98.6, 'p50': 102.7, 'p85': 106.9, 'p97': 111.1}, // 54 meses
    {'p3': 97.3, 'p15': 101.6, 'p50': 106.0, 'p85': 110.4, 'p97': 114.7}, // 60 meses (5 años)
  ];

  /// Mapea meses a índice en los arrays (considerando intervalos)
  static int _getDataIndex(int ageInMonths) {
    if (ageInMonths <= 12) return ageInMonths;
    if (ageInMonths <= 24) return 12 + ((ageInMonths - 12) / 3).floor();
    if (ageInMonths <= 60) return 16 + ((ageInMonths - 24) / 6).floor();
    return 22; // máximo índice
  }
}
