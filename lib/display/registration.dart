import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'dart:convert'; // For hashing
import 'package:crypto/crypto.dart'; // For hashing passwords
import 'dart:math'; // For generating salt
import 'package:flutter/services.dart'; // For input formatters

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _schoolIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // New controller for confirm password

  bool _isRegistering = false;
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true; // Track visibility of confirm password

  void _handleRegister() async {
    if (_isRegistering) return; // Prevent multiple clicks

    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String schoolId = _schoolIdController.text.trim();
    String email = _emailController.text.trim();
    String contactNumber = _contactNumberController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim(); // Get confirm password value

    if (firstName.isEmpty || lastName.isEmpty || schoolId.isEmpty || contactNumber.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Please fill all the fields.');
      return;
    }

    // Check if password and confirm password match
    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    if (schoolId.length != 10) {
      _showMessage('Student ID must be exactly 10 digits.');
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
       await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot existingDoc = await FirebaseFirestore.instance.collection('users').doc(schoolId).get();

      if (existingDoc.exists) {
        _showMessage('A user with this Student ID already exists.');
        setState(() {
          _isRegistering = false;
        });
        return;
      }

      String salt = generateSalt();
      String hashedPassword = hashPassword(password, salt);

      await FirebaseFirestore.instance.collection('users').doc(schoolId).set({
        'firstName': firstName,
        'lastName': lastName,
        'contactNumber': contactNumber,
        'emailAddress': email,
        'password': hashedPassword,
        'salt': salt,
        'status': 'active',
        'member': 'user',
      });

      _showMessage('Registration Successful! Please login now with your Student ID');
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      _showMessage('Registration failed: $e');
    } finally {
      setState(() {
        _isRegistering = false;
      });
    }
  }

  String generateSalt([int length = 30]) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    return List.generate(length, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    return sha256.convert(bytes).toString();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.lightBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height, // Ensures full-screen height
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Image.asset(
                      'assets/images/logo.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'U-FIND Registration',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(_firstNameController, 'First Name', Icons.person),
                    const SizedBox(height: 10),
                    _buildTextField(_lastNameController, 'Last Name', Icons.person),
                    const SizedBox(height: 10),
                    _buildTextField(_schoolIdController, 'Student ID', Icons.school, isNumber: true),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _contactNumberController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                        hintText: 'Contact Number', // Placeholder for format guidance
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),

                      ),
                      keyboardType: TextInputType.number, // Numeric keyboard
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, // Only digits allowed
                        LengthLimitingTextInputFormatter(11),  // Limit to 11 digits
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a contact number.';
                        }
                        if (value.length != 11) {
                          return 'Contact number must be exactly 11 digits.';
                        }
                        if (!value.startsWith('09')) {
                          return 'Contact number must start with "09".';
                        }
                        return null; // Valid input
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(_emailController, 'Email', Icons.email),
                    const SizedBox(height: 10),
                    _buildPasswordField(),
                    const SizedBox(height: 10),
                    _buildConfirmPasswordField(),
                    const SizedBox(height: 20),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _isRegistering ? 60 : MediaQuery.of(context).size.width * 0.8,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _handleRegister,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_isRegistering ? 30 : 10),
                          ),
                        ),
                        child: _isRegistering
                            ? const CircularProgressIndicator(color: Colors.blue)
                            : const Text('Register', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account?",
                          style: TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/signin');
                          },
                          child: const Text('Sign in', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    const Spacer(), // Push content to fill available space
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: _confirmPasswordController,
      obscureText: _isConfirmPasswordHidden,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Confirm Password',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.lock, color: Colors.blue),
        suffixIcon: IconButton(
          icon: Icon(_isConfirmPasswordHidden ? Icons.visibility : Icons.visibility_off, color: Colors.blue),
          onPressed: () {
            setState(() {
              _isConfirmPasswordHidden = !_isConfirmPasswordHidden;
            });
          },
        ),
      ),
    );
  }



  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon, {bool isPassword = false, bool isNumber = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)] : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: Colors.blue),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
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
          icon: Icon(_isPasswordHidden ? Icons.visibility : Icons.visibility_off, color: Colors.blue),
          onPressed: () {
            setState(() {
              _isPasswordHidden = !_isPasswordHidden;
            });
          },
        ),
      ),
    );
  }
}
