import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final UserRepository _userRepo = UserRepository();

  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String carModel = '',
    String carNumber = '',
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authRepo.register(
        email: email,
        password: password,
        name: name,
        role: role,
        carModel: carModel,
        carNumber: carNumber,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authRepo.login(email: email, password: password);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> restore() async {
    _user = await _authRepo.restoreSession();
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepo.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_user == null) return;
    _user = await _userRepo.getUserById(_user!.id);
    notifyListeners();
  }
}
