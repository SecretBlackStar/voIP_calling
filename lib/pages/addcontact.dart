import 'package:flutter/material.dart';
import 'package:caller/services/contact.services.dart';

class AddContactPage extends StatefulWidget {
  final String? callerId;

  AddContactPage({this.callerId});

  @override
  _AddContactPageState createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final TextEditingController _nameController = TextEditingController();
  final Color mainColor = Color(0xFFB05AAD);
  late TextEditingController _phoneController;
  bool isLoading = false;
  Map<String, String?> errors = {'name': null, 'phoneNumber': null};

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.callerId ?? '');
  }

  void handleSave() async {
    setState(() {
      errors = {
        'name': _nameController.text.isEmpty ? 'Name is required.' : null,
        'phoneNumber':
            _phoneController.text.isEmpty ? 'Phone number is required.' : null,
      };
    });

    if (errors.values.any((error) => error != null)) return;

    setState(() => isLoading = true);

    final response = await contactService.addContact(
      _nameController.text,
      _phoneController.text,
    );

    setState(() => isLoading = false);

    if (response == "Contact successfully added.") {
      Navigator.of(context).pushNamed('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response)),
      );
    }
  }

  void handleInputChange(String field, String value) {
    setState(() {
      errors[field] = value.isEmpty
          ? '${field == 'name' ? 'Name' : 'Phone number'} is required.'
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add new contact'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: mainColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Please fill in the fields below to create a new contact. Both fields are required.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.black54),
                  hintText: 'Enter name',
                  errorText: errors['name'],
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(50), // Fully rounded corners
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
                onChanged: (value) => handleInputChange('name', value),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: Colors.black54),
                  hintText: 'Enter callerId number',
                  errorText: errors['phoneNumber'],
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(50), // Fully rounded corners
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
                onChanged: (value) => handleInputChange('phoneNumber', value),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(50), // Fully rounded button
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white), // Smaller activity indicator
                      )
                    : Text(
                        'Save Contact',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
