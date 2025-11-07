import 'package:flutter/material.dart';
import '../utils/brand_colors.dart';
import '../screens/podcast/podcast_screen.dart';
import '../screens/academy/academy_screen.dart';
import '../screens/tutorials/tutorials_screen.dart';
import '../screens/enterprise/enterprise_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PodcastScreen(),
    const TutorialsScreen(),
    const AcademyScreen(),
    const EnterpriseScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.radio_outlined),
      activeIcon: Icon(Icons.radio),
      label: 'Podcast',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.play_lesson_outlined),
      activeIcon: Icon(Icons.play_lesson),
      label: 'Tutoriales',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.school_outlined),
      activeIcon: Icon(Icons.school),
      label: 'Academia',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.business_outlined),
      activeIcon: Icon(Icons.business),
      label: 'Empresarial',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: BrandColors.primaryBlack,
          border: Border(
            top: BorderSide(
              color: BrandColors.primaryOrange,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: BrandColors.primaryBlack,
          selectedItemColor: BrandColors.primaryOrange,
          unselectedItemColor: BrandColors.grayMedium,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
          ),
          items: _navItems,
        ),
      ),
    );
  }
}
