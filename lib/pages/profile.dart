import 'package:flutter/material.dart';
import 'package:caller/services/auth.services.dart';

class ProfileEditPage extends StatefulWidget {
  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final Color mainColor = Color(0xFFB05AAD);

  // Controllers for form fields
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _callerIdController;

  bool _isSavingChanges = false;
  bool _isGeneratingCallerId = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with empty strings
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _callerIdController = TextEditingController();

    _loadUserData();
  }

  @override
  void dispose() {
    // Dispose of controllers when the widget is removed from the widget tree
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _callerIdController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    var user = await authService.getCurrentUser();
    if (user != null) {
      setState(() {
        // Set controller values to user data
        _nameController.text = user.name ?? '';
        _emailController.text = user.email ?? '';
        _phoneController.text = user.phone ?? '';
        _callerIdController.text = user.callerId ?? '';
      });
    }
  }

  void _onFieldChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSavingChanges = true);

    // Use controller values to save updated data
    var updatedData = {
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
    };

    // Save changes logic here with `updatedData`

    setState(() {
      _isSavingChanges = false;
      _hasChanges = false;
    });
  }

  Future<void> _generateNewCallerId() async {
    setState(() => _isGeneratingCallerId = true);
    var newCallerId = await authService.changeCallerId();
    if (newCallerId != null) {
      setState(() {
        _callerIdController.text = newCallerId;
        _isGeneratingCallerId = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(color: mainColor)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: mainColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                onChanged: _onFieldChanged,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Main User Data',
                        style: TextStyle(fontSize: 18, color: mainColor)),
                    SizedBox(height: 16),
                    _buildTextField(
                      'Name',
                      _nameController,
                      validator: (value) =>
                          value!.isEmpty ? 'Name cannot be empty' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Email',
                      _emailController,
                      validator: (value) => value!.isEmpty ||
                              !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)
                          ? 'Enter a valid email'
                          : null,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Phone',
                      _phoneController,
                      validator: (value) => value!.isEmpty || value.length < 10
                          ? 'Enter a valid phone number'
                          : null,
                      keyboardType: TextInputType.phone,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ElevatedButton(
                          onPressed: _hasChanges && !_isSavingChanges
                              ? _saveChanges
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: _isSavingChanges
                              ? Text('Loading...')
                              : Text('Save Changes'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildSectionDivider(),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Caller ID',
                      style: TextStyle(fontSize: 18, color: mainColor)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _callerIdController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Caller ID',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: ElevatedButton(
                        onPressed: !_isGeneratingCallerId
                            ? _generateNewCallerId
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _isGeneratingCallerId
                            ? Text('Loading...')
                            : Text('Generate New Caller ID'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String placeholder,
    TextEditingController controller, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: placeholder,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Divider(
      color: Colors.grey[300],
      thickness: 1,
      height: 32,
    );
  }
}
