import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

/// Everything about accounts: sign-up, login, remember me,
/// forget password and logout.
class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _users = FirebaseFirestore.instance.collection('users');

  /// Creates the account in Firebase Auth, then saves the extra
  /// data (name, birthdate, role) in the "users" collection.
  static Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required DateTime birthdate,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = AppUser(
      uid: cred.user!.uid,
      name: name,
      email: email,
      role: role,
      birthdate: birthdate,
    );
    await _users.doc(user.uid).set(user.toMap());
    return user;
  }

  /// Logs in and remembers the "Remember me" choice on the phone.
  static Future<AppUser> login(
      String email, String password, bool rememberMe) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', rememberMe);
    if (rememberMe) {
      await prefs.setString('saved_email', email);
    } else {
      await prefs.remove('saved_email');
    }
    return getUser(cred.user!.uid);
  }

  /// Called when the app starts. Returns the logged-in user only if
  /// "Remember me" was ticked, otherwise signs out and returns null.
  static Future<AppUser?> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_me') ?? false;
    final current = _auth.currentUser;
    if (current == null) return null;
    if (!remember) {
      await _auth.signOut();
      return null;
    }
    return getUser(current.uid);
  }

  static Future<String> savedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_email') ?? '';
  }

  static Future<AppUser> getUser(String uid) async {
    return AppUser.fromDoc(await _users.doc(uid).get());
  }

  /// Firebase sends an email with a link to choose a new password.
  static Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', false);
    await _auth.signOut();
  }

  /// Turns Firebase error codes into simple messages for the user.
  static String errorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Wrong email or password.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'network-request-failed':
          return 'No internet connection.';
      }
      return e.message ?? e.code;
    }
    return e.toString();
  }
}
