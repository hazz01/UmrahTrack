import 'package:flutter/material.dart';

class BottomNavbarAdmin extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavbarAdmin({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Jamaah'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'OpenMap'),
        BottomNavigationBarItem(icon: Icon(Icons.warning), label: '[Upcoming]'),
        BottomNavigationBarItem(icon: Icon(Icons.warning), label: '[Upcoming]'),
        BottomNavigationBarItem(icon: Icon(Icons.warning), label: '[Upcoming]'),
      ],
    );
  }
}
