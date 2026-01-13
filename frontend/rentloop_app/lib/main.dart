import 'package:flutter/material.dart';
import 'features/auth/login_page.dart';

void main() {
  runApp(const RentLoopApp());
}

class RentLoopApp extends StatelessWidget {
  const RentLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RentLoop',
      home: const LoginPage(),
    );
  }
}
