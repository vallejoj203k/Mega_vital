import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthResult {
  final bool success;
  final bool requiresEmailConfirmation;
  final String? errorMessage;
  final AppUser? user;

  const AuthResult._({
    required this.success,
    this.requiresEmailConfirmation = false,
    this.errorMessage,
    this.user,
  });

  factory AuthResult.ok(AppUser user) =>
      AuthResult._(success: true, user: user);

  // signUp exitoso pero Supabase requiere confirmar el correo antes de dar sesión.
  factory AuthResult.emailPending(AppUser user) =>
      AuthResult._(success: false, requiresEmailConfirmation: true, user: user);

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
  final String? referredBy;
  final String? avatarUrl;

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
    this.avatarUrl,
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
    if (avatarUrl != null) 'avatar_url': avatarUrl,
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
    avatarUrl: m['avatar_url'] as String?,
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
      // Guardamos todos los datos del perfil en metadata para poder recuperarlos
      // si Supabase requiere confirmación de correo y la sesión no se activa ahora.
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'name': name.trim(),
          'goal': goal,
          'weight': weight,
          'height': height,
          'age': age,
          'gender': gender,
          if (referredBy != null && referredBy.isNotEmpty)
            'referred_by': referredBy,
        },
      );

      final supaUser = response.user;
      if (supaUser == null) {
        return AuthResult.fail('No se pudo crear la cuenta. Intenta de nuevo.');
      }

      // Si no hay sesión, Supabase requiere confirmación de correo electrónico.
      if (response.session == null) {
        return AuthResult.emailPending(AppUser.fromSupabase(supaUser));
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
    // Construye el perfil local como fallback si la lectura post-upsert falla.
    UserProfile buildLocal(UserProfile? saved) => UserProfile(
      uid:        saved?.uid ?? user.uid,
      name:       saved?.name ?? name.trim(),
      email:      saved?.email ?? user.email,
      goal:       saved?.goal ?? goal,
      weight:     saved?.weight ?? weight,
      height:     saved?.height ?? height,
      age:        saved?.age ?? age,
      createdAt:  saved?.createdAt ?? DateTime.now(),
      gender:     gender,
      referredBy: referredBy,
    );

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
      // El upsert guardó los datos reales; construimos local si la lectura falla.
      final saved = await getUserProfile(user.uid);
      return buildLocal(saved);
    } catch (_) {
      // Si falla (ej. columna gender faltante), reintentamos sin campos opcionales.
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
        });
        final saved = await getUserProfile(user.uid);
        return buildLocal(saved);
      } catch (_) {
        return null;
      }
    }
  }

  // Carga el perfil del usuario. Si no existe y hay metadatos del registro,
  // crea el perfil desde esos datos (útil al confirmar correo y hacer login).
  Future<UserProfile?> ensureUserProfile(AppUser user) async {
    final existing = await getUserProfile(user.uid);
    if (existing != null) return existing;

    // Sin sesión activa no podemos escribir en la DB (RLS requiere auth.uid()).
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    // Intentar crear el perfil desde los metadatos guardados durante el registro.
    final meta = _supabase.auth.currentUser?.userMetadata;
    if (meta == null) return null;

    final metaName      = (meta['name'] as String?)?.trim() ?? '';
    final metaGoal      = meta['goal'] as String?;
    final metaWeight    = (meta['weight'] as num?)?.toDouble();
    final metaHeight    = (meta['height'] as num?)?.toDouble();
    final metaAge       = (meta['age'] as num?)?.toInt();
    final metaGender    = meta['gender'] as String?;
    final metaReferred  = meta['referred_by'] as String?;

    // Solo crear si hay datos reales del formulario de registro.
    if (metaGoal == null || metaWeight == null || metaHeight == null || metaAge == null) {
      return null;
    }

    final name = metaName.isNotEmpty ? metaName
        : (user.displayName.isNotEmpty ? user.displayName : 'Usuario');

    return await createProfileWithData(
      user:       user,
      name:       name,
      goal:       metaGoal,
      weight:     metaWeight,
      height:     metaHeight,
      age:        metaAge,
      gender:     metaGender ?? 'mujer',
      referredBy: metaReferred,
    );
  }

  /// Elimina la cuenta del usuario y todos sus datos permanentemente.
  /// Llama a la función SQL delete_user_account() con SECURITY DEFINER.
  Future<bool> deleteAccount() async {
    try {
      await _supabase.rpc('delete_user_account');
      return true;
    } catch (_) {
      return false;
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

  /// Sube la imagen al bucket 'avatars' y actualiza avatar_url en el perfil.
  /// Retorna la URL pública o null si falla.
  Future<String?> uploadAvatar(String uid, File file) async {
    try {
      const bucket = 'avatars';
      final path = '$uid/avatar';
      await _supabase.storage.from(bucket).upload(
        path, file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      final url = _supabase.storage.from(bucket).getPublicUrl(path);
      // Añadir timestamp para forzar recarga tras actualización
      final cacheBusted = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
      await updateUserProfile(uid, {'avatar_url': cacheBusted});
      return cacheBusted;
    } catch (_) {
      return null;
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
