import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasInfantProfile = prefs.getBool('has_infant_profile') ?? false;

  runApp(MyApp(hasInfantProfile: hasInfantProfile));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.hasInfantProfile});

  final bool hasInfantProfile;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KOA - Monitoreo de tu bebé',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB6D7A8), // verde pastel suave
          primary: const Color(0xFFB6D7A8),
          secondary: const Color(0xFFCFE8C9),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5FFF3),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4F7A4A),
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Color(0xFF6E8F6A),
          ),
        ),
      ),
      home: BiometricLoginPage(hasInfantProfile: hasInfantProfile),
    );
  }
}

class BiometricLoginPage extends StatefulWidget {
  const BiometricLoginPage({super.key, required this.hasInfantProfile});

  final bool hasInfantProfile;

  @override
  State<BiometricLoginPage> createState() => _BiometricLoginPageState();
}

class _BiometricLoginPageState extends State<BiometricLoginPage> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isChecking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      final canCheckBiometrics = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics || !isSupported) {
        // Si el dispositivo no soporta biometría, continúa sin login biométrico.
        _goNext();
        return;
      }

      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Usa tu rostro o huella para entrar a KOA',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!mounted) return;

      if (didAuthenticate) {
        _goNext();
      } else {
        setState(() {
          _isChecking = false;
          _error = 'No se pudo verificar tu identidad.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _error = 'Error al usar biometría: $e';
      });
    }
  }

  void _goNext() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => widget.hasInfantProfile
            ? const KoaHomePage()
            : const InfantRegistrationPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.1),
            radius: 1.1,
            colors: [
              Color(0xFFE8F7E4),
              Color(0xFFCFE8C9),
              Color(0xFFB6D7A8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 56,
                    color: Color(0xFF4F7A4A),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Protegemos el acceso a KOA',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4F7A4A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Usa reconocimiento facial o huella para entrar a la app.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6E8F6A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_isChecking) ...[
                    const CircularProgressIndicator(
                      color: Color(0xFF4F7A4A),
                    ),
                  ] else ...[
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB6D7A8),
                        foregroundColor: const Color(0xFF355334),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isChecking = true;
                          _error = null;
                        });
                        _authenticate();
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Intentar de nuevo'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _goNext,
                      child: const Text(
                        'Omitir por ahora',
                        style: TextStyle(color: Color(0xFF6E8F6A)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KoaHomePage extends StatelessWidget {
  const KoaHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.1),
            radius: 1.1,
            colors: [
              Color(0xFFE8F7E4),
              Color(0xFFCFE8C9),
              Color(0xFFB6D7A8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                // Portada KOA
                const Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                      child: Image(
                        image: AssetImage('assets/images/koa_cover.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'KOA',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Color(0xFF4F7A4A),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Tu acompañante en el cuidado de tu bebé',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6E8F6A),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Apartados principales',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    KoaFeatureCard(
                      icon: Icons.restaurant,
                      title: 'Comida',
                      description: 'Registro de tomas, horarios y notas sobre la alimentación.',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FoodPage()),
                        );
                      },
                    ),
                    KoaFeatureCard(
                      icon: Icons.videocam,
                      title: 'Monitor cámara',
                      description: 'Acceso al monitoreo visual de tu bebé.',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CameraMonitorPage()),
                        );
                      },
                    ),
                    KoaFeatureCard(
                      icon: Icons.favorite,
                      title: 'Salud',
                      description: 'Vacunas, peso, citas médicas y más.',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HealthPage()),
                        );
                      },
                    ),
                    KoaFeatureCard(
                      icon: Icons.book,
                      title: 'Diario de recuerdos',
                      description: 'Momentos especiales y hitos de tu bebé.',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MemoriesDiaryPage()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KoaFeatureCard extends StatelessWidget {
  const KoaFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 24 * 2 - 16) / 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB6D7A8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF4F7A4A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F7A4A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6E8F6A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FoodPage extends StatelessWidget {
  const FoodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimpleSectionScaffold(
      title: 'Comida',
      description: 'Aquí podrás registrar las tomas, horarios y notas de alimentación.',
      icon: Icons.restaurant,
    );
  }
}

class CameraMonitorPage extends StatelessWidget {
  const CameraMonitorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimpleSectionScaffold(
      title: 'Monitor cámara',
      description: 'En el futuro aquí se integrará la cámara para monitorear a tu bebé.',
      icon: Icons.videocam,
    );
  }
}

class HealthPage extends StatelessWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimpleSectionScaffold(
      title: 'Salud',
      description: 'Espacio para vacunas, peso, altura y citas médicas.',
      icon: Icons.favorite,
    );
  }
}

class MemoriesDiaryPage extends StatelessWidget {
  const MemoriesDiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimpleSectionScaffold(
      title: 'Diario de recuerdos',
      description: 'Guarda fotos, notas y momentos especiales de tu bebé.',
      icon: Icons.book,
    );
  }
}

class _SimpleSectionScaffold extends StatelessWidget {
  const _SimpleSectionScaffold({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB6D7A8),
        title: Text(title),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.1),
            radius: 1.1,
            colors: [
              Color(0xFFE8F7E4),
              Color(0xFFCFE8C9),
              Color(0xFFB6D7A8),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 56,
                  color: const Color(0xFF4F7A4A),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F7A4A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6E8F6A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfantRegistrationPage extends StatefulWidget {
  const InfantRegistrationPage({super.key});

  @override
  State<InfantRegistrationPage> createState() => _InfantRegistrationPageState();
}

class _InfantRegistrationPageState extends State<InfantRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _birthDate;
  String? _gender;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = _birthDate ?? now;
    final firstDate = DateTime(now.year - 3); // hasta 3 años atrás
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now,
      helpText: 'Fecha de nacimiento del bebé',
      locale: const Locale('es', ''),
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _birthDate == null || _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los datos del bebé.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_infant_profile', true);
    await prefs.setString('infant_name', _nameController.text.trim());
    await prefs.setString('infant_gender', _gender!);
    await prefs.setString('infant_birthdate', _birthDate!.toIso8601String());

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const KoaHomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.1),
            radius: 1.1,
            colors: [
              Color(0xFFE8F7E4),
              Color(0xFFCFE8C9),
              Color(0xFFB6D7A8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: const [
                    Text(
                      'KOA',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Color(0xFF4F7A4A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tu acompañante en el cuidado de tu bebé',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6E8F6A),
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
                Text(
                  'Registra a tu bebé',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del bebé',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el nombre.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _pickBirthDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de nacimiento',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _birthDate == null
                                    ? 'Selecciona la fecha'
                                    : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                                style: TextStyle(
                                  color: _birthDate == null
                                      ? Colors.grey[600]
                                      : Colors.black87,
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Género',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'femenino',
                            child: Text('Femenino'),
                          ),
                          DropdownMenuItem(
                            value: 'masculino',
                            child: Text('Masculino'),
                          ),
                          DropdownMenuItem(
                            value: 'otro',
                            child: Text('Otro / Prefiero no decir'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _gender = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Selecciona una opción.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB6D7A8),
                            foregroundColor: const Color(0xFF355334),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _submit,
                          child: const Text(
                            'Guardar perfil',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
