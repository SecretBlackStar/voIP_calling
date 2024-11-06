import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/types.dart';

class ContactService {
  final CollectionReference contactsCollection = FirebaseFirestore.instance.collection('contacts');

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = prefs.getString('currentUser');
    if (currentUser != null) {
      final user = jsonDecode(currentUser) as Map<String, dynamic>;
      return user['uid'] as String?;
    }
    return null;
  }

  Future<void> persistContactData() async {
    final contacts = await getAllContacts();
    if (contacts is List<Contact>) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userContacts', jsonEncode(contacts.map((e) => e.toMap()).toList()));
    }
  }

  Future<String> addContact(String name, String phoneNumber) async {
    final userId = await getCurrentUserId();
    if (userId == null) return 'User not logged in. Please log in to add a contact.';

    final newContact = Contact(name: name, phoneNumber: phoneNumber, owner: userId);
    final contactDoc = contactsCollection.doc();
    await contactDoc.set(newContact.toMap());

    await persistContactData();
    return 'Contact successfully added.';
  }

  Future<dynamic> getAllContacts() async {
    // final prefs = await SharedPreferences.getInstance();
    // final storedContacts = prefs.getString('userContacts');
    // if (storedContacts != null) {
    //   return (jsonDecode(storedContacts) as List).map((contact) => Contact.fromMap(contact as Map<String, dynamic>)).toList();
    // }
    
    final userId = await getCurrentUserId();
    if (userId == null) return 'User not logged in. Please log in to view your contacts.';

    final contactsQuery = contactsCollection.where('owner', isEqualTo: userId);
    final querySnapshot = await contactsQuery.get();

    final contacts = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Contact.fromFirestore(data)..id = doc.id;
    }).toList();

    return contacts.isNotEmpty ? contacts : 'No contacts found for the current user.';
  }

  Future<String> deleteContact(String contactId) async {
    final userId = await getCurrentUserId();
    if (userId == null) return 'User not logged in. Please log in to delete a contact.';

    final contactDoc = contactsCollection.doc(contactId);
    final contactSnapshot = await contactDoc.get();

    if (!contactSnapshot.exists) return 'Contact not found.';
    if ((contactSnapshot.data() as Map<String, dynamic>)['owner'] != userId) return 'You can only delete your own contacts.';

    await contactDoc.delete();
    await persistContactData();
    return 'Contact successfully deleted.';
  }

  Future<String> updateContact(String contactId, Map<String, dynamic> updatedData) async {
    final userId = await getCurrentUserId();
    if (userId == null) return 'User not logged in. Please log in to update a contact.';

    final contactDoc = contactsCollection.doc(contactId);
    final contactSnapshot = await contactDoc.get();

    if (!contactSnapshot.exists) return 'Contact not found.';
    if ((contactSnapshot.data() as Map<String, dynamic>)['owner'] != userId) return 'You can only update your own contacts.';

    await contactDoc.update(updatedData);
    await persistContactData();
    return 'Contact successfully updated.';
  }
}

final ContactService contactService = ContactService();
