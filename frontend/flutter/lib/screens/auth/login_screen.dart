import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/diamond_background.dart';
import '../../widgets/loading_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      final role = (auth.user?.role ?? '').toLowerCase();
      String route = '/citizen';
      if (role.contains('ngo')) route = '/ngo';
      else if (role.contains('volunteer')) route = '/volunteer';
      else if (role.contains('vet')) route = '/vet';
      Navigator.pushReplacementNamed(context, route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed'), backgroundColor: AppColors.critical));
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return; // User cancelled the flow
      final authInfo = await account.authentication;
      final idToken = authInfo.idToken;
      if (idToken == null) {
        throw 'No Google ID Token generated';
      }

      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final ok = await auth.loginWithGoogle(idToken);
      if (!mounted) return;
      if (ok) {
        final role = (auth.user?.role ?? '').toLowerCase();
        String route = '/citizen';
        if (role.contains('ngo')) route = '/ngo';
        else if (role.contains('volunteer')) route = '/volunteer';
        else if (role.contains('vet')) route = '/vet';
        Navigator.pushReplacementNamed(context, route);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Google Sign-in failed'), backgroundColor: AppColors.critical));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-in error: $e'), backgroundColor: AppColors.critical));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: LightDiamondBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(children: [
                const SizedBox(height: 24),
                Text('Karuṇā', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.teal)),
                const SizedBox(height: 28),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Center(child: Text('🐾', style: TextStyle(fontSize: 40))),
                ),
                const SizedBox(height: 28),
                Text('Welcome back!', style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.dark)),
                const SizedBox(height: 6),
                Text('Sign in to continue to Karuṇā', style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(),
                  decoration: const InputDecoration(hintText: 'Email Address', prefixIcon: Icon(Icons.mail_outline, color: AppColors.gray)),
                  validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl, obscureText: _obscure,
                  style: GoogleFonts.inter(),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.gray),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.gray),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 4 ? 'Enter your password' : null,
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () {},
                    child: Text('Forgot Password?', style: GoogleFonts.inter(color: AppColors.teal, fontWeight: FontWeight.w600)))),
                const SizedBox(height: 8),
                LoadingButton(label: 'Sign In', loading: auth.loading, onPressed: _login),
                const SizedBox(height: 24),
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: GoogleFonts.inter(color: AppColors.gray, fontSize: 12, fontWeight: FontWeight.w600))),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), side: const BorderSide(color: AppColors.divider), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), foregroundColor: AppColors.dark),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('G ', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                      Text('Google', style: GoogleFonts.inter(color: AppColors.dark, fontWeight: FontWeight.w500, fontSize: 14)),
                    ]),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), side: const BorderSide(color: AppColors.divider), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), foregroundColor: AppColors.dark),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.apple, color: AppColors.dark, size: 20),
                      const SizedBox(width: 4),
                      Text('Apple', style: GoogleFonts.inter(color: AppColors.dark, fontWeight: FontWeight.w500, fontSize: 14)),
                    ]),
                  )),
                ]),
                const SizedBox(height: 28),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("Don't have an account? ", style: GoogleFonts.inter(color: AppColors.gray, fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/register'),
                    child: Text('Register', style: GoogleFonts.inter(color: AppColors.teal, fontWeight: FontWeight.bold, fontSize: 14))),
                ]),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
