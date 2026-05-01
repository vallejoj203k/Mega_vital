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
  final String username;
  final String email;
  final String goal;
  final double weight;
  final double height;
  final int age;
  final DateTime createdAt;
  final String gender;
  final String? referredBy;
  final String? avatarUrl;
  final int nutritionLevel;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    required this.goal,
    required this.weight,
    required this.height,
    required this.age,
    required this.createdAt,
    this.gender = 'mujer',
    this.referredBy,
    this.avatarUrl,
    this.nutritionLevel = 1,
  });

  bool get isMale => gender == 'hombre';

  UserProfile copyWith({
    String? uid,
    String? name,
    String? username,
    String? email,
    String? goal,
    double? weight,
    double? height,
    int? age,
    DateTime? createdAt,
    String? gender,
    String? referredBy,
    String? avatarUrl,
    int? nutritionLevel,
  }) => UserProfile(
    uid:            uid            ?? this.uid,
    name:           name           ?? this.name,
    username:       username       ?? this.username,
    email:          email          ?? this.email,
    goal:           goal           ?? this.goal,
    weight:         weight         ?? this.weight,
    height:         height         ?? this.height,
    age:            age            ?? this.age,
    createdAt:      createdAt      ?? this.createdAt,
    gender:         gender         ?? this.gender,
    referredBy:     referredBy     ?? this.referredBy,
    avatarUrl:      avatarUrl      ?? this.avatarUrl,
    nutritionLevel: nutritionLevel ?? this.nutritionLevel,
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'username': username,
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

  factory UserProfile.fromMap(Map<String, dynamic> m) {
    final rawEmail = m['email'] as String? ?? '';
    final derivedUsername = rawEmail.replaceAll('@megavital.app', '');
    return UserProfile(
      uid:            m['uid']      ?? '',
      name:           m['name']     ?? '',
      username:       m['username'] as String? ?? derivedUsername,
      email:          rawEmail,
      goal:           m['goal']     ?? 'Ganar músculo',
      weight:         (m['weight']  ?? 70.0).toDouble(),
      height:         (m['height']  ?? 170.0).toDouble(),
      age:            m['age']      ?? 25,
      createdAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at']) ?? DateTime.now()
          : DateTime.now(),
      gender:         m['gender']        ?? 'mujer',
      referredBy:     m['referred_by'],
      avatarUrl:      m['avatar_url']    as String?,
      nutritionLevel: (m['nutrition_level'] as int?) ?? 1,
    );
  }
}

class AuthService {
  final _supabase = Supabase.instance.client;

  // Si el usuario ingresó un email real (ej. @gmail.com), lo usa directamente.
  // Los usuarios nuevos con username reciben un email ficticio @megavital.app.
  String _usernameToEmail(String username) {
    final trimmed = username.toLowerCase().trim();
    if (trimmed.contains('@')) return trimmed;
    final clean = trimmed.replaceAll('.', '_');
    return '$clean@megavital.app';
  }

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
    required String username,
    required String name,
    required String password,
    required String goal,
    required double weight,
    required double height,
    required int age,
    String gender = 'mujer',
    String? referredBy,
  }) async {
    try {
      final email = _usernameToEmail(username);
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name.trim(),
          'username': username.trim(),
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
    required String username,
    required String password,
  }) async {
    try {
      final email = _usernameToEmail(username);
      final response = await _supabase.auth.signInWithPassword(
        email: email,
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

  Future<UserProfile?> createProfileWithData({
    required AppUser user,
    required String username,
    required String name,
    required String goal,
    required double weight,
    required double height,
    required int age,
    String gender = 'mujer',
    String? referredBy,
  }) async {
    final email = _usernameToEmail(username);

    UserProfile buildLocal(UserProfile? saved) => UserProfile(
      uid:        saved?.uid      ?? user.uid,
      name:       saved?.name     ?? name.trim(),
      username:   saved?.username ?? username.trim(),
      email:      saved?.email    ?? email,
      goal:       saved?.goal     ?? goal,
      weight:     saved?.weight   ?? weight,
      height:     saved?.height   ?? height,
      age:        saved?.age      ?? age,
      createdAt:  saved?.createdAt ?? DateTime.now(),
      gender:     gender,
      referredBy: referredBy,
    );

    try {
      await _supabase.from('user_profiles').upsert({
        'uid':            user.uid,
        'name':           name.trim(),
        'username':       username.trim(),
        'email':          email,
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
      final saved = await getUserProfile(user.uid);
      return buildLocal(saved);
    } catch (_) {
      try {
        await _supabase.from('user_profiles').upsert({
          'uid':            user.uid,
          'name':           name.trim(),
          'email':          email,
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

  Future<UserProfile?> ensureUserProfile(AppUser user) async {
    final existing = await getUserProfile(user.uid);
    if (existing != null) return existing;

    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    final meta = _supabase.auth.currentUser?.userMetadata;
    if (meta == null) return null;

    final metaName     = (meta['name'] as String?)?.trim() ?? '';
    final metaUsername = (meta['username'] as String?)?.trim() ?? '';
    final metaGoal     = meta['goal'] as String?;
    final metaWeight   = (meta['weight'] as num?)?.toDouble();
    final metaHeight   = (meta['height'] as num?)?.toDouble();
    final metaAge      = (meta['age'] as num?)?.toInt();
    final metaGender   = meta['gender'] as String?;
    final metaReferred = meta['referred_by'] as String?;

    if (metaGoal == null || metaWeight == null || metaHeight == null || metaAge == null) {
      return null;
    }

    final name     = metaName.isNotEmpty ? metaName
        : (user.displayName.isNotEmpty ? user.displayName : 'Usuario');
    final username = metaUsername.isNotEmpty ? metaUsername
        : user.email.replaceAll('@megavital.app', '');

    return await createProfileWithData(
      user:       user,
      username:   username,
      name:       name,
      goal:       metaGoal,
      weight:     metaWeight,
      height:     metaHeight,
      age:        metaAge,
      gender:     metaGender ?? 'mujer',
      referredBy: metaReferred,
    );
  }

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

  Future<String?> uploadAvatar(String uid, File file) async {
    try {
      const bucket = 'avatars';
      final path = '$uid/avatar';
      await _supabase.storage.from(bucket).upload(
        path, file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      final url = _supabase.storage.from(bucket).getPublicUrl(path);
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
      return 'Nombre de usuario o contraseña incorrectos.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already registered')) {
      return 'Ese nombre de usuario ya está en uso.';
    }
    if (lower.contains('password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (lower.contains('unable to validate email') ||
        lower.contains('invalid format') ||
        lower.contains('valid email')) {
      return 'Nombre de usuario no válido. Usa solo letras, números y guiones bajos.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Sin conexión. Verifica tu internet.';
    }
    return message;
  }
}
