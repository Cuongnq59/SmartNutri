import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../api/api_service.dart';

class AuthUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });
}

class AuthResult {
  final bool success;
  final String? errorMessage;
  final AuthUser? user;

  AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });
}

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  static bool isFirebaseAvailable = false;
  final StreamController<AuthUser?> _authStateController = StreamController<AuthUser?>.broadcast();

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  void initializeWithFirebase() {
    try {
      final fbAuth = fb.FirebaseAuth.instance;
      isFirebaseAvailable = true;

      fbAuth.authStateChanges().listen((fbUser) async {
        if (fbUser != null) {
          final user = AuthUser(
            uid: fbUser.uid,
            email: fbUser.email ?? 'sinhvien@smartnutri.vn',
            displayName: fbUser.displayName ?? 'Sinh viên SmartNutri',
            photoUrl: fbUser.photoURL,
          );
          _currentUser = user;
          _authStateController.add(user);

          // Sync with backend database
          await ApiService.syncFirebaseUser(
            firebaseUid: user.uid,
            email: user.email,
            fullName: user.displayName,
          );
        } else {
          if (_currentUser != null && !isFirebaseAvailable) {
            // Keep demo user if not logged out
          } else {
            _currentUser = null;
            _authStateController.add(null);
          }
        }
      });
    } catch (e) {
      debugPrint('Firebase Auth not available locally, enabling smart mock auth mode: $e');
      isFirebaseAvailable = false;
    }
  }

  // 1. Sign In with Email & Password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    if (isFirebaseAvailable) {
      try {
        final credential = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        final fbUser = credential.user;
        if (fbUser != null) {
          final user = AuthUser(
            uid: fbUser.uid,
            email: fbUser.email ?? email,
            displayName: fbUser.displayName ?? email.split('@')[0],
          );
          _currentUser = user;
          _authStateController.add(user);

          await ApiService.syncFirebaseUser(
            firebaseUid: user.uid,
            email: user.email,
            fullName: user.displayName,
          );

          return AuthResult(success: true, user: user);
        }
      } on fb.FirebaseAuthException catch (e) {
        String msg = 'Đăng nhập thất bại: ${e.message}';
        if (e.code == 'user-not-found') msg = 'Tài khoản không tồn tại.';
        if (e.code == 'wrong-password') msg = 'Mật khẩu không chính xác.';
        if (e.code == 'invalid-email') msg = 'Email không hợp lệ.';
        return AuthResult(success: false, errorMessage: msg);
      } catch (e) {
        debugPrint('Firebase error: $e. Falling back to local auth.');
      }
    }

    // Local / Offline demo mode
    final user = AuthUser(
      uid: 'demo_user_${email.hashCode.abs()}',
      email: email,
      displayName: email.split('@')[0],
    );
    _currentUser = user;
    _authStateController.add(user);

    await ApiService.syncFirebaseUser(
      firebaseUid: user.uid,
      email: user.email,
      fullName: user.displayName,
    );

    return AuthResult(success: true, user: user);
  }

  // 2. Sign Up with Email & Password
  Future<AuthResult> signUpWithEmail(String email, String password, String fullName) async {
    if (isFirebaseAvailable) {
      try {
        final credential = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        final fbUser = credential.user;
        if (fbUser != null) {
          await fbUser.updateDisplayName(fullName);
          final user = AuthUser(
            uid: fbUser.uid,
            email: fbUser.email ?? email,
            displayName: fullName,
          );
          _currentUser = user;
          _authStateController.add(user);

          await ApiService.syncFirebaseUser(
            firebaseUid: user.uid,
            email: user.email,
            fullName: fullName,
          );

          return AuthResult(success: true, user: user);
        }
      } on fb.FirebaseAuthException catch (e) {
        String msg = 'Đăng ký thất bại: ${e.message}';
        if (e.code == 'weak-password') msg = 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
        if (e.code == 'email-already-in-use') msg = 'Email này đã được sử dụng.';
        return AuthResult(success: false, errorMessage: msg);
      } catch (e) {
        debugPrint('Firebase error: $e');
      }
    }

    // Local fallback
    final user = AuthUser(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: fullName,
    );
    _currentUser = user;
    _authStateController.add(user);

    await ApiService.syncFirebaseUser(
      firebaseUid: user.uid,
      email: user.email,
      fullName: fullName,
    );

    return AuthResult(success: true, user: user);
  }

  // 3. Demo Student Quick Login
  Future<AuthResult> signInDemoStudent() async {
    final user = AuthUser(
      uid: 'firebase_student_an_01',
      email: 'sinhvien@smartnutri.vn',
      displayName: 'Nguyễn Văn An',
    );
    _currentUser = user;
    _authStateController.add(user);

    await ApiService.syncFirebaseUser(
      firebaseUid: user.uid,
      email: user.email,
      fullName: user.displayName,
    );

    return AuthResult(success: true, user: user);
  }

  // 4. Sign Out
  Future<void> signOut() async {
    if (isFirebaseAvailable) {
      try {
        await fb.FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint('Firebase signOut error: $e');
      }
    }
    _currentUser = null;
    _authStateController.add(null);
  }
}
