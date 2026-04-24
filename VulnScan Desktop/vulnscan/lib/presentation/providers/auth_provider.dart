import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vulnscan/config/constants/app_constants.dart';
import 'package:vulnscan/domain/failures.dart';

class User {
  final String uid;
  final String email;
  final String? displayName;

  User({required this.uid, required this.email, this.displayName});

  factory User.fromFirebase(firebase.User fUser) {
    return User(uid: fUser.uid, email: fUser.email!, displayName: fUser.displayName);
  }
}

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;

  AuthNotifier() : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final fUser = _firebaseAuth.currentUser;
      if (fUser != null) {
        final token = await fUser.getIdToken();
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.storageKeyAuthToken, token);
          await prefs.setString(AppConstants.storageKeyUserId, fUser.uid);
          
          // Store display name if available
          if (fUser.displayName != null) {
            await prefs.setString('user_name', fUser.displayName!);
          }
          
          state = AsyncValue.data(User.fromFirebase(fUser));
          return;
        }
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fUser = credential.user;
      if (fUser == null) throw AuthFailure(message: 'Login failed');

      final token = await fUser.getIdToken();
      if (token == null) throw AuthFailure(message: 'Failed to get auth token');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.storageKeyAuthToken, token);
      await prefs.setString(AppConstants.storageKeyUserId, fUser.uid);
      
      // Store display name if available
      if (fUser.displayName != null) {
        await prefs.setString('user_name', fUser.displayName!);
      }

      state = AsyncValue.data(User.fromFirebase(fUser));
    } on firebase.FirebaseAuthException catch (e) {
      state = AsyncValue.error(AuthFailure(message: _getAuthErrorMessage(e)), StackTrace.current);
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        AuthFailure(message: 'Login failed: ${error.toString()}'),
        stackTrace,
      );
    }
  }

  Future<void> signupWithEmail(String email, String password, {String? name}) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fUser = credential.user;
      if (fUser == null) throw AuthFailure(message: 'Signup failed');

      // Update display name if provided
      if (name != null && name.isNotEmpty) {
        await fUser.updateDisplayName(name);
        await fUser.reload();
      }

      final token = await fUser.getIdToken();
      if (token == null) throw AuthFailure(message: 'Failed to get auth token');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.storageKeyAuthToken, token);
      await prefs.setString(AppConstants.storageKeyUserId, fUser.uid);
      if (name != null && name.isNotEmpty) {
        await prefs.setString('user_name', name);
      }

      state = AsyncValue.data(User.fromFirebase(fUser));
    } on firebase.FirebaseAuthException catch (e) {
      state = AsyncValue.error(AuthFailure(message: _getAuthErrorMessage(e)), StackTrace.current);
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        AuthFailure(message: 'Signup failed: ${error.toString()}'),
        stackTrace,
      );
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.storageKeyAuthToken);
      await prefs.remove(AppConstants.storageKeyUserId);
      await _firebaseAuth.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        AuthFailure(message: 'Logout failed: ${error.toString()}'),
        stackTrace,
      );
    }
  }

  String _getAuthErrorMessage(firebase.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'User account is disabled';
      case 'invalid-email':
        return 'Invalid email address';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'operation-not-allowed':
        return 'Email/password accounts not enabled';
      case 'weak-password':
        return 'Password is too weak';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(authNotifierProvider);
  return user.maybeWhen(data: (data) => data != null, orElse: () => false);
});
