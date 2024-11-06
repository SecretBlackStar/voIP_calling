import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caller/utils/types.dart';

class AuthService {
  Future<String> hashPassword(String password) async {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> comparePasswords(String plainPassword, String hashedPassword) async {
    var hashedInput = await hashPassword(plainPassword);
    return hashedInput == hashedPassword;
  }

  Future<User?> getUserByEmailOrPhone(String email, String phone) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    
    var emailQuery = await usersRef.where('email', isEqualTo: email).get();
    if (emailQuery.docs.isNotEmpty) {
      return  User.fromFirestore(emailQuery.docs.first.data());
    }

    var phoneQuery = await usersRef.where('phone', isEqualTo: phone).get();
    if (phoneQuery.docs.isNotEmpty) {
      return User.fromFirestore(phoneQuery.docs.first.data());
    }

    return null;
  }

  Future<dynamic> registerUser(String email, String password, String name, String phone) async {
    var existingUser = await getUserByEmailOrPhone(email, phone);
    if (existingUser != null) {
      return 'A user with this email or phone number already exists.';
    }
    print(password);
    var hashedPassword = await hashPassword(password);
    print(hashedPassword);
    var uid = DateTime.now().millisecondsSinceEpoch.toString();
    var callerId = uid.substring(uid.length - 10); // Last 10 digits of UID

    var customUser = User(
      uid: uid,
      email: email,
      name: name,
      phone: phone,
      password: hashedPassword,
      role: 'USER',
      airtime: 0,
      callerId: callerId,
    );

    await FirebaseFirestore.instance.collection('users').doc(uid).set(customUser.toMap());
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUser', jsonEncode(customUser.toMap()..remove('password')));
    return customUser.toMap()..remove('password');
  }

  Future<dynamic> loginUser(String identifier, String password) async {
    var userData = await getUserByEmailOrPhone(identifier, identifier);
    if (userData != null) {
      var isPasswordValid = await comparePasswords(password, userData.password!);
      if (isPasswordValid) {
        var prefs = await SharedPreferences.getInstance();
        await prefs.setString('currentUser', jsonEncode(userData.toMap()..remove('password')));
        return userData.toMap()..remove('password');
      }
      throw Exception('Incorrect password.');
    }
    throw Exception('User not found.');
  }

    Future<void> logoutUser() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser');
  }

  Future<User?> getUserData(String uid) async {
    var userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    var userSnapshot = await userDoc.get();
    return userSnapshot.exists ? User.fromFirestore(userSnapshot.data()!) : null;
  }

  Future<String?> resetPassword(String email, String newPassword) async {
    var userDoc = FirebaseFirestore.instance.collection('users').doc(email);
    var userSnapshot = await userDoc.get();
    if (userSnapshot.exists) {
      var hashedPassword = await hashPassword(newPassword);
      await userDoc.set({'password': hashedPassword}, SetOptions(merge: true));
    } else {
      return 'User not found.';
    }
  }



  Future<void> deleteUser(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    var prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser');
  }

Future<void> updateUser(Map<String, dynamic> update) async {
  var currentUser = await getCurrentUser();
  if (currentUser == null) throw Exception('No user is currently logged in.');
  await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .set(update, SetOptions(merge: true));
  var prefs = await SharedPreferences.getInstance();
  var existingUserData = jsonDecode(prefs.getString('currentUser') ?? '{}');
  existingUserData.addAll(update);
  await prefs.setString('currentUser', jsonEncode(existingUserData..remove('password')));
}


  Future<User?> getCurrentUser() async {
    var prefs = await SharedPreferences.getInstance();
    var userJson = prefs.getString('currentUser');
    return userJson != null ? User.fromJson(jsonDecode(userJson)) : null;
  }

  Future<String?> changeCallerId() async {
    var currentUser = await getCurrentUser();
    if (currentUser == null) throw Exception('No user is currently logged in.');

    String newCallerId;
    do {
      newCallerId = generateRandomCallerId();
    } while (await isCallerIdExists(newCallerId));

    currentUser.callerId = newCallerId;
    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set(
      {'callerId': newCallerId}, 
      SetOptions(merge: true)
    );

    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUser', jsonEncode(currentUser.toMap()..remove('password')));
    return newCallerId;
  }

  String generateRandomCallerId() {
    Random random = Random();
    String callerId = '';
    for (int i = 0; i < 10; i++) {
      callerId += random.nextInt(10).toString();
    }
    return callerId;
  }

  Future<bool> isCallerIdExists(String callerId) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('callerId', isEqualTo: callerId)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}

final AuthService authService = AuthService();
