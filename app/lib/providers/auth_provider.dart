import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// Singleton AuthService provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// StreamProvider wrapping Firebase Auth state
/// Drives GoRouter redirect logic — when null, user is logged out
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});
