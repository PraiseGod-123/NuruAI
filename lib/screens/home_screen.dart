import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/nuru_colors.dart';
import 'home_screen_young.dart';
import 'home_screen_teen.dart';
import 'home_screen_young_adult.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const HomeScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final userAge = widget.userData?['age'] ?? 18;

    // Route to appropriate home screen based on age
    // Under 13 or unknown → young (most conservative, safest content)
    // 13–15 → young
    // 16–19 → teen
    // 20+ → young adult
    if (userAge <= 15) {
      return HomeScreenYoung(userData: widget.userData);
    } else if (userAge <= 19) {
      return HomeScreenTeen(userData: widget.userData);
    } else {
      return HomeScreenYoungAdult(userData: widget.userData);
    }
  }
}
