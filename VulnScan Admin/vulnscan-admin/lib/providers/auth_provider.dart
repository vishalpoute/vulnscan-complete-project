import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Firebase Auth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Current authenticated user
final authProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

// Login with email and password
final loginProvider = FutureProvider.family<UserCredential, ({String email, String password})>((ref, credentials) async {
  final auth = ref.watch(firebaseAuthProvider);
  return await auth.signInWithEmailAndPassword(
    email: credentials.email,
    password: credentials.password,
  );
});

// Logout
final logoutProvider = FutureProvider<void>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  return await auth.signOut();
});

// Get current user ID token for API calls
final authTokenProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user != null) {
    return await user.getIdToken();
  }
  return null;
});
