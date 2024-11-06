import 'package:caller/pages/ougoingcall.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:caller/services/auth.services.dart';
import 'package:caller/services/contact.services.dart';
import 'package:caller/pages/call.dart';
import 'package:caller/utils/types.dart';

class DialNumberPage extends StatefulWidget {
  @override
  _DialNumberPageState createState() => _DialNumberPageState();
}

class _DialNumberPageState extends State<DialNumberPage> {
  final TextEditingController _phoneController = TextEditingController();
  List<Contact> filteredContacts = [];
  static const Color primaryColor = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => _filterContacts(_phoneController.text));
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    final contacts = await contactService
        .getAllContacts(); // Assuming this method returns a List<Contact>
    setState(() {
      filteredContacts = contacts;
    });
  }

  void _filterContacts(String query) {
    setState(() {
      filteredContacts =
          filteredContacts.where((c) => c.phoneNumber.contains(query)).toList();
    });
  }

  void _handleDelete() {
    if (_phoneController.text.isNotEmpty) {
      setState(() {
        _phoneController.text = _phoneController.text
            .substring(0, _phoneController.text.length - 1);
      });
    }
  }

  void _handleCall() async {
    final phoneNumber = _phoneController.text;
    final user = await authService.getCurrentUser();
    
    if (user != null && phoneNumber.isNotEmpty && mounted) {
      if (user.airtime >= 10) {
        _joinCall(calleeId: phoneNumber);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Sorry, you cannot make a call with airtime below 10 seconds')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a phone number')),
        );
      }
    }
  }

  _joinCall({required String calleeId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OutgoingCallPage(
          calleeId: calleeId,
        ),
      ),
    );
  }

  Widget _buildContactItem(Contact contact) {
    return ListTile(
      title: Text(contact.name, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(contact.phoneNumber),
      onTap: () {
        _phoneController.text = contact.phoneNumber;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: primaryColor),
            onPressed: () {
              Navigator.of(context).pushNamed(
                '/addcontact',
                arguments: {'callerId': _phoneController.text},
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: filteredContacts.isEmpty
                ? Center(child: Text("No contacts found"))
                : ListView.builder(
                    itemCount: filteredContacts.length,
                    itemBuilder: (context, index) =>
                        _buildContactItem(filteredContacts[index]),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      hintText: 'Enter phone number',
                      border: OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.call, size: 36, color: primaryColor),
                  onPressed: _handleCall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
