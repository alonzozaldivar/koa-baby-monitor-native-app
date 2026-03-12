// ============================================================================
// KOALA TIPS - Tips organizados por sección y rango de edad
// koala_baby: 0-4 años | koala_nino: 5-7 años | koala_infante: 7-10 años
// ============================================================================

enum KoalaStage { baby, nino, infante }

class KoalaTipData {
  final String tipEs;
  final String tipEn;

  const KoalaTipData({required this.tipEs, required this.tipEn});
}

class KoalaTips {
  /// Determina la etapa del koala según la edad en años
  static KoalaStage getStage(int ageInYears) {
    if (ageInYears <= 4) return KoalaStage.baby;
    if (ageInYears <= 7) return KoalaStage.nino;
    return KoalaStage.infante;
  }

  /// Obtiene la imagen del koala según la etapa
  static String getKoalaImage(KoalaStage stage) {
    switch (stage) {
      case KoalaStage.baby:
        return 'assets/images/koala_baby.png';
      case KoalaStage.nino:
        return 'assets/images/koala_nino.png';
      case KoalaStage.infante:
        return 'assets/images/koala_infante.png';
    }
  }

  /// Nombre del koala según la etapa
  static Map<String, String> getKoalaName(KoalaStage stage) {
    switch (stage) {
      case KoalaStage.baby:
        return {'es': 'Koalito', 'en': 'Little Koala'};
      case KoalaStage.nino:
        return {'es': 'Koalín', 'en': 'Koalin'};
      case KoalaStage.infante:
        return {'es': 'Koa', 'en': 'Koa'};
    }
  }

  // ==========================================================================
  // TIPS POR SECCIÓN Y ETAPA
  // ==========================================================================

