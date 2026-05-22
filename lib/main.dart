import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import screen Anda
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/report_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/chat_screen.dart';
import 'presentation/screens/chat_list_screen.dart';
import 'presentation/screens/match_details_screen.dart';
import 'presentation/screens/admin_login_screen.dart';
import 'presentation/screens/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // // --- TAMBAHKAN 2 BARIS INI UNTUK TESTING ---
  // print("CEK API KEY: ${dotenv.env['FIREBASE_API_KEY']}");
  // print("CEK PROJECT ID: ${dotenv.env['FIREBASE_PROJECT_ID']}");

  // 3. Menyalakan mesin Firebase sesuai platform (Web atau Android)
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
        measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'],
      ),
    );
  } else {
    // Untuk Android akan otomatis menggunakan google-services.json
    await Firebase.initializeApp();
  }

  // 4. Menjalankan aplikasi
  runApp(const UnesaLostFoundApp());
}

class UnesaLostFoundApp extends StatelessWidget {
  const UnesaLostFoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNESA Lost & Found',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003366),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/report-lost': (context) => const ReportScreen(isLost: true),
        '/report-found': (context) => const ReportScreen(isLost: false),
        '/dashboard': (context) => const DashboardScreen(),
        '/chat': (context) => const ChatListScreen(),
        '/chat-room': (context) => const ChatScreen(),
        '/match-details': (context) => const MatchDetailsScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
      },
    );
  }
}
