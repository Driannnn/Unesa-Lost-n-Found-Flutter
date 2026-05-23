import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getter untuk user saat ini
  User? get currentUser => _auth.currentUser;

  // Stream untuk mendengarkan perubahan status auth
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Fungsi Login menggunakan Google Sign-In (platform-aware: popup di Web, native di Mobile)
  Future<User?> signInWithGoogle() async {
    try {
      UserCredential result;

      if (kIsWeb) {
        // Web: pakai signInWithPopup
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({
          'prompt': 'select_account',
        });

        result = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile (Android/iOS): pakai package google_sign_in lalu sign in dengan credential
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );

        // Memaksa pilih akun setiap kali login
        await googleSignIn.signOut();

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          // User membatalkan dialog pemilihan akun
          throw 'Login dibatalkan oleh pengguna.';
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        result = await _auth.signInWithCredential(credential);
      }

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
      } else if (e.code == 'invalid-credential') {
        throw 'Credential Google tidak valid.';
      }
      throw 'Gagal login dengan Google: ${e.message}';
    } catch (e) {
      print('Error Google Sign-In: $e');
      // Re-throw pesan yang sudah ramah user
      if (e is String) rethrow;
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
