import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For session management
import '../services/auth_service.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  _SigninPageState createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final TextEditingController _schoolIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isPasswordHidden = true;

  @override
  void initState() {
    super.initState();
    _checkUserSession(); // Check if user is already logged in
  }

  // Step 1: Check if the user session exists
  Future<void> _checkUserSession() async {
    setState(() {
      _isLoading = true;
    });

    final isLoggedIn = await _authService.isLoggedIn();
    setState(() {
      _isLoading = false;
    });

    if (isLoggedIn) {
      // If the user is logged in, redirect to the homepage
      Navigator.pushReplacementNamed(context, '/homepage');
    }
  }

  // Step 2: Login method
  void _login() async {
    setState(() {
      _isLoading = true;
    });

    final schoolId = _schoolIdController.text.trim();
    final password = _passwordController.text.trim();

    if (schoolId.isEmpty || password.isEmpty) {
      _showMessage('Please enter both Student ID and password.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Try to log in using AuthService
    final loginData = await _authService.loginWithSchoolId(schoolId, password);

    setState(() {
      _isLoading = false;
    });

    if (loginData['success']) {
      var userData = loginData['user']; // Get user data from response

      // Save user data locally in SharedPreferences
      _saveUserDataLocally(userData);

      _showMessage(loginData['message']);
      Navigator.pushReplacementNamed(context, '/homepage');
    } else {
      _showMessage(loginData['message'] ?? 'Invalid credentials. Please try again.');
    }
  }

  // Step 3: Save user data locally in SharedPreferences
  Future<void> _saveUserDataLocally(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', userData.toString()); // Save user data as string
  }

  // Show a message (error/success)
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show a loader if checking session
          : Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.lightBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150, // Set the desired width
              height: 150, // Set the desired height
              fit: BoxFit.cover, // Adjust how the image is fitted within the widget
            ),
            const SizedBox(height: 10),
            const Text(
              'U-FIND',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _schoolIdController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Student ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.school, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: _isPasswordHidden,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordHidden ? Icons.visibility : Icons.visibility_off,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordHidden = !_isPasswordHidden;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 100),
              ),
              child: const Text(
                'Login',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account?",
                  style: TextStyle(color: Colors.white),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/registration');
                  },
                  child: const Text('Sign up', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
