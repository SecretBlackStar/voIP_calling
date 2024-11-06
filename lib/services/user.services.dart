import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/types.dart';

class UserService {
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('currentUser');
    return userData != null ? User.fromJson(jsonDecode(userData)) : null;
  }

  Future<void> saveCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUser', jsonEncode(user.toJson()));
  }

  Future<void> updateUser(Map<String, dynamic> update) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) throw Exception('No user is currently logged in.');

      final updatedUser = currentUser.copyWith(update);
      await saveCurrentUser(updatedUser);
      
      print('User updated successfully: $updatedUser');
    } catch (error) {
      print('Error updating user: $error');
      throw Exception('Failed to update user.');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUser');
      print('User account deleted successfully.');
    } catch (error) {
      print('Error deleting account: $error');
      throw Exception('Failed to delete account.');
    }
  }
}

final UserService userService = UserService();