  static const Map<String, Map<KoalaStage, List<KoalaTipData>>> tips = {
    // ---- HOME ----
    'home': {
      KoalaStage.baby: [
        KoalaTipData(
          tipEs: '¡Hola! Recuerda que los bebés necesitan entre 14 y 17 horas de sueño al día.',
          tipEn: 'Hi! Remember that babies need 14 to 17 hours of sleep per day.',
        ),
        KoalaTipData(
          tipEs: 'El contacto piel con piel fortalece el vínculo con tu bebé. ¡Abrázalo mucho!',
          tipEn: 'Skin-to-skin contact strengthens the bond with your baby. Hug them a lot!',
        ),
        KoalaTipData(
          tipEs: 'Hablarle y cantarle a tu bebé estimula su desarrollo cerebral desde el primer día.',
          tipEn: 'Talking and singing to your baby stimulates brain development from day one.',
        ),
        KoalaTipData(
          tipEs: 'Los primeros 1000 días de vida son clave para el desarrollo. ¡Cada momento cuenta!',
          tipEn: 'The first 1000 days of life are key for development. Every moment counts!',
        ),
      ],
      KoalaStage.nino: [
        KoalaTipData(
          tipEs: 'A esta edad, 10-13 horas de sueño son ideales. ¡Una buena rutina ayuda!',
          tipEn: 'At this age, 10-13 hours of sleep are ideal. A good routine helps!',
        ),
        KoalaTipData(
          tipEs: 'Los niños aprenden jugando. Dedica tiempo a jugar con ellos cada día.',
          tipEn: 'Children learn by playing. Spend time playing with them every day.',
        ),
        KoalaTipData(
          tipEs: 'Leer juntos antes de dormir crea un hábito maravilloso. ¡Pruébalo!',
          tipEn: 'Reading together before bed creates a wonderful habit. Try it!',
        ),
      ],
      KoalaStage.infante: [
        KoalaTipData(
          tipEs: 'Los niños en edad escolar necesitan 9-11 horas de sueño para rendir bien.',
          tipEn: 'School-age children need 9-11 hours of sleep to perform well.',
        ),
        KoalaTipData(
          tipEs: 'Fomentar la autonomía a esta edad les da confianza. ¡Déjalos intentar!',
          tipEn: 'Encouraging autonomy at this age builds confidence. Let them try!',
        ),
        KoalaTipData(
          tipEs: 'Conversa con tu hijo sobre su día. La comunicación abierta fortalece la relación.',
          tipEn: 'Talk with your child about their day. Open communication strengthens the bond.',
        ),
      ],
    },

    // ---- FOOD ----
    'food': {
      KoalaStage.baby: [
        KoalaTipData(
          tipEs: 'La lactancia materna exclusiva se recomienda los primeros 6 meses.',
          tipEn: 'Exclusive breastfeeding is recommended for the first 6 months.',
        ),
        KoalaTipData(
          tipEs: 'A partir de los 6 meses puedes iniciar la alimentación complementaria.',
          tipEn: 'From 6 months you can start complementary feeding.',
        ),
        KoalaTipData(
          tipEs: 'Introduce un alimento nuevo a la vez y espera 3 días para detectar alergias.',
          tipEn: 'Introduce one new food at a time and wait 3 days to detect allergies.',
        ),
        KoalaTipData(
          tipEs: 'Evita la miel antes del primer año. ¡La seguridad alimentaria es primero!',
          tipEn: 'Avoid honey before the first year. Food safety comes first!',
        ),
      ],
      KoalaStage.nino: [
        KoalaTipData(
          tipEs: 'Incluye frutas y verduras de colores en cada comida. ¡Hazlo divertido!',
          tipEn: 'Include colorful fruits and vegetables in every meal. Make it fun!',
        ),
        KoalaTipData(
          tipEs: 'Los niños necesitan 5 comidas al día: 3 principales y 2 meriendas.',
          tipEn: 'Children need 5 meals a day: 3 main meals and 2 snacks.',
        ),
        KoalaTipData(
          tipEs: 'Involúcralos en la cocina. Los niños comen mejor lo que ayudan a preparar.',
          tipEn: 'Involve them in cooking. Kids eat better what they help prepare.',
        ),
      ],
      KoalaStage.infante: [
        KoalaTipData(
          tipEs: 'Un desayuno completo mejora la concentración en la escuela.',
          tipEn: 'A complete breakfast improves concentration at school.',
        ),
        KoalaTipData(
          tipEs: 'Limita las bebidas azucaradas. El agua siempre es la mejor opción.',
          tipEn: 'Limit sugary drinks. Water is always the best option.',
        ),
        KoalaTipData(
          tipEs: 'Enséñales a leer etiquetas nutricionales. ¡Es un hábito para toda la vida!',
          tipEn: 'Teach them to read nutrition labels. It\'s a lifelong habit!',
        ),
      ],
    },

    // ---- SLEEP ----
    'sleep': {
      KoalaStage.baby: [
        KoalaTipData(
          tipEs: 'Siempre acuesta a tu bebé boca arriba para dormir. ¡Es más seguro!',
          tipEn: 'Always place your baby on their back to sleep. It\'s safer!',
        ),
        KoalaTipData(
          tipEs: 'Una rutina de sueño consistente ayuda a tu bebé a dormir mejor.',
          tipEn: 'A consistent sleep routine helps your baby sleep better.',
        ),
        KoalaTipData(
          tipEs: 'El ruido blanco puede ayudar a calmar a tu bebé para dormir.',
          tipEn: 'White noise can help soothe your baby to sleep.',
        ),
      ],
      KoalaStage.nino: [
        KoalaTipData(
          tipEs: 'Evita pantallas 1 hora antes de dormir. La luz azul afecta el sueño.',
          tipEn: 'Avoid screens 1 hour before bed. Blue light affects sleep.',
        ),
        KoalaTipData(
          tipEs: 'Un baño tibio antes de dormir relaja y prepara para el descanso.',
          tipEn: 'A warm bath before bed relaxes and prepares for rest.',
        ),
        KoalaTipData(
          tipEs: 'Mantén horarios fijos para dormir, incluso los fines de semana.',
          tipEn: 'Keep fixed sleep schedules, even on weekends.',
        ),
      ],
      KoalaStage.infante: [
        KoalaTipData(
          tipEs: 'Un ambiente oscuro y fresco favorece un sueño profundo y reparador.',
          tipEn: 'A dark and cool environment promotes deep, restorative sleep.',
        ),
        KoalaTipData(
          tipEs: 'Si tu hijo tiene pesadillas frecuentes, hablen sobre ello con calma.',
          tipEn: 'If your child has frequent nightmares, talk about it calmly.',
        ),
        KoalaTipData(
          tipEs: 'Dormir bien mejora la memoria y el aprendizaje. ¡Prioriza el descanso!',
          tipEn: 'Good sleep improves memory and learning. Prioritize rest!',
        ),
      ],
    },

    // ---- HEALTH ----
    'health': {
      KoalaStage.baby: [
        KoalaTipData(
          tipEs: 'Las visitas al pediatra deben ser mensuales el primer año de vida.',
          tipEn: 'Pediatric visits should be monthly during the first year.',
        ),
        KoalaTipData(
          tipEs: 'Mantén el calendario de vacunación al día. ¡Protege a tu bebé!',
          tipEn: 'Keep the vaccination schedule up to date. Protect your baby!',
        ),
        KoalaTipData(
          tipEs: 'La fiebre en menores de 3 meses requiere atención médica inmediata.',
          tipEn: 'Fever in children under 3 months requires immediate medical attention.',
        ),
      ],
      KoalaStage.nino: [
        KoalaTipData(
          tipEs: 'Revisiones dentales cada 6 meses ayudan a mantener dientes sanos.',
          tipEn: 'Dental checkups every 6 months help maintain healthy teeth.',
        ),
        KoalaTipData(
          tipEs: 'Enseña a tu hijo a lavarse las manos correctamente. ¡Previene enfermedades!',
          tipEn: 'Teach your child to wash hands properly. It prevents diseases!',
        ),
        KoalaTipData(
          tipEs: '60 minutos de actividad física diaria son esenciales para su salud.',
          tipEn: '60 minutes of daily physical activity are essential for their health.',
        ),
      ],
      KoalaStage.infante: [
        KoalaTipData(
          tipEs: 'Un chequeo anual completo es importante a esta edad.',
          tipEn: 'A complete annual checkup is important at this age.',
        ),
        KoalaTipData(
          tipEs: 'Habla con tu hijo sobre higiene personal. Ya puede ser más independiente.',
          tipEn: 'Talk to your child about personal hygiene. They can be more independent now.',
        ),
        KoalaTipData(
          tipEs: 'Revisa la visión de tu hijo. Problemas visuales pueden afectar su rendimiento escolar.',
          tipEn: 'Check your child\'s vision. Visual problems can affect school performance.',
        ),
      ],
    },

    // ---- DIARY ----
    'diary': {
      KoalaStage.baby: [
        KoalaTipData(
          tipEs: '¡No olvides registrar su primera sonrisa! Pasa más rápido de lo que crees.',
          tipEn: 'Don\'t forget to record their first smile! It happens faster than you think.',
        ),
        KoalaTipData(
          tipEs: 'Toma fotos del mismo ángulo cada mes. ¡Verás cuánto crece!',
          tipEn: 'Take photos from the same angle each month. You\'ll see how much they grow!',
        ),
        KoalaTipData(
          tipEs: 'Guarda un registro de sus primeras palabras. Son recuerdos invaluables.',
          tipEn: 'Keep a record of their first words. They are priceless memories.',
        ),
      ],
      KoalaStage.nino: [
        KoalaTipData(
          tipEs: 'Registra sus dibujos favoritos. ¡Un día los verán juntos y se reirán!',
          tipEn: 'Save their favorite drawings. One day you\'ll look at them together and laugh!',
        ),
        KoalaTipData(
          tipEs: 'Los logros pequeños también cuentan. ¡Celebra cada uno!',
          tipEn: 'Small achievements count too. Celebrate each one!',
        ),
        KoalaTipData(
          tipEs: 'Pídele que te cuente su momento favorito del día y anótalo.',
          tipEn: 'Ask them to tell you their favorite moment of the day and write it down.',
        ),
      ],
      KoalaStage.infante: [
        KoalaTipData(
          tipEs: 'Invítalo a escribir en su propio diario. ¡Fomenta la creatividad!',
          tipEn: 'Invite them to write in their own diary. Encourage creativity!',
        ),
        KoalaTipData(
          tipEs: 'Hagan juntos un álbum de sus mejores aventuras del año.',
          tipEn: 'Make an album together of their best adventures of the year.',
        ),
        KoalaTipData(
          tipEs: 'Registra sus metas y sueños. A esta edad empiezan a soñar en grande.',
          tipEn: 'Record their goals and dreams. At this age they start dreaming big.',
        ),
      ],
    },
  };

  /// Obtiene un tip aleatorio para una sección y etapa
  static KoalaTipData? getTip(String section, KoalaStage stage) {
    final sectionTips = tips[section];
    if (sectionTips == null) return null;

    final stageTips = sectionTips[stage];
    if (stageTips == null || stageTips.isEmpty) return null;

    // Tip basado en el día del año para que cambie diariamente
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final index = dayOfYear % stageTips.length;
    return stageTips[index];
  }
}
