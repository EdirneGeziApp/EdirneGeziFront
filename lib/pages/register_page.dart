import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  int _passwordScore = 0;
  String _passwordStrengthText = "Şifre gücü";
  String _passwordHintText =
      "Daha güvenli bir şifre için harf, sayı ve özel karakter kullan.";
  Color _passwordStrengthColor = Colors.grey;

  void _checkPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 6) score++;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    String text;
    String hint;
    Color color;

    if (password.isEmpty) {
      text = "Şifre gücü";
      hint = "Daha güvenli bir şifre için harf, sayı ve özel karakter kullan.";
      color = Colors.grey;
      score = 0;
    } else if (password.length < 6) {
      text = "Zayıf şifre";
      hint = "En az 6 karakter kullanmalısın.";
      color = Colors.red;
    } else if (!RegExp(r'[A-Z]').hasMatch(password)) {
      text = "Orta seviye şifre";
      hint = "Bir büyük harf eklersen daha güçlü olur.";
      color = Colors.orange;
    } else if (!RegExp(r'[0-9]').hasMatch(password)) {
      text = "Orta seviye şifre";
      hint = "Bir sayı eklersen daha güvenli olur.";
      color = Colors.orange;
    } else if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      text = "Orta seviye şifre";
      hint = "Özel karakter eklersen şifren daha güçlü olur.";
      color = Colors.orange;
    } else {
      text = "Güçlü şifre";
      hint = "Harika! Bu şifre güçlü görünüyor.";
      color = Colors.green;
    }

    setState(() {
      _passwordScore = score;
      _passwordStrengthText = text;
      _passwordHintText = hint;
      _passwordStrengthColor = color;
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _register() async {
    final userName = _userNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _passwordConfirmController.text.trim();

    if (userName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage("Lütfen tüm alanları doldurun.");
      return;
    }

    if (userName.length < 3) {
      _showMessage("Kullanıcı adı en az 3 karakter olmalı.");
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

    if (password != confirmPassword) {
      _showMessage("Şifreler eşleşmiyor.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService().register(userName, email, password);

      if (result != null && mounted) {
        _showMessage("Kayıt başarılı. Lütfen giriş yapın.");

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    final double value = (_passwordScore / 5).clamp(0.0, 1.0);

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
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: _passwordStrengthColor,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "$_passwordStrengthText: ",
                      style: TextStyle(
                        color: _passwordStrengthColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: _passwordHintText,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
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
              stops: const [0.0, 0.42, 0.78, 1.0],
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
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 55,
                      color: Colors.red[900],
                    ),
                  ),
                  const SizedBox(height: 26),
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
                          "Hesap Oluştur ✨",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[900],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Bilgilerini girerek Edirne Gezi Rehberi'ne katıl.",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 22),
                        TextField(
                          controller: _userNameController,
                          decoration: _inputDecoration(
                            "Kullanıcı Adı",
                            Icons.person_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),
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
                          obscureText: _obscurePassword,
                          onChanged: _checkPasswordStrength,
                          decoration: _inputDecoration(
                            "Şifre",
                            Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPasswordStrength(),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordConfirmController,
                          obscureText: _obscurePasswordConfirm,
                          decoration: _inputDecoration(
                            "Şifre Tekrar",
                            Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePasswordConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePasswordConfirm =
                                      !_obscurePasswordConfirm;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
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
                            onPressed: _isLoading ? null : _register,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Hesap Oluştur",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
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