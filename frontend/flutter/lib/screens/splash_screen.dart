import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/diamond_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.init();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (auth.isLoggedIn) {
      final role = (auth.user?.role ?? '').toLowerCase();
      String route = '/citizen';
      if (role.contains('ngo')) route = '/ngo';
      else if (role.contains('volunteer')) route = '/volunteer';
      else if (role.contains('vet')) route = '/vet';
      Navigator.pushReplacementNamed(context, route);
    } else {
      Navigator.pushReplacementNamed(context, '/choose-role');
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DiamondBackground(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(24)),
                child: const Center(child: Text('🐾', style: TextStyle(fontSize: 56))),
              ),
              const SizedBox(height: 24),
              Text('Karuṇā', style: GoogleFonts.playfairDisplay(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              const Text('RESCUE. HEAL. ADOPT.', style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 2.5, fontWeight: FontWeight.w500)),
              const Spacer(flex: 4),
              const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
