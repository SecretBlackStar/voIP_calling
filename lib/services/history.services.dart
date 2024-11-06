import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  final CollectionReference historyCollection =
      FirebaseFirestore.instance.collection('callHistory');
  final String _historyKey = 'callHistory';

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = prefs.getString('currentUser');
    if (currentUser != null) {
      final user = jsonDecode(currentUser) as Map<String, dynamic>;
      return user['uid'] as String?;
    }
    return null;
  }

  Future<void> createCallHistory(String from, String to, int duration) async {
    final userId = await getCurrentUserId();
    if (userId == null) return;

    // Create call history in Firestore
    await historyCollection.add({
      'from': from,
      'to': to,
      'duration': duration,
      'owner': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update local cache
    await _updateLocalCache(from, to, duration);
  }

  Future<List<Map<String, dynamic>>> getCallHistory() async {
    // First, try to get data from local cache
    final cachedHistory = await _getLocalCache();
    if (cachedHistory.isNotEmpty) return cachedHistory;

    // If cache is empty, fetch from Firestore
    final userId = await getCurrentUserId();
    if (userId == null) return [];

    final querySnapshot = await historyCollection
        .where('owner', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    // Convert Firestore documents to local history format
    final historyList = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'from': data['from'],
        'to': data['to'],
        'duration': data['duration'],
        'timestamp': data['timestamp'],
      };
    }).toList();

    // Cache fetched data locally
    await _cacheLocalHistory(historyList);

    return historyList;
  }

  Future<void> updateCallHistory(
      String id, Map<String, dynamic> updatedData) async {
    await historyCollection.doc(id).update(updatedData);

    // Update local cache if needed
    List<Map<String, dynamic>> cachedHistory = await _getLocalCache();
    final index = cachedHistory.indexWhere((entry) => entry['id'] == id);
    if (index != -1) {
      cachedHistory[index] = {...cachedHistory[index], ...updatedData};
      await _cacheLocalHistory(cachedHistory);
    }
  }

  Future<void> deleteCallHistory(String id) async {
    await historyCollection.doc(id).delete();

    // Remove from local cache
    List<Map<String, dynamic>> cachedHistory = await _getLocalCache();
    cachedHistory.removeWhere((entry) => entry['id'] == id);
    await _cacheLocalHistory(cachedHistory);
  }

  Future<void> _updateLocalCache(String from, String to, int duration) async {
    List<Map<String, dynamic>> cachedHistory = await _getLocalCache();
    cachedHistory.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
      'from': from,
      'to': to,
      'duration': duration,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _cacheLocalHistory(cachedHistory);
  }

  Future<void> _cacheLocalHistory(List<Map<String, dynamic>> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(history));
  }

  Future<List<Map<String, dynamic>>> _getLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_historyKey);
    if (cachedData != null) {
      return (jsonDecode(cachedData) as List)
          .map((entry) => entry as Map<String, dynamic>)
          .toList();
    }
    return [];
  }
}

final HistoryService historyService = HistoryService();
