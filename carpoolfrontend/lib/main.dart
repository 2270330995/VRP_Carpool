import 'package:flutter/material.dart';

import 'pages/plan_carpool_page.dart';

const Color _softBlue = Color(0xFF5DA9E9);
const Color _mintGreen = Color(0xFF7ED957);
const Color _warmWhite = Color(0xFFFFFAF2);
const Color _ink = Color(0xFF28445C);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _softBlue,
      brightness: Brightness.light,
      primary: _softBlue,
      secondary: _mintGreen,
      surface: Colors.white,
    );

    return MaterialApp(
      title: 'Carpool',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: _warmWhite,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: _ink,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          shadowColor: _softBlue.withValues(alpha: 0.14),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _softBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: _softBlue.withValues(alpha: 0.5)),
            foregroundColor: _ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _softBlue.withValues(alpha: 0.25)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _softBlue.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _softBlue, width: 1.4),
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carpool')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5DA9E9), Color(0xFF7ED957)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.family_restroom,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Family Carpool Planner',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Safe, friendly, and organized rides for students.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x1F7ED957),
                  child: Icon(Icons.directions_car_filled, color: _ink),
                ),
                title: const Text('Plan and optimize routes'),
                subtitle: const Text(
                  'Set destination, drivers, and passengers',
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlanCarpoolPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
