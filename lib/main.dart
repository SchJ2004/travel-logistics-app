import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/dashboard_screen.dart';

Future<void> main() async {
  // 1. Ensure Flutter is ready before we talk to the database
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Wake up the Database Connection!
  // ---> PASTE YOUR KEYS HERE <---
  await Supabase.initialize(
    url: 'https://ongyhyjodwkbmjhkzmbc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9uZ3loeWpvZHdrYm1qaGt6bWJjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcwNzYyMjMsImV4cCI6MjA5MjY1MjIyM30.Q7_5I-b2LxLinW9vTipvpy2VB-KQpVRyaNn7HVAJelQ',
  );

  runApp(const TravelApp());
}

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Logistics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          surface: Color(0xFF1E293B),
        ),
        useMaterial3: true,
      ),
      // 3. Boot straight to the Dashboard
      home: const DashboardScreen(),
    );
  }
}
