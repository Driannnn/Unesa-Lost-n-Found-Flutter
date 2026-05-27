import 'package:flutter/material.dart';
import '../widgets/app_colors.dart';
import '../../data/service/admin_service.dart';

/// Admin login screen for security guards and campus admins.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  String? _error;

  final AdminService _adminService = AdminService();

  static const _accounts = [
    {'username': 'satpam', 'password': 'admin123', 'role': 'Satpam'},
    {'username': 'adminit', 'password': 'admin123', 'role': 'Admin IT'},
    {'username': 'koordinator', 'password': 'admin123', 'role': 'Koordinator Keamanan'},
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Username dan password wajib diisi.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _adminService.loginAdmin(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (result == null) {
        setState(() => _error = 'Username atau password salah.');
        return;
      }

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/admin-dashboard',
          arguments: {
            'adminName': result['name'] ?? 'Admin',
            'adminRole': result['role'] ?? 'Satpam',
            'adminUsername': result['username'] ?? '',
          },
        );
      }
    } catch (e) {
      setState(() => _error = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF002244), Color(0xFF003366), Color(0xFF004488)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                // Back
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        Icon(Icons.chevron_left, size: 20, color: Colors.white.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text('Kembali ke Login Mahasiswa',
                            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
                      ],
                    ),
                  ),
                ),

                // Logo + info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo with shield
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
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
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo_unesa.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -4, right: -4,
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.unesaGold,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                              ),
                              child: const Icon(Icons.shield, size: 16, color: AppColors.unesaBlue),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Portal Admin',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('UNESA Lost & Found · PSDKU Magetan',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.unesaGold)),
                      const SizedBox(height: 4),
                      Text('Akses khusus petugas keamanan & admin kampus',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
                      const SizedBox(height: 16),
                      // Role badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: _accounts.map((a) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shield, size: 12, color: AppColors.unesaGold),
                                  const SizedBox(width: 6),
                                  Text(a['role']!,
                                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                                ],
                              ),
                            )).toList(),
                      ),
                    ],
                  ),
                ),

                // ── Form ──
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Masuk sebagai Petugas',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.unesaBlue)),
                      const SizedBox(height: 20),
                      // Username
                      const Text('Username / ID Petugas',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedText)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _usernameController,
                        onSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person, size: 16, color: AppColors.mutedText),
                          hintText: 'Username',
                          hintStyle: const TextStyle(fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      const SizedBox(height: 16),
                      // Password
                      const Text('Password',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedText)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        onSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock, size: 16, color: AppColors.mutedText),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _showPassword = !_showPassword),
                            child: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, size: 16, color: AppColors.mutedText),
                          ),
                          hintText: 'Password',
                          hintStyle: const TextStyle(fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            border: Border.all(color: const Color(0xFFFECACA)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.danger)),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Demo credentials
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.unesaLightBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Demo credentials:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.unesaBlue)),
                            const SizedBox(height: 4),
                            ..._accounts.map((a) => GestureDetector(
                                  onTap: () {
                                    _usernameController.text = a['username']!;
                                    _passwordController.text = a['password']!;
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      '→ ${a['username']} / ${a['password']} (${a['role']})',
                                      style: TextStyle(fontSize: 12, color: AppColors.unesaBlue.withOpacity(0.7)),
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleLogin,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.shield, size: 16),
                          label: Text(
                            _isLoading ? 'Memverifikasi...' : 'Masuk ke Portal Admin',
                            style: const TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.unesaBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text('Akses ini terbatas untuk petugas yang berwenang',
                            style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
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
