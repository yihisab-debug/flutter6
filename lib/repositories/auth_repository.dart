import 'package:firebase_auth/firebase_auth.dart';
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

  AuthFlowResult.existingUser(this.user)
      : needsRole = false,
        firebaseUid = null,
        email = null,
        name = null,
        password = null;

  AuthFlowResult.needsRole({
    required String uid,
    required String mail,
    required String userName,
    this.password,
  })  : user = null,
        needsRole = true,
        firebaseUid = uid,
        email = mail,
        name = userName;
}

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
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

  Future<void> logout() async {
    await _googleSignIn.signOut();
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
