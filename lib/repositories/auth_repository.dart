import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_constants.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

class AuthFlowResult {
  final UserModel? user;
  final bool needsRole;
  final String? firebaseUid;
  final String? email;
  final String? name;
  final String? password;
  final String? phone;

  AuthFlowResult.existingUser(this.user)
      : needsRole = false,
        firebaseUid = null,
        email = null,
        name = null,
        password = null,
        phone = null;

  AuthFlowResult.needsRole({
    required String uid,
    required String mail,
    required String userName,
    this.password,
    this.phone,
  })  : user = null,
        needsRole = true,
        firebaseUid = uid,
        email = mail,
        name = userName;
}

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;
  final UserRepository _userRepo = UserRepository();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<AuthFlowResult> signInOrRegister({
    required String email,
    required String password,
  }) async {
    UserCredential credential;
    bool isNewAccount = false;

    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        try {
          credential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          isNewAccount = true;
        } on FirebaseAuthException catch (e2) {
          if (e2.code == 'wrong-password' ||
              e2.code == 'invalid-credential') {
            throw Exception('Неверный пароль');
          }
          if (e2.code == 'email-already-in-use') {
            throw Exception('Неверный пароль');
          }
          if (e2.code == 'weak-password') {
            throw Exception('Слишком простой пароль (минимум 6 символов)');
          }
          if (e2.code == 'invalid-email') {
            throw Exception('Неверный формат email');
          }
          rethrow;
        }
      } else if (e.code == 'wrong-password') {
        throw Exception('Неверный пароль');
      } else {
        rethrow;
      }
    }

    final uid = credential.user!.uid;

    final existing = await _userRepo.getUserByFirebaseUid(uid);

    if (existing != null) {
      await _saveSession(existing.id, uid);
      return AuthFlowResult.existingUser(existing);
    }

    return AuthFlowResult.needsRole(
      uid: uid,
      mail: email,
      userName: credential.user!.displayName ?? '',
      password: isNewAccount ? password : null,
    );
  }

  Future<AuthFlowResult?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null;
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user!;
    final uid = firebaseUser.uid;

    final existing = await _userRepo.getUserByFirebaseUid(uid);

    if (existing != null) {
      await _saveSession(existing.id, uid);
      return AuthFlowResult.existingUser(existing);
    }

    return AuthFlowResult.needsRole(
      uid: uid,
      mail: firebaseUser.email ?? '',
      userName: firebaseUser.displayName ?? 'Пользователь',
    );
  }

  /// Вход / регистрация через Facebook.
  Future<AuthFlowResult?> signInWithFacebook() async {
    final loginResult = await _facebookAuth.login(
      permissions: const ['email', 'public_profile'],
    );

    if (loginResult.status == LoginStatus.cancelled) {
      return null;
    }

    if (loginResult.status != LoginStatus.success ||
        loginResult.accessToken == null) {
      throw Exception(
        loginResult.message ?? 'Не удалось войти через Facebook',
      );
    }

    final accessToken = loginResult.accessToken!;
    final tokenString = accessToken.token;

    final credential = FacebookAuthProvider.credential(tokenString);

    UserCredential userCredential;
    try {
      userCredential = await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
          'Этот email уже зарегистрирован другим способом. '
          'Войдите прежним способом, чтобы привязать Facebook.',
        );
      }
      rethrow;
    }

    final firebaseUser = userCredential.user!;
    final uid = firebaseUser.uid;

    final existing = await _userRepo.getUserByFirebaseUid(uid);

    if (existing != null) {
      await _saveSession(existing.id, uid);
      return AuthFlowResult.existingUser(existing);
    }

    return AuthFlowResult.needsRole(
      uid: uid,
      mail: firebaseUser.email ?? '',
      userName: firebaseUser.displayName ?? 'Пользователь',
    );
  }
  Future<UserModel> completeRegistration({
    required String firebaseUid,
    required String email,
    required String name,
    required String role,
    String carModel = '',
    String carNumber = '',
  }) async {
    final user = UserModel(
      id: '',
      name: name,
      email: email,
      role: role,
      balance: role == 'passenger' ? 5000 : 0,
      firebaseUid: firebaseUid,
      carModel: carModel,
      carNumber: carNumber,
      rating: role == 'driver' ? 5.0 : 0,
      isAvailable: true,
    );

    final created = await _userRepo.createUser(user);
    await _saveSession(created.id, firebaseUid);
    return created;
  }

  /// Отправляет SMS с кодом подтверждения на указанный номер.
  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthFlowResult result) onAutoVerified,
    required void Function(String error) onFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final result = await _signInWithPhoneCredential(
            credential: credential,
            phoneNumber: phoneNumber,
          );
          onAutoVerified(result);
        } catch (e) {
          onFailed(e.toString().replaceFirst('Exception: ', ''));
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          onFailed('Неверный формат номера телефона');
        } else if (e.code == 'too-many-requests') {
          onFailed('Слишком много попыток. Попробуйте позже');
        } else if (e.code == 'quota-exceeded') {
          onFailed('Превышен лимит SMS. Попробуйте позже');
        } else if (e.message?.contains('TOO_SHORT') == true ||
            e.message?.contains('TOO_LONG') == true) {
          onFailed('Неверный формат номера. Введите +7 и 10 цифр');
        } else if (e.message?.contains('BILLING_NOT_ENABLED') == true) {
          onFailed(
            'SMS на реальные номера временно недоступны. '
            'Используйте тестовый номер из Firebase Console.',
          );
        } else if (e.message?.contains('blocked all requests') == true) {
          onFailed(
            'Устройство временно заблокировано Firebase. '
            'Попробуйте через несколько часов.',
          );
        } else {
          onFailed(e.message ?? 'Ошибка отправки SMS');
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// Подтверждает код из SMS и выполняет вход.
  Future<AuthFlowResult> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    return _signInWithPhoneCredential(
      credential: credential,
      phoneNumber: phoneNumber,
    );
  }

  Future<AuthFlowResult> _signInWithPhoneCredential({
    required PhoneAuthCredential credential,
    required String phoneNumber,
  }) async {
    UserCredential userCredential;
    try {
      userCredential = await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        throw Exception('Неверный код из SMS');
      }
      if (e.code == 'session-expired') {
        throw Exception('Срок действия кода истёк. Запросите новый');
      }
      rethrow;
    }

    final firebaseUser = userCredential.user!;
    final uid = firebaseUser.uid;

    final existing = await _userRepo.getUserByFirebaseUid(uid);

    if (existing != null) {
      await _saveSession(existing.id, uid);
      return AuthFlowResult.existingUser(existing);
    }

    return AuthFlowResult.needsRole(
      uid: uid,
      mail: firebaseUser.email ?? '',
      userName: firebaseUser.displayName ?? '',
      phone: phoneNumber,
    );
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _facebookAuth.logOut();
    await _auth.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyFirebaseUid);
  }

  Future<UserModel?> restoreSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return _userRepo.getUserByFirebaseUid(firebaseUser.uid);
  }

  Future<void> _saveSession(String userId, String firebaseUid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserId, userId);
    await prefs.setString(AppConstants.keyFirebaseUid, firebaseUid);
  }
}
