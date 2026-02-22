import 'package:flutter/material.dart';
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
    if (userAge >= 13 && userAge <= 15) {
      return HomeScreenYoung(userData: widget.userData);
    } else if (userAge >= 16 && userAge <= 19) {
      return HomeScreenTeen(userData: widget.userData);
    } else {
      return HomeScreenYoungAdult(userData: widget.userData);
    }
  }
}
