import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../core/app_constants.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.expectedRole});

  

  
  final String expectedRole;

  final AuthRepository _authRepo = AuthRepository();
  final UserRepository _userRepo = UserRepository();

  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  
  Future<bool> _enforceRole(UserModel user) async {
    if (user.role == expectedRole) return true;
    await _authRepo.logout();
    _user = null;
    _error = _wrongRoleMessage(user.role);
    notifyListeners();
    return false;
  }

  String _wrongRoleMessage(String actualRole) {
    final actual = _roleLabel(actualRole);
    final expected = _roleLabel(expectedRole);
    return 'Этот аккаунт зарегистрирован как $actual. '
        'Войдите в приложение для $expected.';
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'passenger':
        return 'пассажир';
      case 'driver':
        return 'водитель';
      case 'admin':
        return 'администратор';
      default:
        return role;
    }
  }

  Future<AuthFlowResult?> signInOrRegister({
    required String email,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepo.signInOrRegister(
        email: email,
        password: password,
      );

      if (!result.needsRole) {
        if (await _enforceRole(result.user!)) {
          _user = result.user;
        } else {
          return null;
        }
      }

      return result;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithTestAccount(TestAccount account) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authRepo.signInWithTestAccount(
        account: account,
        expectedRole: expectedRole,
      );
      _user = user;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<AuthFlowResult?> signInWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepo.signInWithGoogle();

      if (result != null && !result.needsRole) {
        if (await _enforceRole(result.user!)) {
          _user = result.user;
        } else {
          return null;
        }
      }

      return result;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<AuthFlowResult?> signInWithFacebook() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepo.signInWithFacebook();

      if (result != null && !result.needsRole) {
        if (await _enforceRole(result.user!)) {
          _user = result.user;
        } else {
          return null;
        }
      }

      return result;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> sendPhoneCode({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthFlowResult result) onAutoVerified,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    await _authRepo.sendPhoneVerificationCode(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId, resendToken) {
        _loading = false;
        notifyListeners();
        onCodeSent(verificationId, resendToken);
      },
      onAutoVerified: (result) async {
        if (!result.needsRole) {
          if (await _enforceRole(result.user!)) {
            _user = result.user;
          }
        }
        _loading = false;
        notifyListeners();
        onAutoVerified(result);
      },
      onFailed: (error) {
        _error = error;
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<AuthFlowResult?> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepo.verifyPhoneCode(
        verificationId: verificationId,
        smsCode: smsCode,
        phoneNumber: phoneNumber,
      );

      if (!result.needsRole) {
        if (await _enforceRole(result.user!)) {
          _user = result.user;
        } else {
          return null;
        }
      }

      return result;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> completeRegistration({
    required String firebaseUid,
    required String email,
    required String name,
    String carModel = '',
    String carNumber = '',
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {

      _user = await _authRepo.completeRegistration(
        firebaseUid: firebaseUid,
        email: email,
        name: name,
        role: expectedRole,
        carModel: carModel,
        carNumber: carNumber,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> restore() async {
    final user = await _authRepo.restoreSession();
    if (user == null) {
      _user = null;
    } else if (user.role == expectedRole && !user.isBlocked) {
      _user = user;
    } else {

      await _authRepo.logout();
      _user = null;
    }
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

    if (_user!.isBlocked) {
      await logout();
      _error = 'Ваш аккаунт был заблокирован администратором';
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  Future<bool> topUpBalance(double amount) async {
    if (_user == null) return false;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final newBalance = _user!.balance + amount;
      _user = await _userRepo.updateBalance(_user!.id, newBalance);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
