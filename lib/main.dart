import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'daily_planner_screen.dart';
import 'api_service.dart';
import 'forgot_password.dart';


final GlobalKey<NavigatorState> auraNavigatorKey =
    GlobalKey<NavigatorState>();

// GLOBAL AURA THEME SETTINGS
final ValueNotifier<ThemeMode> auraThemeMode =
    ValueNotifier<ThemeMode>(ThemeMode.system);

final ValueNotifier<Color> auraAccentColor =
    ValueNotifier<Color>(const Color(0xFF7950F2));

    ThemeMode getAuraThemeMode(String value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

Color getAuraAccentColor(String value) {
  switch (value.toUpperCase()) {
    case '#00C4C7':
      return const Color(0xFF00C4C7);
    case '#7950F2':
      return const Color(0xFF7950F2);
    case '#FF9F43':
      return const Color(0xFFFF9F43);
    default:
      return const Color(0xFF7950F2);
  }
}

void updateAuraAppearance({
  required String themeMode,
  required String accentColor,
}) {
  auraThemeMode.value = getAuraThemeMode(themeMode);
  auraAccentColor.value = getAuraAccentColor(accentColor);
}

void main() {
  runApp(const AuraApp());
}

// AURA COLOURS
const Color teal = Color(0xFF00C4C7);
const Color purple = Color(0xFF7950F2);
const Color navy = Color(0xFF19172F);
const Color white = Colors.white;

// APPLY SAVED USER THEME
void applyAuraSettings(Map<String, dynamic> settings) {
  final mode = settings['theme_mode']?.toString() ?? 'system';

  switch (mode) {
    case 'light':
      auraThemeMode.value = ThemeMode.light;
      break;
    case 'dark':
      auraThemeMode.value = ThemeMode.dark;
      break;
    default:
      auraThemeMode.value = ThemeMode.system;
  }

  final accent = settings['accent_color']?.toString() ?? '#7950F2';

  try {
    final hex = accent.replaceFirst('#', '');
    final colorValue = int.parse(hex, radix: 16);
    auraAccentColor.value = Color(0xFF000000 | colorValue);
  } catch (_) {
    auraAccentColor.value = purple;
  }
}

// MAIN AURA APPLICATION
class AuraApp extends StatelessWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: auraThemeMode,
      builder: (context, selectedMode, child) {
        return ValueListenableBuilder<Color>(
          valueListenable: auraAccentColor,
          builder: (context, accent, child) {
            return MaterialApp(
              navigatorKey: auraNavigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'AURA',

              themeMode: selectedMode,

              theme: ThemeData(
                useMaterial3: true,
                fontFamily: 'Roboto',
                brightness: Brightness.light,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: accent,
                  brightness: Brightness.light,
                ),
                scaffoldBackgroundColor:
                    const Color(0xFFF7F8FC),
              ),

              darkTheme: ThemeData(
                useMaterial3: true,
                fontFamily: 'Roboto',
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: accent,
                  brightness: Brightness.dark,
                ),
                scaffoldBackgroundColor:
                    const Color(0xFF12121A),
              ),

              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}

// SPLASH SCREEN
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: teal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(height: 15),

              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 105,
                    height: 105,
                    decoration: const BoxDecoration(
                      color: purple,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 65,
                    height: 65,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6961F0),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Icon(
                    Icons.auto_awesome,
                    color: white,
                    size: 32,
                  ),
                ],
              ),

              Column(
                children: [
                  const Text(
                    'AURA',
                    style: TextStyle(
                      color: white,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Your day, thoughtfully organised.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Plan smarter. Remember what matters.\n'
                    'Find your flow again when plans change.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: white,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text('Get started'),
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const LoginScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// LOGIN SCREEN
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;
  bool rememberMe = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage('Please enter your email and password.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final user = result['user'];

      final Map<String, dynamic> userData =
          user is Map
              ? Map<String, dynamic>.from(user)
              : result;

      final userId = userData['user_id'];
      final fullName =
          userData['full_name']?.toString() ?? '';

      if (userId == null) {
        showMessage(
          result['message']?.toString() ??
              result['error']?.toString() ??
              'Login failed. User information was not received.',
        );
        return;
      }

      final parsedUserId =
          int.tryParse(userId.toString());

      if (parsedUserId == null) {
        showMessage('Invalid user account information.');
        return;
      }

      // LOAD SAVED SETTINGS AFTER LOGIN
      try {
        final savedSettings = await ApiService.getSettings(
          userId: parsedUserId,
        );

        applyAuraSettings(savedSettings);
      } catch (_) {
        // Login should still work if settings cannot load.
      }

      if (!mounted) return;

      showMessage('Login successful! Welcome to AURA.');

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
builder: (context) => DailyPlannerScreen(
  userId: parsedUserId,
  userName: fullName,

  onLogout: () {
    // Reset theme when logging out.
    auraThemeMode.value = ThemeMode.system;
    auraAccentColor.value = purple;

    auraNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  },

  onThemeChanged: ({
    required String themeMode,
    required String accentColor,
  }) {
    updateAuraAppearance(
      themeMode: themeMode,
      accentColor: accentColor,
    );
  },
),
  ),
      );
    } catch (e) {
      if (mounted) {
        showMessage(
          'Invalid email or password.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: teal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 45),

              const Text(
                'Welcome back!',
                style: TextStyle(
                  color: white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Your plans are waiting for you.',
                style: TextStyle(color: white),
              ),

              const SizedBox(height: 35),

              const Text(
                'Email address',
                style: TextStyle(color: white),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: white),
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  filled: true,
                  fillColor: navy,
                  hintStyle: const TextStyle(
                    color: Colors.white54,
                  ),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: white,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Password',
                style: TextStyle(color: white),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                style: const TextStyle(color: white),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  filled: true,
                  fillColor: navy,
                  hintStyle: const TextStyle(
                    color: Colors.white54,
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: white,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: white,
                    ),
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (value) {
                          setState(() {
                            rememberMe = value ?? false;
                          });
                        },
                        activeColor: purple,
                        checkColor: white,
                      ),
                      const Text(
                        'Remember me',
                        style: TextStyle(
                          color: white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                 TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ForgotPasswordScreen(),
      ),
    );
  },
  style: TextButton.styleFrom(
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  ),
  child: const Text(
    'Forgot password?',
    style: TextStyle(
      color: purple,
      fontSize: 12,
    ),
  ),
),
    ],
   ),
       const SizedBox(height: 25),
                SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: white,
                  ),
                  onPressed:
                      isLoading ? null : loginUser,
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: white,
                        )
                      : const Text('Log in'),
                ),
              ),

           const SizedBox(height: 25),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SignupScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'New to AURA? Create account',
                    style: TextStyle(color: white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}