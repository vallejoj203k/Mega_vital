// lib/core/providers/premium_provider.dart
// Estado global del sistema premium.

import 'package:flutter/material.dart';
import '../../services/premium_service.dart';

export '../../services/premium_service.dart'
    show PremiumStatus, PremiumTier, RedeemResult, PremiumCodeInfo, PremiumStats, kPremiumTrialDays;

class PremiumProvider extends ChangeNotifier {
  final PremiumService _service;

  PremiumStatus _status    = PremiumStatus.expired();
  bool          _isLoading = false;
  String?       _error;

  PremiumProvider({PremiumService? service})
      : _service = service ?? PremiumService();

  PremiumStatus get status    => _status;
  bool          get isLoading => _isLoading;
  String?       get error     => _error;

  // True si el usuario puede acceder a las secciones premium
  bool get hasAccess => _status.isAccessible;
  bool get isTrial   => _status.tier == PremiumTier.trial;
  bool get isActive  => _status.tier == PremiumTier.active;

  // ── Verificar estado premium (llamar tras login/inicio) ───────
  Future<void> checkStatus(String userId, DateTime accountCreatedAt) async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    _status    = await _service.checkStatus(userId, accountCreatedAt);
    _isLoading = false;
    notifyListeners();
  }

  // ── Canjear código ────────────────────────────────────────────
  Future<RedeemResult> redeemCode(String code, String userId, DateTime accountCreatedAt) async {
    _isLoading = true;
    notifyListeners();

    final result = await _service.redeemCode(code);

    if (result.success) {
      // Refrescar estado tras canjear
      await checkStatus(userId, accountCreatedAt);
    } else {
      _isLoading = false;
      notifyListeners();
    }

    return result;
  }

  // ── Operaciones de administración ─────────────────────────────
  Future<String?> generateCode(String type) => _service.generateCode(type);

  Future<List<PremiumCodeInfo>> listCodes() => _service.listCodes();

  Future<PremiumStats> getStats() => _service.getStats();

  // ── Limpiar al cerrar sesión ──────────────────────────────────
  void clear() {
    _status    = PremiumStatus.expired();
    _isLoading = false;
    _error     = null;
    notifyListeners();
  }
}
