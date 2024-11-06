
import 'package:flutter/material.dart';
import 'package:caller/services/contact.services.dart'; // Ensure this is correct
import 'package:caller/utils/types.dart'; // Import the correct Contact class

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    setState(() => loading = true);

    final result = await contactService.getAllContacts();
    if (result is List<Contact>) {
      contacts = result;
      filteredContacts = contacts;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    }

    setState(() => loading = false);
  }

  void handleSearch(String query) {
    setState(() {
      filteredContacts = query.isEmpty
          ? contacts
          : contacts.where((contact) {
              return contact.name.toLowerCase().contains(query.toLowerCase());
            }).toList();
    });
  }

  List<SectionData> groupContactsByAlphabet(List<Contact> contacts) {
    Map<String, List<Contact>> grouped = {};

    for (var contact in contacts) {
      String firstChar = RegExp(r'^[0-9]').hasMatch(contact.name) ? '#' : contact.name[0].toUpperCase();
      if (!grouped.containsKey(firstChar)) {
        grouped[firstChar] = [];
      }
      grouped[firstChar]!.add(contact);
    }

    List<SectionData> sections = grouped.keys.map((key) {
      return SectionData(title: key, contacts: grouped[key]!);
    }).toList();

    sections.sort((a, b) => a.title.compareTo(b.title));
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search favorite contacts',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
                ),
                onChanged: handleSearch,
              ),
              SizedBox(height: 20),
              loading
                  ? Center(child: CircularProgressIndicator(color: Color(0xFF007BFF)))
                  : Expanded(
                      child: filteredContacts.isNotEmpty
                          ? SectionList(
                              sections: groupContactsByAlphabet(filteredContacts),
                            )
                          : Center(
                              child: Text(
                                _searchController.text.isNotEmpty
                                    ? 'No contacts found matching your search.'
                                    : 'No favorite contacts yet.',
                                style: TextStyle(color: Color(0xFF777777)),
                                textAlign: TextAlign.center,
                              ),
                            ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionData {
  final String title;
  final List<Contact> contacts;

  SectionData({required this.title, required this.contacts});
}

class SectionList extends StatelessWidget {
  final List<SectionData> sections;

  SectionList({required this.sections});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: sections.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        final section = sections[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                section.title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...section.contacts.map((contact) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(0xFF6C63FF),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(contact.name, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(contact.phoneNumber),
                onTap: () {
                  // Handle contact tap
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
