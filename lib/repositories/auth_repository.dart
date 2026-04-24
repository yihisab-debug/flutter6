import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_constants.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepo = UserRepository();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String carModel = '',
    String carNumber = '',
  }) async {
    UserCredential? credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      final user = UserModel(
        id: '',
        name: name,
        email: email,
        role: role,
        balance: role == 'passenger' ? 5000 : 0,
        firebaseUid: uid,
        carModel: carModel,
        carNumber: carNumber,
        rating: role == 'driver' ? 5.0 : 0,
        isAvailable: true,
      );

      final created = await _userRepo.createUser(user);

      await _saveSession(created.id, uid);
      return created;
    } catch (e) {
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final user = await _userRepo.getUserByFirebaseUid(uid);
    if (user == null) {
      throw Exception('Профиль не найден в системе');
    }

    await _saveSession(user.id, uid);
    return user;
  }

  Future<void> logout() async {
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
