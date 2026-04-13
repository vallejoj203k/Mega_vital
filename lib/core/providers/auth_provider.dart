// lib/core/providers/auth_provider.dart
// ─────────────────────────────────────────────────────────────────
// Gestiona el estado global de autenticación.
// Usa MockUser en lugar de firebase_auth User.
// ─────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _service;

  AuthStatus _status = AuthStatus.initial;
  MockUser?    _mockUser;
  UserProfile? _profile;
  String?      _errorMessage;
  bool         _isLoading = false;

  AuthProvider({AuthService? service})
      : _service = service ?? AuthService() {
    _init();
  }

  // ── Getters ──────────────────────────────────────────────────
  AuthStatus   get status       => _status;
  MockUser?    get firebaseUser  => _mockUser;
  UserProfile? get profile       => _profile;
  String?      get errorMessage  => _errorMessage;
  bool         get isLoading     => _isLoading;
  bool         get isLoggedIn    => _status == AuthStatus.authenticated;
  bool         get isInitializing=> _status == AuthStatus.initial;

  String get displayName =>
      _profile?.name ?? _mockUser?.displayName ?? 'Usuario';

  String get userInitials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
  }

  // ── Inicialización: restaura sesión guardada ─────────────────
  Future<void> _init() async {
    _service.authStateChanges.listen((user) async {
      _mockUser = user;
      if (user != null) {
        _status  = AuthStatus.authenticated;
        _profile = await _service.getUserProfile(user.uid);
      } else {
        _status  = AuthStatus.unauthenticated;
        _profile = null;
      }
      notifyListeners();
    });
  }

  // ── LOGIN ────────────────────────────────────────────────────
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    final result = await _service.login(email: email, password: password);
    if (!result.success) {
      _errorMessage = result.errorMessage;
      _setLoading(false);
      return false;
    }

    _mockUser = result.user;
    _profile  = await _service.getUserProfile(result.user!.uid);
    _status   = AuthStatus.authenticated;
    _setLoading(false);
    return true;
  }

  // ── REGISTRO ─────────────────────────────────────────────────
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

    _mockUser = result.user;
    _profile  = await _service.getUserProfile(result.user!.uid);
    _status   = AuthStatus.authenticated;
    _setLoading(false);
    return true;
  }

  // ── RECUPERAR CONTRASEÑA ─────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();
    final result = await _service.sendPasswordReset(email);
    _setLoading(false);
    if (!result.success) { _errorMessage = result.errorMessage; return false; }
    return true;
  }

  // ── CERRAR SESIÓN ────────────────────────────────────────────
  Future<void> signOut() async {
    await _service.signOut();
    _mockUser = null;
    _profile  = null;
    _status   = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── ACTUALIZAR PERFIL ────────────────────────────────────────
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final uid = _mockUser?.uid;
    if (uid == null) return false;
    final ok = await _service.updateUserProfile(uid, data);
    if (ok) {
      _profile = await _service.getUserProfile(uid);
      notifyListeners();
    }
    return ok;
  }

  void clearError() => _clearError();

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _clearError()       { _errorMessage = null; notifyListeners(); }
}
