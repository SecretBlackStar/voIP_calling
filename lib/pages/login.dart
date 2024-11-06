import 'package:flutter/material.dart';
import 'package:caller/services/auth.services.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailOrPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _loading = false;
  final String primaryColor = "#B05AAD";
  Map<String, String> _errors = {'emailOrPhone': '', 'password': ''};
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _emailOrPhoneController.addListener(() => _clearErrorOnChange('emailOrPhone'));
    _passwordController.addListener(() => _clearErrorOnChange('password'));
  }

  void _clearErrorOnChange(String field) {
    setState(() {
      _errors[field] = '';
    });
  }

  bool _validateInputs() {
    bool valid = true;
    setState(() {
      _errors['emailOrPhone'] = _emailOrPhoneController.text.isEmpty
          ? 'Email or phone is required.'
          : '';
      _errors['password'] = _passwordController.text.isEmpty
          ? 'Password is required.'
          : _passwordController.text.length < 8
              ? 'Password must be at least 8 characters.'
              : '';
      valid = !_errors.values.any((error) => error.isNotEmpty);
    });
    return valid;
  }

Future<void> _handleLogin() async {
  if (!_validateInputs()) return;

  setState(() {
    _loading = true;
  });

  try {
    await _authService.loginUser(
      _emailOrPhoneController.text,
      _passwordController.text,
    );
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  } catch (e) {
    if (mounted) {
      _showAlert('Login Failed', e.toString());
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
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
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
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(int.parse(primaryColor.replaceAll('#', '0xff'))),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "We're glad to see you again. Please enter your credentials to continue.",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              _buildInputField(
                'Email or Phone',
                _emailOrPhoneController,
                _errors['emailOrPhone'],
              ),
              _buildPasswordField(),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot Password?'),
                ),
              ),
             const  SizedBox(height: 10),
              _buildLoginButton(),
              const SizedBox(height: 15),
              _buildRegisterLink(),
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
    String? error,
  ) {
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
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(int.parse(primaryColor.replaceAll('#', '0xff'))),
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: _passwordController,
            obscureText: !_passwordVisible,
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
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Color(int.parse(primaryColor.replaceAll('#', '0xff'))),
                ),
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              ),
              errorText: _errors['password'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(int.parse(primaryColor.replaceAll('#', '0xff'))),
          padding: const EdgeInsets.all(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: _loading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Text(
                'Login',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/register');
      },
      child: RichText(
        text: TextSpan(
          text: 'Not a member? ',
          style: const TextStyle(color: Colors.black, fontSize: 16),
          children: [
            TextSpan(
              text: 'Create an account',
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
