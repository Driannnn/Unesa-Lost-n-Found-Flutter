import 'package:flutter/material.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/report_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/chat_screen.dart';
import 'presentation/screens/match_details_screen.dart';
import 'presentation/screens/admin_login_screen.dart';
import 'presentation/screens/admin_dashboard_screen.dart';

void main() {
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
        '/chat': (context) => const ChatScreen(),
        '/match-details': (context) => const MatchDetailsScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
      },
    );
  }
}
