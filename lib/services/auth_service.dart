import 'package:supabase_flutter/supabase_flutter.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  final AppUser? user;

  const AuthResult._({required this.success, this.errorMessage, this.user});

  factory AuthResult.ok(AppUser user) =>
      AuthResult._(success: true, user: user);
  factory AuthResult.fail(String message) =>
      AuthResult._(success: false, errorMessage: message);
}

class AppUser {
  final String uid;
  final String email;
  final String displayName;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  factory AppUser.fromSupabase(User user) => AppUser(
    uid: user.id,
    email: user.email ?? '',
    displayName: user.userMetadata?['name'] ?? '',
  );
}

typedef MockUser = AppUser;

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String goal;
  final double weight;
  final double height;
  final int age;
  final DateTime createdAt;
  final String gender;       // 'hombre' | 'mujer'
  final String? referredBy;  // nombre de quien recomendó el gimnasio

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.goal,
    required this.weight,
    required this.height,
    required this.age,
    required this.createdAt,
    this.gender = 'mujer',
    this.referredBy,
  });

  bool get isMale => gender == 'hombre';

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'goal': goal,
    'weight': weight,
    'height': height,
    'age': age,
    'created_at': createdAt.toIso8601String(),
    'streak': 0,
    'total_workouts': 0,
    'gender': gender,
    if (referredBy != null && referredBy!.isNotEmpty) 'referred_by': referredBy,
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    uid: m['uid'] ?? '',
    name: m['name'] ?? '',
    email: m['email'] ?? '',
    goal: m['goal'] ?? 'Ganar músculo',
    weight: (m['weight'] ?? 70.0).toDouble(),
    height: (m['height'] ?? 170.0).toDouble(),
    age: m['age'] ?? 25,
    createdAt: m['created_at'] != null
        ? DateTime.tryParse(m['created_at']) ?? DateTime.now()
        : DateTime.now(),
    gender: m['gender'] ?? 'mujer',
    referredBy: m['referred_by'],
  );
}

class AuthService {
  final _supabase = Supabase.instance.client;

  Stream<AppUser?> get authStateChanges =>
      _supabase.auth.onAuthStateChange.map((event) {
        final user = event.session?.user;
        if (user == null) return null;
        return AppUser.fromSupabase(user);
      });

  AppUser? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return AppUser.fromSupabase(user);
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String goal,
    required double weight,
    required double height,
    required int age,
    String gender = 'mujer',
    String? referredBy,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim()},
      );

      final supaUser = response.user;
      if (supaUser == null) {
        return AuthResult.fail('No se pudo crear la cuenta. Intenta de nuevo.');
      }

      return AuthResult.ok(AppUser.fromSupabase(supaUser));
    } on AuthException catch (e) {
      return AuthResult.fail(_translateError(e.message));
    } catch (e) {
      return AuthResult.fail('Error inesperado. Verifica tu conexión.');
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final supaUser = response.user;
      if (supaUser == null) {
        return AuthResult.fail('No se pudo iniciar sesión. Intenta de nuevo.');
      }

      return AuthResult.ok(AppUser.fromSupabase(supaUser));
    } on AuthException catch (e) {
      return AuthResult.fail(_translateError(e.message));
    } catch (e) {
      return AuthResult.fail('Error inesperado. Verifica tu conexión.');
    }
  }

  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      return const AuthResult._(success: true);
    } on AuthException catch (e) {
      return AuthResult.fail(_translateError(e.message));
    } catch (_) {
      return AuthResult.fail('No se pudo enviar el correo. Intenta de nuevo.');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final data = await _supabase
          .from('user_profiles')
          .select()
          .eq('uid', uid)
          .single()
          .timeout(const Duration(seconds: 10));
      return UserProfile.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  // Crea o sobreescribe el perfil con los datos reales del registro.
  Future<UserProfile?> createProfileWithData({
    required AppUser user,
    required String name,
    required String goal,
    required double weight,
    required double height,
    required int age,
    String gender = 'mujer',
    String? referredBy,
  }) async {
    try {
      await _supabase.from('user_profiles').upsert({
        'uid':            user.uid,
        'name':           name.trim(),
        'email':          user.email,
        'goal':           goal,
        'weight':         weight,
        'height':         height,
        'age':            age,
        'streak':         0,
        'total_workouts': 0,
        'gender':         gender,
        if (referredBy != null && referredBy.isNotEmpty)
          'referred_by': referredBy,
      });
      return await getUserProfile(user.uid);
    } catch (_) {
      return null;
    }
  }

  // Carga el perfil, y si no existe lo crea con valores por defecto (fallback para login).
  Future<UserProfile?> ensureUserProfile(AppUser user) async {
    final existing = await getUserProfile(user.uid);
    if (existing != null) return existing;

    try {
      final name = user.displayName.isNotEmpty ? user.displayName : 'Usuario';
      await _supabase.from('user_profiles').upsert({
        'uid':            user.uid,
        'name':           name,
        'email':          user.email,
        'goal':           'Ganar músculo',
        'weight':         70.0,
        'height':         170.0,
        'age':            25,
        'streak':         0,
        'total_workouts': 0,
      });
      return await getUserProfile(user.uid);
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _supabase.from('user_profiles').update(data).eq('uid', uid);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _translateError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already registered')) {
      return 'Ese correo ya está registrado.';
    }
    if (lower.contains('password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (lower.contains('unable to validate email')) {
      return 'Correo electrónico no válido.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Debes confirmar tu correo antes de iniciar sesión.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Sin conexión. Verifica tu internet.';
    }
    return message;
  }
}
