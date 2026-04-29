import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumCodeInfo {
  final String code;
  final String type;
  final String memberName;
  final bool isUsed;
  final DateTime? usedAt;
  final DateTime createdAt;

  const PremiumCodeInfo({
    required this.code,
    required this.type,
    required this.memberName,
    required this.isUsed,
    required this.createdAt,
    this.usedAt,
  });

  Map<String, dynamic> toJson() => {
    'code':        code,
    'type':        type,
    'memberName':  memberName,
    'isUsed':      isUsed,
    'createdAt':   createdAt.toIso8601String(),
    if (usedAt != null) 'usedAt': usedAt!.toIso8601String(),
  };

  factory PremiumCodeInfo.fromJson(Map<String, dynamic> j) => PremiumCodeInfo(
    code:       j['code'] as String,
    type:       j['type'] as String,
    memberName: j['memberName'] as String? ?? '',
    isUsed:     j['isUsed'] as bool? ?? false,
    createdAt:  DateTime.parse(j['createdAt'] as String),
    usedAt:     j['usedAt'] != null ? DateTime.parse(j['usedAt'] as String) : null,
  );
}

class PremiumProvider extends ChangeNotifier {
  static const _prefsKey = 'premium_codes';

  List<PremiumCodeInfo> _codes = [];
  List<PremiumCodeInfo> get codes => List.unmodifiable(_codes);

  static String _buildCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<List<PremiumCodeInfo>> listCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    _codes = raw
        .map((e) => PremiumCodeInfo.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
    return _codes;
  }

  Future<String?> generateCode(String type, {String memberName = ''}) async {
    try {
      final code = _buildCode();
      final info = PremiumCodeInfo(
        code:       code,
        type:       type,
        memberName: memberName.trim(),
        isUsed:     false,
        createdAt:  DateTime.now(),
      );
      _codes.insert(0, info);
      await _persist();
      notifyListeners();
      return code;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _codes.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
