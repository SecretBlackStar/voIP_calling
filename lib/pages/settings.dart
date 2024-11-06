import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Color mainColor = Color(0xFFB05AAD);

  Future<void> handleLogout() async {
    try {
      await Future.delayed(Duration(seconds: 1)); // Simulate logout process
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (error) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Error'),
          content: Text(error.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: mainColor)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/profile'),
              child: buildSectionOption('Account', Icons.person),
            ),
            Divider(color: Colors.grey[300], thickness: 1),

            // Logout Option
            GestureDetector(
              onTap: handleLogout,
              child: buildSectionOption('Logout', Icons.logout),
            ),
            Divider(color: Colors.grey[300], thickness: 1),
          ],
        ),
      ),
    );
  }

  Widget buildSectionOption(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: mainColor),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
