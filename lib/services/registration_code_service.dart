// lib/services/registration_code_service.dart
// Gestión de códigos de registro: el administrador genera un código único
// para cada persona que va a crear una cuenta, y el dueño recibe una
// notificación cada vez que se genera un código nuevo.

import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationCodeInfo {
  final String id;
  final String code;
  final String createdFor;
  final bool isUsed;
  final String? usedBy;
  final DateTime? usedAt;
  final DateTime createdAt;

  const RegistrationCodeInfo({
    required this.id,
    required this.code,
    required this.createdFor,
    required this.isUsed,
    this.usedBy,
    this.usedAt,
    required this.createdAt,
  });

  factory RegistrationCodeInfo.fromMap(Map<String, dynamic> m) =>
      RegistrationCodeInfo(
        id:         m['id'] as String,
        code:       m['code'] as String,
        createdFor: m['created_for'] as String,
        isUsed:     m['is_used'] as bool,
        usedBy:     m['used_by'] as String?,
        usedAt:     m['used_at'] != null
            ? DateTime.tryParse(m['used_at'] as String)
            : null,
        createdAt:  DateTime.parse(m['created_at'] as String),
      );
}

class AdminNotificationInfo {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  const AdminNotificationInfo({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory AdminNotificationInfo.fromMap(Map<String, dynamic> m) =>
      AdminNotificationInfo(
        id:        m['id'] as String,
        title:     m['title'] as String,
        body:      m['body'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

class RegistrationCodeService {
  final _db = Supabase.instance.client;

  static const _adminKey = 'cocodemegavital';

  // ── Generar un código de registro (solo administradores) ──────────
  Future<String?> generateCode(String createdFor) async {
    try {
      final result = await _db.rpc('generate_registration_code', params: {
        'admin_key':   _adminKey,
        'created_for': createdFor.trim(),
      });
      return result as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Validar un código antes de permitir el registro ───────────────
  Future<({bool valid, String message})> validateCode(String code) async {
    try {
      final result = await _db.rpc('validate_registration_code', params: {
        'code_text': code.trim().toUpperCase(),
      });
      final map = result as Map<String, dynamic>;
      return (
        valid:   map['valid'] as bool,
        message: map['message'] as String,
      );
    } catch (_) {
      return (valid: false, message: 'Error de conexión. Intenta de nuevo.');
    }
  }

  // ── Marcar el código como usado tras el registro exitoso ──────────
  Future<bool> useCode(String code) async {
    try {
      final result = await _db.rpc('use_registration_code', params: {
        'code_text': code.trim().toUpperCase(),
      });
      return result as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  // ── Listar todos los códigos de registro (solo administradores) ───
  Future<List<RegistrationCodeInfo>> listCodes() async {
    try {
      final result = await _db.rpc('list_registration_codes', params: {
        'admin_key': _adminKey,
      });
      final list = result as List<dynamic>;
      return list
          .map((e) => RegistrationCodeInfo.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Listar notificaciones del dueño (solo administradores) ────────
  Future<List<AdminNotificationInfo>> listOwnerNotifications() async {
    try {
      final result = await _db.rpc('list_admin_notifications', params: {
        'admin_key': _adminKey,
      });
      final list = result as List<dynamic>;
      return list
          .map((e) =>
              AdminNotificationInfo.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
