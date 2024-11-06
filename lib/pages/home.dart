import 'package:flutter/material.dart';
import 'package:caller/services/auth.services.dart';
import 'dashboard.dart'; 
import 'history.dart'; 
import 'contact.dart'; 
import 'settings.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  final Color primaryColor = Color(0xFF6C63FF); // Main color for the app
  final Color inactiveColor = Color(0xFFBDBDBD); // Lighter shade for inactive items

  final List<Widget> _pages = [
    HomePage(),
    HistoryPage(),
    ContactsPage(),
    SettingsPage(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: onTabTapped,
        selectedItemColor: primaryColor,
        unselectedItemColor: inactiveColor,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600), // Bold for active tab
        items: [
          BottomNavigationBarItem(
            icon: Icon(_currentIndex == 0 ? Icons.home_filled : Icons.home_outlined, size: 28),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(_currentIndex == 1 ? Icons.history_edu : Icons.history, size: 28),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(_currentIndex == 2 ? Icons.contact_phone : Icons.contact_phone_outlined, size: 28),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(_currentIndex == 3 ? Icons.settings_suggest : Icons.settings_outlined, size: 28),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _currentIndex != 3
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/dial');
              },
              backgroundColor: primaryColor,
              tooltip: 'Dial Pad',
              child: const Icon(Icons.dialpad, size: 30,color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
