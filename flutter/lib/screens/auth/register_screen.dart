import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/loading_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _ngoCtrl = TextEditingController();
  String _role = 'citizen';
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose(); _ngoCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role: _role,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      ngoName: _role == 'ngo' ? _ngoCtrl.text.trim() : null,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, auth.isCitizen ? '/citizen' : '/ngo');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Registration failed'), backgroundColor: AppColors.critical),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.dark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role toggle
              const Text('I am a:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray)),
              const SizedBox(height: 8),
              Row(children: [
                _roleChip('citizen', '🏙️ Citizen'),
                const SizedBox(width: 10),
                _roleChip('ngo', '🏥 NGO Staff'),
              ]),
              const SizedBox(height: 20),
              _field(_nameCtrl, 'Full Name', Icons.person_outline),
              const SizedBox(height: 14),
              _field(_emailCtrl, 'Email Address', Icons.email_outlined, type: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null),
              const SizedBox(height: 14),
              _field(_phoneCtrl, 'Phone Number (optional)', Icons.phone_outlined, type: TextInputType.phone, required: false),
              if (_role == 'ngo') ...[
                const SizedBox(height: 14),
                _field(_ngoCtrl, 'NGO / Organisation Name', Icons.business_outlined),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.gray),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.gray),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscure,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.gray),
                ),
                validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 12),
              Text(
                'By registering, you agree to our Terms of Service and Privacy Policy.',
                style: TextStyle(fontSize: 11, color: AppColors.gray),
              ),
              const SizedBox(height: 24),
              LoadingButton(label: 'Create Account', loading: auth.loading, onPressed: _register),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(color: AppColors.gray, fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Sign In', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String role, String label) {
    final active = _role == role;
    return GestureDetector(
      onTap: () => setState(() => _role = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.teal : AppColors.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.teal : AppColors.lightGray),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : AppColors.dark,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14)),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.gray),
      ),
      validator: validator ??
          (required ? (v) => v == null || v.trim().isEmpty ? 'Required' : null : null),
    );
  }
}
