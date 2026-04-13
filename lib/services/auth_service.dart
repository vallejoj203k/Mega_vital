// lib/services/auth_service.dart
// ─────────────────────────────────────────────────────────────────
// Servicio de autenticación con modo MOCK (sin Firebase).
//
// ¿Cómo funciona ahora?
//   - Login/Registro funcionan con datos locales (shared_preferences)
//   - Los datos se guardan en el dispositivo
//
// ¿Cómo activar Firebase cuando estés listo?
//   1. flutter pub add firebase_core firebase_auth cloud_firestore
//   2. flutterfire configure
//   3. Descomenta el bloque FIREBASE en este archivo y en main.dart
// ─────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ── Resultado tipado ─────────────────────────────────────────────
class AuthResult {
  final bool success;
  final String? errorMessage;
  final MockUser? user;

  const AuthResult._({required this.success, this.errorMessage, this.user});

  factory AuthResult.ok(MockUser user) =>
      AuthResult._(success: true, user: user);
  factory AuthResult.fail(String message) =>
      AuthResult._(success: false, errorMessage: message);
}

// ── Usuario mock (reemplaza firebase_auth User) ──────────────────
class MockUser {
  final String uid;
  final String email;
  final String displayName;

  const MockUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
      };

  factory MockUser.fromMap(Map<String, dynamic> m) => MockUser(
        uid: m['uid'] ?? '',
        email: m['email'] ?? '',
        displayName: m['displayName'] ?? '',
      );
}

// ── Perfil completo del usuario ───────────────────────────────────
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String goal;
  final double weight;
  final double height;
  final int age;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.goal,
    required this.weight,
    required this.height,
    required this.age,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'goal': goal,
        'weight': weight,
        'height': height,
        'age': age,
        'createdAt': createdAt.toIso8601String(),
        'streak': 0,
        'totalWorkouts': 0,
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        uid: m['uid'] ?? '',
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        goal: m['goal'] ?? 'Ganar músculo',
        weight: (m['weight'] ?? 70.0).toDouble(),
        height: (m['height'] ?? 170.0).toDouble(),
        age: m['age'] ?? 25,
        createdAt: m['createdAt'] != null
            ? DateTime.tryParse(m['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}

// ── Claves de SharedPreferences ───────────────────────────────────
const _kCurrentUser = 'mv_current_user';
const _kUsers       = 'mv_users';

// ── Servicio principal ────────────────────────────────────────────
class AuthService {
  // Stream que emite el usuario actual cuando cambia
  // (simulado con un Stream periódico de SharedPreferences)
  Stream<MockUser?> get authStateChanges async* {
    yield await _loadCurrentUser();
  }

  MockUser? _cachedUser;
  MockUser? get currentUser => _cachedUser;

  // ── REGISTRO ──────────────────────────────────────────────────
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String goal,
    required double weight,
    required double height,
    required int age,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800)); // simula latencia
    final prefs = await SharedPreferences.getInstance();

    // Verifica si el email ya existe
    final usersJson = prefs.getString(_kUsers) ?? '{}';
    final users = Map<String, dynamic>.from(jsonDecode(usersJson));

    final emailKey = email.trim().toLowerCase();
    if (users.containsKey(emailKey)) {
      return AuthResult.fail('Ese correo ya está registrado.');
    }

    // Crea el usuario
    final uid = 'uid_${DateTime.now().millisecondsSinceEpoch}';
    final profile = UserProfile(
      uid: uid,
      name: name.trim(),
      email: email.trim(),
      goal: goal,
      weight: weight,
      height: height,
      age: age,
      createdAt: DateTime.now(),
    );

    // Guarda contraseña (en producción esto va en Firebase Auth, no local)
    users[emailKey] = {
      ...profile.toMap(),
      'password': password, // solo para el mock
    };
    await prefs.setString(_kUsers, jsonEncode(users));

    // Inicia sesión automáticamente
    final user = MockUser(uid: uid, email: email.trim(), displayName: name.trim());
    await _saveCurrentUser(user);
    _cachedUser = user;

    return AuthResult.ok(user);
  }

  // ── LOGIN ─────────────────────────────────────────────────────
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final prefs = await SharedPreferences.getInstance();

    final usersJson = prefs.getString(_kUsers) ?? '{}';
    final users = Map<String, dynamic>.from(jsonDecode(usersJson));

    final emailKey = email.trim().toLowerCase();
    if (!users.containsKey(emailKey)) {
      return AuthResult.fail('No existe una cuenta con ese correo.');
    }

    final userData = Map<String, dynamic>.from(users[emailKey]);
    if (userData['password'] != password) {
      return AuthResult.fail('Contraseña incorrecta.');
    }

    final user = MockUser(
      uid: userData['uid'],
      email: userData['email'],
      displayName: userData['name'],
    );
    await _saveCurrentUser(user);
    _cachedUser = user;

    return AuthResult.ok(user);
  }

  // ── RECUPERAR CONTRASEÑA ──────────────────────────────────────
  Future<AuthResult> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_kUsers) ?? '{}';
    final users = Map<String, dynamic>.from(jsonDecode(usersJson));

    if (!users.containsKey(email.trim().toLowerCase())) {
      return AuthResult.fail('No existe una cuenta con ese correo.');
    }
    // En el mock simplemente simulamos el envío
    return const AuthResult._(success: true);
  }

  // ── CERRAR SESIÓN ─────────────────────────────────────────────
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCurrentUser);
    _cachedUser = null;
  }

  // ── OBTENER PERFIL ────────────────────────────────────────────
  Future<UserProfile?> getUserProfile(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_kUsers) ?? '{}';
    final users = Map<String, dynamic>.from(jsonDecode(usersJson));

    for (final data in users.values) {
      final m = Map<String, dynamic>.from(data as Map);
      if (m['uid'] == uid) return UserProfile.fromMap(m);
    }
    return null;
  }

  // ── ACTUALIZAR PERFIL ─────────────────────────────────────────
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_kUsers) ?? '{}';
      final users = Map<String, dynamic>.from(jsonDecode(usersJson));

      for (final key in users.keys) {
        final m = Map<String, dynamic>.from(users[key] as Map);
        if (m['uid'] == uid) {
          users[key] = {...m, ...data};
          await prefs.setString(_kUsers, jsonEncode(users));
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers privados ──────────────────────────────────────────
  Future<void> _saveCurrentUser(MockUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrentUser, jsonEncode(user.toMap()));
  }

  Future<MockUser?> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kCurrentUser);
    if (json == null) return null;
    final user = MockUser.fromMap(jsonDecode(json));
    _cachedUser = user;
    return user;
  }
}
