import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUserInfo {
  final String uid;
  final String name;
  final String username;
  final String email;
  final DateTime createdAt;

  const AdminUserInfo({
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    required this.createdAt,
  });

  factory AdminUserInfo.fromMap(Map<String, dynamic> m) {
    final email = m['email'] as String? ?? '';
    final derivedUsername = email.replaceAll('@megavital.app', '');
    return AdminUserInfo(
      uid:       m['uid']  as String,
      name:      m['name'] as String,
      username:  derivedUsername,
      email:     email,
      createdAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AdminUserService {
  static const _adminKey = 'cocodemegavital';
  final _supabase = Supabase.instance.client;

  /// Retorna la lista de usuarios o lanza una excepción con el mensaje de error.
  Future<List<AdminUserInfo>> listUsers() async {
    final data = await _supabase
        .rpc('admin_list_users', params: {'admin_key': _adminKey});
    if (data == null) return [];
    return (data as List)
        .map((e) => AdminUserInfo.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> deleteUser(String targetUid) async {
    try {
      await _supabase.rpc('admin_delete_user', params: {
        'admin_key': _adminKey,
        'target_uid': targetUid,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
