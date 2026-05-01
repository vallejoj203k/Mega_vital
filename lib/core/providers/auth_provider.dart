import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

export '../../services/auth_service.dart' show AppUser, MockUser;

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _service;

  AuthStatus _status = AuthStatus.initial;
  AppUser?     _user;
  UserProfile? _profile;
  String?      _errorMessage;
  bool         _isLoading = false;
  bool         _profileLoading = false;
  bool         _isRegistering = false;
  StreamSubscription? _authSub;

  AuthProvider({AuthService? service})
      : _service = service ?? AuthService() {
    _init();
  }

  AuthStatus   get status         => _status;
  AppUser?     get firebaseUser   => _user;
  UserProfile? get profile        => _profile;
  String?      get errorMessage   => _errorMessage;
  bool         get isLoading      => _isLoading;
  bool         get profileLoading => _profileLoading;
  bool         get isLoggedIn     => _status == AuthStatus.authenticated;
  bool         get isInitializing => _status == AuthStatus.initial;

  String get displayName =>
      _profile?.name ?? _user?.displayName ?? 'Usuario';

  String get userInitials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
  }

  Future<void> _init() async {
    final current = _service.currentUser;
    if (current != null) {
      _user           = current;
      _status         = AuthStatus.authenticated;
      _profileLoading = true;
      notifyListeners();
      try {
        _profile = await _service.ensureUserProfile(current);
      } catch (_) {
        // El perfil no cargó (red), pero el usuario SÍ está autenticado.
      }
      _profileLoading = false;
      notifyListeners();
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }

    _authSub = _service.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        if (_isRegistering) return;
        _status         = AuthStatus.authenticated;
        _profileLoading = true;
        notifyListeners();
        _profile        = await _service.ensureUserProfile(user);
        _profileLoading = false;
      } else {
        _status         = AuthStatus.unauthenticated;
        _profileLoading = false;
        _profile        = null;
      }
      notifyListeners();
    });
  }

  Future<bool> login({required String username, required String password}) async {
    _setLoading(true);
    _clearError();
    final result = await _service.login(username: username, password: password);
    if (!result.success) {
      _errorMessage = result.errorMessage;
      _setLoading(false);
      return false;
    }
    _user   = result.user;
    _status = AuthStatus.authenticated;
    _setLoading(false);
    _profile = await _service.ensureUserProfile(result.user!);
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String username,
    required String name,
    required String password,
    required String goal,
    required double weight,
    required double height,
    required int    age,
    String gender = 'mujer',
    String? referredBy,
  }) async {
    _isRegistering = true;
    _setLoading(true);
    _clearError();
    final result = await _service.register(
      username: username, name: name, password: password,
      goal: goal, weight: weight, height: height, age: age,
      gender: gender, referredBy: referredBy,
    );

    if (result.requiresEmailConfirmation) {
      final loginResult = await _service.login(username: username, password: password);
      if (loginResult.success && loginResult.user != null) {
        _user           = loginResult.user;
        _status         = AuthStatus.authenticated;
        _profileLoading = true;
        _setLoading(false);
        _profile = await _service.createProfileWithData(
          user:       loginResult.user!,
          username:   username,
          name:       name,
          goal:       goal,
          weight:     weight,
          height:     height,
          age:        age,
          gender:     gender,
          referredBy: referredBy,
        );
        _profileLoading = false;
        _isRegistering  = false;
        notifyListeners();
        return true;
      }
      _errorMessage  = 'Cuenta creada. El miembro puede iniciar sesión con su usuario y contraseña.';
      _isRegistering = false;
      _setLoading(false);
      return false;
    }

    if (!result.success || result.user == null) {
      _errorMessage  = result.errorMessage ?? 'Error al crear la cuenta.';
      _isRegistering = false;
      _setLoading(false);
      return false;
    }

    _user           = result.user;
    _status         = AuthStatus.authenticated;
    _profileLoading = true;
    _setLoading(false);

    _profile = await _service.createProfileWithData(
      user:       result.user!,
      username:   username,
      name:       name,
      goal:       goal,
      weight:     weight,
      height:     height,
      age:        age,
      gender:     gender,
      referredBy: referredBy,
    );

    _profileLoading = false;
    _isRegistering  = false;
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    await _service.signOut();
    _user    = null;
    _profile = null;
    _status  = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    final ok = await _service.deleteAccount();
    if (ok) {
      _user    = null;
      _profile = null;
      _status  = AuthStatus.unauthenticated;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final uid = _user?.uid;
    if (uid == null) return false;
    final ok = await _service.updateUserProfile(uid, data);
    if (ok) {
      _profile = await _service.getUserProfile(uid);
      notifyListeners();
    }
    return ok;
  }

  Future<String?> uploadAvatar(File file) async {
    final uid = _user?.uid;
    if (uid == null) return null;
    final url = await _service.uploadAvatar(uid, file);
    if (url != null) {
      _profile = await _service.getUserProfile(uid);
      notifyListeners();
    }
    return url;
  }

  Future<void> updateNutritionLevel(int level) async {
    if (_profile == null || _user == null) return;
    _profile = _profile!.copyWith(nutritionLevel: level.clamp(1, 4));
    notifyListeners();
    await _service.updateUserProfile(_user!.uid, {'nutrition_level': level.clamp(1, 4)});
  }

  Future<void> reloadProfile() async {
    final user = _user;
    if (user == null) return;
    _profileLoading = true;
    notifyListeners();
    _profile        = await _service.ensureUserProfile(user);
    _profileLoading = false;
    notifyListeners();
  }

  void clearError() => _clearError();
  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _clearError()       { _errorMessage = null; notifyListeners(); }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
