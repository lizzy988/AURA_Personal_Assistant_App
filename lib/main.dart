
import 'package:flutter/material.dart';

void main() {
  runApp(const AuraApp());
}

class AuraApp extends StatelessWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AURA',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

// AURA COLOURS
const Color teal = Color(0xFF00C4C7);
const Color purple = Color(0xFF7950F2);
const Color navy = Color(0xFF19172F);
const Color white = Colors.white;

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

              // AURA LOGO
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

              // APP NAME AND DESCRIPTION
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

              // GET STARTED BUTTON
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
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text('Get started'),
                ),
              ),

              // LOGIN LINK
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
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
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: teal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 45),

              const Text(
                'Welcome back Aitasi!',
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
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  filled: true,
                  fillColor: navy,
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: white),
              ),

              const SizedBox(height: 20),

              const Text(
                'Password',
                style: TextStyle(color: white),
              ),

              const SizedBox(height: 8),

              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  filled: true,
                  fillColor: navy,
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: white),
              ),

              const SizedBox(height: 18),

              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '☐  Remember me',
                    style: TextStyle(color: white, fontSize: 12),
                  ),
                  Text(
                    'Forgot password?',
                    style: TextStyle(color: purple, fontSize: 12),
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
                  onPressed: () {},
                  child: const Text('Log in'),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: white,
                  ),
                  onPressed: () {},
                  child: const Text('Continue with Google'),
                ),
              ),

              const Spacer(),

              Center(
                child: TextButton(
                  onPressed: () {},
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
