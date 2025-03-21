import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart'; // For SHA-256
import 'dart:convert'; // For utf8 encoding
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // Check if the user is logged in by checking SharedPreferences
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('userData'); // Returns true if 'userData' exists
  }

  // Check if the user is logged in by checking SharedPreferences
  Future<Map<String, dynamic>> loginWithSchoolId(String schoolId, String password) async {
    try {
      // Fetch the user document from Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(schoolId).get();

      if (!userDoc.exists) {
        return {'success': false, 'message': 'User not found.'};
      }

      // Check the user's status
      String status = userDoc['status'];
      if (status != 'active') {
        return {
          'success': false,
          'message': 'Your account is currently inactive and cannot log in at this time. Please contact support for assistance.',
        };
      }

      // Retrieve stored salt and hashed password
      String storedSalt = userDoc['salt'];
      String storedHashedPassword = userDoc['password'];

      // Hash the provided password with the stored salt
      String hashedInputPassword = _hashPasswordWithSalt(password, storedSalt);

      if (hashedInputPassword != storedHashedPassword) {
        return {'success': false, 'message': 'Invalid credentials.'};
      }

      String email = userDoc['emailAddress'];

      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password, // Used for Firebase login
      );

      final user = userCredential.user;
      if (user != null) {
        await _saveUserDataLocally(userDoc, user.email);
        return {
          'success': true,
          'message': 'Login successful!',
          'user': userDoc.data(),
        };
      } else {
        return {'success': false, 'message': 'Failed to log in.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Please Check Internet Connection.'};
    }
  }


  String _hashPasswordWithSalt(String password, String salt) {
    final bytes = utf8.encode(password + salt); // Combine password and salt
    return sha256.convert(bytes).toString(); // Hash the combination
  }

  // Save user data to SharedPreferences (excluding the password)
  Future<void> _saveUserDataLocally(DocumentSnapshot userDoc,
      String? email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Save user details (ensure that the keys match your Firestore document fields)
    await prefs.setString('user_first_name', userDoc['firstName']);
    await prefs.setString('user_last_name', userDoc['lastName']);
    await prefs.setString('contact_number', userDoc['contactNumber']);
    await prefs.setString(
        'user_email', email ?? ''); // Save email from Firebase Authentication
    await prefs.setString(
        'user_school_id', userDoc.id); // Saving the school ID (document ID)
    // Do not store the password in SharedPreferences for security reasons

    await prefs.setBool('is_logged_in', true);
  }

  // Log out the user and clear SharedPreferences
  Future<void> logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // List of keys to retain
    List<String> keysToRetain = [
      'first_time', // Retaining the key for first-time app launch (example)
      // Add any other keys you want to retain here
    ];

    // Get all keys in SharedPreferences
    Set<String> allKeys = prefs.getKeys();

    // Iterate over all keys and remove them if they are not in the keysToRetain list
    for (String key in allKeys) {
      if (!keysToRetain.contains(key)) {
        await prefs.remove(key);
      }
    }

    // Optionally set 'is_logged_in' to false if you want to track login status
    await prefs.setBool('is_logged_in', false);
  }

  // Get current user email from Firebase Authentication
  Future<String> getCurrentUserEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email ?? '';
  }

  Future<bool> updateProfile(String schoolId, String firstName, String lastName, String contactNumber, String password) async {
    try {
      // Prepare user data for update
      Map<String, dynamic> updatedData = {
        'firstName': firstName,
        'lastName': lastName,
        'contactNumber': contactNumber,

      };

      // If a new password is provided, generate a new salt and hash the password
      if (password.isNotEmpty) {
        String newSalt = _generateSalt();
        String hashedPassword = _hashPasswordWithSalt(password, newSalt);
        updatedData['salt'] = newSalt;
        updatedData['password'] = hashedPassword;
      }

      // Update the user document in Firestore
      await _firestore.collection('users').doc(schoolId).update(updatedData);

      // Optionally, save updated data to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_first_name', firstName);
      await prefs.setString('user_last_name', lastName);
      await prefs.setString('contact_number', contactNumber);
      await prefs.setString('user_school_id', schoolId);

      return true;
    } catch (e) {
      return false;
    }
  }

  String _generateSalt() {
    final random = List<int>.generate(16, (i) => DateTime.now().microsecond % 256);
    return base64Url.encode(random);
  }
}