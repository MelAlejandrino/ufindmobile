import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'signin_page.dart';  // Import the SigninPage

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _schoolIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Add GlobalKey for Form
  bool _isPasswordVisible = false; // State variable to track visibility
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final firstName = prefs.getString('user_first_name');
    final lastName = prefs.getString('user_last_name');
    final contactNumber = prefs.getString('contact_number');
    final schoolId = prefs.getString('user_school_id');

    if (schoolId == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SigninPage()),
      );
    } else {
      setState(() {
        _firstNameController.text = firstName ?? '';
        _lastNameController.text = lastName ?? '';
        _contactNumberController.text = contactNumber ?? '';
        _schoolIdController.text = schoolId;
        _passwordController.text = '';
        userId = schoolId;
      });
    }
  }

  Future<void> saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (userId != null) {
        final success = await AuthService().updateProfile(
          userId!,
          _firstNameController.text,
          _lastNameController.text,
          _contactNumberController.text,
          _passwordController.text,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated! Relogin to see changes.')),
          );

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_first_name', _firstNameController.text);
          await prefs.setString('user_last_name', _lastNameController.text);
          await prefs.setString('contact_number', _contactNumberController.text);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID is missing.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey, // Wrap content in a Form widget
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: userId != '1234567890'
                      ? const AssetImage('assets/images/profile.jpg')
                      : const AssetImage('assets/images/profile-guard.png'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactNumberController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white70,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Contact number is required.';
                    }
                    if (value.length != 11) {
                      return 'Contact number must be 11 digits.';
                    }
                    if (!value.startsWith('09')) {
                      return 'Contact number must start with "09".';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _schoolIdController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'School ID',
                    prefixIcon: Icon(Icons.school),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: saveProfile,
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}