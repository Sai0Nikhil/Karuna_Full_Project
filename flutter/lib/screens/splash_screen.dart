import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.init();
    if (!mounted) return;
    if (auth.isLoggedIn) {
      if (auth.isCitizen) {
        Navigator.pushReplacementNamed(context, '/citizen');
      } else if (auth.isNgo) {
        Navigator.pushReplacementNamed(context, '/ngo');
      } else if (auth.user?.role == 'vet') {
        Navigator.pushReplacementNamed(context, '/vet');
      } else {
        Navigator.pushReplacementNamed(context, '/citizen');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/choose-role');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.teal,
      body: FadeTransition(
        opacity: _fade,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [AppColors.teal, AppColors.tealDark],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -60,
                right: -60,
                child: _circle(300, Colors.white.withOpacity(0.06)),
              ),
              Positioned(
                bottom: 40,
                left: -80,
                child: _circle(220, Colors.white.withOpacity(0.04)),
              ),
              // Content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Center(
                        child: Text('🐾', style: TextStyle(fontSize: 56)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Karuṇā',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Compassion for every creature',
                      style: TextStyle(
                        color: AppColors.tealLight,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: 160,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // Version
              const Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Text(
                  'v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
