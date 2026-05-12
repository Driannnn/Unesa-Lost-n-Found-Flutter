import 'package:flutter/material.dart';
import 'package:lostnfoundunesa5/data/service/auth.service.dart';
import '../widgets/app_colors.dart';

/// Login screen with SSO button and manual NIM login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showManual = false;
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;
  bool _isNimLoading = false;

  // Deklarasi ganda dihapus agar tidak error
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handler untuk Google Sign-In via tombol SSO
  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;

    setState(() => _isGoogleLoading = true);

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryVerticalGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Upper section: Logo + features ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      // Logo
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.unesaGold.withOpacity(0.4),
                                width: 2,
                              ),
                            ),
                          ),
                          Container(
                            width: 112,
                            height: 112,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 16),
                              ],
                            ),
                            child: const Center(
                              child: Text('🎓', style: TextStyle(fontSize: 48)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'UNESA Lost & Found',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'PSDKU Magetan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.unesaGold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sistem pelaporan barang hilang dan temuan berbasis AI Matching',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Feature cards
                      _featureCard(
                        Icons.verified_user,
                        'Aman & Terverifikasi',
                        'Hanya untuk civitas akademika UNESA',
                      ),
                      const SizedBox(height: 8),
                      _featureCard(
                        Icons.bolt,
                        'AI Matching Otomatis',
                        'Rekomendasi kecocokan barang real-time',
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              // ── Bottom white sheet ──
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // SSO Button → sekarang memanggil Google Sign-In
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                        icon: _isGoogleLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login, size: 20),
                        label: Text(
                          _isGoogleLoading ? 'Menghubungkan...' : 'Login with SSO UNESA',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.unesaBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Manual login toggle
                    GestureDetector(
                      onTap: () => setState(() => _showManual = !_showManual),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person, size: 14, color: AppColors.mutedText),
                          const SizedBox(width: 6),
                          const Text(
                            'Login Manual dengan NIM',
                            style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _showManual ? Icons.expand_less : Icons.expand_more,
                            size: 14,
                            color: AppColors.mutedText,
                          ),
                        ],
                      ),
                    ),
                    // Manual login form
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          children: [
                            TextField(
                              controller: _nimController,
                              decoration: InputDecoration(
                                hintText: 'NIM (contoh: 21051204011)',
                                hintStyle: const TextStyle(fontSize: 14),
                                filled: true,
                                fillColor: const Color(0xFFF3F4F6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(fontSize: 14, color: Colors.black),
                            ),
                            const SizedBox(height: 8),
                            // Password field dengan hide/show toggle
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: const TextStyle(fontSize: 14),
                                filled: true,
                                fillColor: const Color(0xFFF3F4F6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    size: 20,
                                    color: AppColors.mutedText,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              style: const TextStyle(fontSize: 14, color: Colors.black),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: _isNimLoading
                                    ? null
                                    : () async {
                                        String nim = _nimController.text.trim();
                                        String password = _passwordController.text.trim();

                                        if (nim.isEmpty || password.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Harap isi semua kolom!")),
                                          );
                                          return;
                                        }

                                        setState(() => _isNimLoading = true);

                                        try {
                                          final user = await _authService.loginWithNIM(nim, password);

                                          if (user != null && mounted) {
                                            Navigator.pushReplacementNamed(context, '/home');
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text("Gagal Masuk"),
                                                content: Text(e.toString()),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text("OK"),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        } finally {
                                          if (mounted) {
                                            setState(() => _isNimLoading = false);
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.unesaBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isNimLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Masuk', style: TextStyle(fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      crossFadeState: _showManual
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Dengan masuk, Anda menyetujui syarat dan ketentuan aplikasi Lost & Found UNESA Magetan',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/admin-login'),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield, size: 14, color: AppColors.mutedText),
                          SizedBox(width: 6),
                          Text(
                            'Portal Admin / Satpam',
                            style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.unesaGold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}