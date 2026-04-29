// lib/services/premium_service.dart
// Gestión del sistema premium: prueba gratuita, códigos, suscripciones.

import 'package:supabase_flutter/supabase_flutter.dart';

// ── Duración de la prueba gratuita ────────────────────────────
const int kPremiumTrialDays = 2;

enum PremiumTier { trial, active, expired }

class PremiumStatus {
  final PremiumTier tier;
  final DateTime?   expiresAt;
  final String?     type; // mensual | trimestral | anual

  const PremiumStatus._({required this.tier, this.expiresAt, this.type});

  factory PremiumStatus.trial(DateTime expiresAt) =>
      PremiumStatus._(tier: PremiumTier.trial, expiresAt: expiresAt);

  factory PremiumStatus.active({required DateTime expiresAt, required String type}) =>
      PremiumStatus._(tier: PremiumTier.active, expiresAt: expiresAt, type: type);

  factory PremiumStatus.expired() =>
      const PremiumStatus._(tier: PremiumTier.expired);

  bool get isAccessible => tier == PremiumTier.trial || tier == PremiumTier.active;

  int get daysRemaining {
    if (expiresAt == null) return 0;
    final diff = expiresAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}

class RedeemResult {
  final bool     success;
  final String?  message;
  final DateTime? expiresAt;
  final String?  type;

  const RedeemResult._({required this.success, this.message, this.expiresAt, this.type});

  factory RedeemResult.ok({required DateTime expiresAt, required String type}) =>
      RedeemResult._(success: true, expiresAt: expiresAt, type: type);

  factory RedeemResult.fail(String message) =>
      RedeemResult._(success: false, message: message);
}

class PremiumCodeInfo {
  final String    id;
  final String    code;
  final String    type;
  final int       durationDays;
  final bool      isUsed;
  final DateTime  createdAt;
  final DateTime? usedAt;

  const PremiumCodeInfo({
    required this.id,
    required this.code,
    required this.type,
    required this.durationDays,
    required this.isUsed,
    required this.createdAt,
    this.usedAt,
  });

  factory PremiumCodeInfo.fromMap(Map<String, dynamic> m) => PremiumCodeInfo(
    id:           m['id'] as String,
    code:         m['code'] as String,
    type:         m['type'] as String,
    durationDays: (m['duration_days'] as num).toInt(),
    isUsed:       m['is_used'] as bool,
    createdAt:    DateTime.parse(m['created_at'] as String),
    usedAt:       m['used_at'] != null ? DateTime.parse(m['used_at'] as String) : null,
  );
}

class PremiumService {
  final _db = Supabase.instance.client;

  // ── Verificar estado premium del usuario actual ───────────────
  Future<PremiumStatus> checkStatus(String userId, DateTime accountCreatedAt) async {
    final now = DateTime.now();
    final trialExpiry = accountCreatedAt.add(Duration(days: kPremiumTrialDays));

    // Primero verificar si está en período de prueba
    if (now.isBefore(trialExpiry)) {
      return PremiumStatus.trial(trialExpiry);
    }

    // Verificar suscripción activa via RPC
    try {
      final result = await _db.rpc('get_my_premium_subscription');
      final map = result as Map<String, dynamic>;
      if (map['found'] == true && map['is_active'] == true) {
        return PremiumStatus.active(
          expiresAt: DateTime.parse(map['expires_at'] as String),
          type:      map['type'] as String,
        );
      }
    } catch (_) {}

    return PremiumStatus.expired();
  }

  // ── Canjear un código premium ─────────────────────────────────
  Future<RedeemResult> redeemCode(String code) async {
    try {
      final result = await _db.rpc('redeem_premium_code', params: {'code_text': code.trim()});
      final map = result as Map<String, dynamic>;
      if (map['success'] == true) {
        return RedeemResult.ok(
          expiresAt: DateTime.parse(map['expires_at'] as String),
          type:      map['type'] as String,
        );
      }
      return RedeemResult.fail(map['message'] as String? ?? 'Error al canjear el código.');
    } on PostgrestException catch (e) {
      return RedeemResult.fail(e.message);
    } catch (_) {
      return RedeemResult.fail('Error de conexión. Intenta de nuevo.');
    }
  }

  // ── Generar código (solo administración) ──────────────────────
  Future<String?> generateCode(String type) async {
    try {
      final result = await _db.rpc('generate_premium_code', params: {
        'admin_key': 'cocodemegavital',
        'code_type': type,
      });
      return result as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Listar códigos generados (solo administración) ────────────
  Future<List<PremiumCodeInfo>> listCodes() async {
    try {
      final result = await _db.rpc('list_premium_codes', params: {'admin_key': 'cocodemegavital'});
      final list = result as List<dynamic>;
      return list.map((e) => PremiumCodeInfo.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
