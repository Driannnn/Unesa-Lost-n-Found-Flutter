import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getter untuk user saat ini
  User? get currentUser => _auth.currentUser;

  // Stream untuk mendengarkan perubahan status auth
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Fungsi Login menggunakan Google Sign-In (Firebase Popup untuk Web)
  Future<User?> signInWithGoogle() async {
    try {
      // Membuat provider Google
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Menambahkan scope untuk mendapatkan email dan profil
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // Memaksa pilih akun setiap kali login
      googleProvider.setCustomParameters({
        'prompt': 'select_account',
      });

      // Melakukan sign in dengan popup (untuk Web)
      UserCredential result = await _auth.signInWithPopup(googleProvider);

      print('Google Sign-In berhasil: ${result.user?.email}');
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'account-exists-with-different-credential') {
        throw 'Akun sudah terdaftar dengan metode login lain.';
      } else if (e.code == 'popup-closed-by-user') {
        throw 'Login dibatalkan oleh pengguna.';
      } else if (e.code == 'cancelled-popup-request') {
        throw 'Permintaan popup dibatalkan.';
      }
      throw 'Gagal login dengan Google: ${e.message}';
    } catch (e) {
      print('Error Google Sign-In: $e');
      throw 'Terjadi kesalahan saat login dengan Google. Coba lagi.';
    }
  }

  // Fungsi Login menggunakan NIM
  Future<User?> loginWithNIM(String inputNim, String password) async {
    try {
      String email = inputNim;

      // Cek apakah user sudah mengetikkan @ di inputannya
      // Jika belum ada @, maka sistem yang akan menambahkannya otomatis
      if (!inputNim.contains('@')) {
        email = "$inputNim@mhs.unesa.ac.id";
      }

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result.user;
    } on FirebaseAuthException catch (e) {
      // Menangani error spesifik (Berguna untuk Test Case TC002)
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        throw 'NIM atau Password salah. Silakan coba lagi.';
      }
      throw 'Terjadi kesalahan sistem. Coba lagi nanti.';
    } catch (e) {
      throw e.toString();
    }
  }

  // Fungsi Logout (Memenuhi TC018)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
