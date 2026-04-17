import 'dart:async';
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
    try {
      final current = _service.currentUser;
      if (current != null) {
        _user           = current;
        _status         = AuthStatus.authenticated;
        _profileLoading = true;
        notifyListeners();
        _profile        = await _service.getUserProfile(current.uid);
        _profileLoading = false;
        notifyListeners();
      } else {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } catch (_) {
      _profileLoading = false;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }

    _authSub = _service.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        _status         = AuthStatus.authenticated;
        _profileLoading = true;
        notifyListeners();
        _profile        = await _service.getUserProfile(user.uid);
        _profileLoading = false;
      } else {
        _status         = AuthStatus.unauthenticated;
        _profileLoading = false;
        _profile        = null;
      }
      notifyListeners();
    });
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _clearError();
    final result = await _service.login(email: email, password: password);
    if (!result.success) {
      _errorMessage = result.errorMessage;
      _setLoading(false);
      return false;
    }
    _user   = result.user;
    _status = AuthStatus.authenticated;
    _setLoading(false);
    _profile = await _service.getUserProfile(result.user!.uid);
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String goal,
    required double weight,
    required double height,
    required int    age,
  }) async {
    _setLoading(true);
    _clearError();
    final result = await _service.register(
      name: name, email: email, password: password,
      goal: goal, weight: weight, height: height, age: age,
    );
    if (!result.success) {
      _errorMessage = result.errorMessage;
      _setLoading(false);
      return false;
    }
    _user   = result.user;
    _status = AuthStatus.authenticated;
    _setLoading(false);
    _profile = await _service.getUserProfile(result.user!.uid);
    notifyListeners();
    return true;
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();
    final result = await _service.sendPasswordReset(email);
    _setLoading(false);
    if (!result.success) { _errorMessage = result.errorMessage; return false; }
    return true;
  }

  Future<void> signOut() async {
    await _service.signOut();
    _user    = null;
    _profile = null;
    _status  = AuthStatus.unauthenticated;
    notifyListeners();
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

  Future<void> reloadProfile() async {
    final uid = _user?.uid;
    if (uid == null) return;
    _profileLoading = true;
    notifyListeners();
    _profile        = await _service.getUserProfile(uid);
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
