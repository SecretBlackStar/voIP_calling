import 'package:flutter/material.dart';
import 'package:caller/services/auth.services.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _agreeToTerms = false;
  bool _loading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  final String primaryColor = "#B05AAD";
  final AuthService _authService = AuthService();

  Map<String, String> _errors = {
    "name": "",
    "email": "",
    "phone": "",
    "password": "",
    "confirmPassword": "",
  };

  bool _validateInputs() {
    bool valid = true;
    setState(() {
      _errors = {
        "name": _nameController.text.isEmpty ? "Name is required." : "",
        "email": _emailController.text.isEmpty
            ? "Email is required."
            : !_emailController.text.contains('@')
                ? "Enter a valid email."
                : "",
        "phone": _phoneController.text.isEmpty
            ? "Phone number is required."
            : !RegExp(r'^[0-9]+$').hasMatch(_phoneController.text)
                ? "Enter a valid phone number."
                : "",
        "password": _passwordController.text.isEmpty
            ? "Password is required."
            : _passwordController.text.length < 8
                ? "Password must be at least 8 characters."
                : "",
        "confirmPassword": _confirmPasswordController.text != _passwordController.text
            ? "Passwords do not match."
            : "",
      };
      valid = !_errors.values.any((error) => error.isNotEmpty);
    });
    return valid;
  }

  void _clearErrorOnChange(String field) {
    setState(() {
      _errors[field] = "";
    });
  }

Future<void> _handleRegister() async {
  if (!_validateInputs()) return;

  setState(() {
    _loading = true;
  });

  try {
    await _authService.registerUser(
      _emailController.text,
      _passwordController.text,
      _nameController.text,
      _phoneController.text,
    );

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
      _showAlert("Registration Successful", "Welcome!");
    }
  } catch (error) {
    if (mounted) {
      _showAlert("Registration Failed", error.toString());
    }
  } finally {
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }
}


  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => _clearErrorOnChange("name"));
    _emailController.addListener(() => _clearErrorOnChange("email"));
    _phoneController.addListener(() => _clearErrorOnChange("phone"));
    _passwordController.addListener(() => _clearErrorOnChange("password"));
    _confirmPasswordController.addListener(() => _clearErrorOnChange("confirmPassword"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUserIcon(),
              const SizedBox(height: 10),
              Text(
                "Create an Account",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(int.parse(primaryColor.replaceAll('#', '0xff'))),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Join us and unlock the best features tailored just for you.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              _buildInputField("Name", _nameController, _errors['name']),
              _buildInputField("Email", _emailController, _errors['email']),
              _buildInputField("Phone", _phoneController, _errors['phone'], keyboardType: TextInputType.phone),
              _buildPasswordField("Password", _passwordController, _errors['password'], _passwordVisible, () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              }),
              _buildPasswordField("Confirm Password", _confirmPasswordController, _errors['confirmPassword'], _confirmPasswordVisible, () {
                setState(() {
                  _confirmPasswordVisible = !_confirmPasswordVisible;
                });
              }),
              const SizedBox(height: 5),
              _buildTermsAndConditions(),
              const SizedBox(height: 15),
              _buildRegisterButton(),
              const SizedBox(height: 15),
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserIcon() {
    return CircleAvatar(
      radius: 60,
      backgroundColor: Color(int.parse(primaryColor.replaceAll('#', '0xff'))).withOpacity(0.2),
      child: Icon(
        Icons.person_outline,
        size: 80,
        color: Color(int.parse(primaryColor.replaceAll('#', '0xff'))),
      ),
    );
  }


  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String? error, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(int.parse(primaryColor.replaceAll('#', '0xff'))),
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(
                  color: Color(int.parse(primaryColor.replaceAll('#', '0xff'))),
                  width: 2,
                ),
              ),
              errorText: (error != null && error.isNotEmpty) ? error : null,
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    String? error,
    bool isVisible,
    VoidCallback toggleVisibility, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(int.parse(primaryColor.replaceAll('#', '0xff'))),
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: !isVisible,
            decoration: InputDecoration(
              suffixIcon: IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: toggleVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(
                  color: Color(int.parse(primaryColor.replaceAll('#', '0xff'))),
                  width: 2,
                ),
              ),
              errorText: (error != null && error.isNotEmpty) ? error : null,
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) {
            setState(() {
              _agreeToTerms = value!;
            });
          },
        ),
        const Expanded(
          child: Text(
            "I agree with the Terms and Conditions.",
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading || !_agreeToTerms ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(int.parse(primaryColor.replaceAll('#', '0xff'))),
          padding: const EdgeInsets.all(15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: _loading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Text(
                "Register",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(context, '/login'); 
      },
      child: RichText(
        text: TextSpan(
          text: "Already a member? ",
          style: const TextStyle(color: Colors.black, fontSize: 16),
          children: [
            TextSpan(
              text: "Login",
              style: TextStyle(
                color: Color(int.parse(primaryColor.replaceAll('#', '0xff'))),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
