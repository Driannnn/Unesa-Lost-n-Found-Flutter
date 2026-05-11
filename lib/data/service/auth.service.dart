import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
