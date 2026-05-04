import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  int _passwordScore = 0;
  String _passwordStrengthText = "Şifre gücü";
  Color _passwordStrengthColor = Colors.grey;

  void _checkPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 6) score++;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    String text;
    Color color;

    if (password.isEmpty) {
      text = "Şifre gücü";
      color = Colors.grey;
      score = 0;
    } else if (score <= 2) {
      text = "Zayıf şifre";
      color = Colors.red;
    } else if (score <= 4) {
      text = "Orta seviye şifre";
      color = Colors.orange;
    } else {
      text = "Güçlü şifre";
      color = Colors.green;
    }

    setState(() {
      _passwordScore = score;
      _passwordStrengthText = text;
      _passwordStrengthColor = color;
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email);
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Lütfen tüm alanları doldurun.");
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage("Geçerli bir email adresi girin.");
      return;
    }

    if (password.length < 6) {
      _showMessage("Şifre en az 6 karakter olmalı.");
      return;
    }

    if (_passwordScore <= 2) {
      _showMessage("Lütfen daha güçlü bir şifre seçin.");
      return;
    }

    setState(() => _loading = true);

    final success = await ApiService().resetPassword(email, password);

    if (!mounted) return;

    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şifre başarıyla güncellendi.")),
      );
      Navigator.pop(context);
    } else {
      _showMessage("Şifre güncellenemedi. Email adresini kontrol edin.");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red[900]!, width: 2),
      ),
    );
  }

  Widget _buildPasswordStrength() {
    double value = (_passwordScore / 5).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: value,
          minHeight: 6,
          backgroundColor: Colors.grey[200],
          color: _passwordStrengthColor,
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(height: 6),
        Text(
          _passwordStrengthText,
          style: TextStyle(
            color: _passwordStrengthColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.45, 0.78, 1.0],
              colors: [
                Colors.red[900]!,
                Colors.red[700]!,
                Colors.white,
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      size: 55,
                      color: Colors.red[900],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Şifre Sıfırla 🔐",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[900],
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          "Email adresinizi ve yeni şifrenizi girin.",
                          style: TextStyle(color: Colors.grey),
                        ),

                        const SizedBox(height: 24),

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(
                            "Email",
                            Icons.email_outlined,
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          onChanged: _checkPasswordStrength,
                          decoration: _inputDecoration(
                            "Yeni Şifre",
                            Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscure = !_obscure;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        _buildPasswordStrength(),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[900],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _loading ? null : _resetPassword,
                            child: _loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Şifreyi Güncelle",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Giriş ekranına dön",
                              style: TextStyle(
                                color: Colors.red[900],
                                fontWeight: FontWeight.w600,
                              ),
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
      ),
    );
  }
}