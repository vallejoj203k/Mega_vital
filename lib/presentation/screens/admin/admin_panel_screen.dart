// lib/presentation/screens/admin/admin_panel_screen.dart
// Panel de administración: generar y listar códigos premium.
// Acceso protegido por contraseña de administración.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/premium_provider.dart';

// ── Pantalla de acceso (contraseña) ─────────────────────────────
class AdminAccessScreen extends StatefulWidget {
  const AdminAccessScreen({super.key});

  @override
  State<AdminAccessScreen> createState() => _AdminAccessScreenState();
}

class _AdminAccessScreenState extends State<AdminAccessScreen> {
  final _ctrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  static const _adminKey = 'cocodemegavital';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_ctrl.text.trim() == _adminKey) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
      );
    } else {
      setState(() => _error = 'Contraseña incorrecta.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Acceso Administración', style: AppTextStyles.headingSmall),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.accentOrange,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text('Panel de Administración', style: AppTextStyles.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Ingresa la contraseña para continuar.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _ctrl,
              obscureText: _obscure,
              style: const TextStyle(color: AppColors.textPrimary),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Contraseña de administración',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.accentOrange, width: 1.5),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Entrar',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Panel principal ───────────────────────────────────────────────
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _generating = false;
  bool _loadingCodes = true;
  List<PremiumCodeInfo> _codes = [];

  final _memberCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  @override
  void dispose() {
    _memberCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCodes() async {
    setState(() => _loadingCodes = true);
    _codes = await context.read<PremiumProvider>().listCodes();
    if (mounted) setState(() => _loadingCodes = false);
  }

  Future<void> _generateCode(String type) async {
    final member = _memberCtrl.text.trim();
    if (member.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el nombre del miembro primero.'),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _generating = true);

    final code = await context
        .read<PremiumProvider>()
        .generateCode(type, memberName: member);

    if (!mounted) return;

    if (code != null) {
      await _sendWhatsApp(member: member, code: code, type: type);
      setState(() => _generating = false);
      await _loadCodes();
      if (mounted) _showCodeDialog(code, type, member);
    } else {
      setState(() => _generating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al generar el código. Verifica la conexión.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendWhatsApp({
    required String member,
    required String code,
    required String type,
  }) async {
    final planLabel = type[0].toUpperCase() + type.substring(1);
    final now = DateTime.now();
    final fecha =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}'
        '  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final text = Uri.encodeComponent(
      '🏋️ *Mega Vital — Código Premium*\n\n'
      'Se está generando un código de acceso premium:\n\n'
      '👤 Miembro: *$member*\n'
      '📦 Plan: *$planLabel*\n'
      '🔑 Código: *$code*\n\n'
      '📅 $fecha',
    );

    final uri =
        Uri.parse('https://wa.me/${AppConfig.ownerWhatsApp}?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showCodeDialog(String code, String type, String member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Text('Código generado', style: AppTextStyles.headingSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Plan: ${type[0].toUpperCase()}${type.substring(1)}  ·  $member',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.whatsapp,
                    color: AppColors.primary, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Dueño notificado por WhatsApp',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Entrega este código al socio en la caja del gimnasio.',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                content: Text('Código copiado'),
                backgroundColor: AppColors.primary,
              ));
            },
            child: const Text('Copiar',
                style: TextStyle(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:
            Text('Panel de Administración', style: AppTextStyles.headingSmall),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary),
            onPressed: _loadCodes,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Campo: nombre del miembro ───────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: TextField(
                  controller: _memberCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: AppTextStyles.bodyLarge,
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    labelText: 'Nombre del miembro',
                    hintText: 'Juan García',
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        color: AppColors.textMuted, size: 20),
                    labelStyle: AppTextStyles.bodyMedium,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.border, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.border, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ),

            // ── Generar código ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Generar código premium',
                        style: AppTextStyles.headingSmall),
                    const SizedBox(height: 6),
                    Text(
                      'Selecciona el plan. Se abrirá WhatsApp para notificar al dueño.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _PlanButton(
                          label: 'Mensual',
                          days: '30 días',
                          color: AppColors.accentBlue,
                          loading: _generating,
                          onTap: () => _generateCode('mensual'),
                        ),
                        const SizedBox(width: 10),
                        _PlanButton(
                          label: 'Trimestral',
                          days: '90 días',
                          color: AppColors.primary,
                          loading: _generating,
                          onTap: () => _generateCode('trimestral'),
                        ),
                        const SizedBox(width: 10),
                        _PlanButton(
                          label: 'Anual',
                          days: '365 días',
                          color: AppColors.accentOrange,
                          loading: _generating,
                          onTap: () => _generateCode('anual'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Códigos generados ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Códigos generados',
                        style: AppTextStyles.headingSmall),
                    Text(
                      '${_codes.length} total',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),

            if (_loadingCodes)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              )
            else if (_codes.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No hay códigos generados aún.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _CodeTile(info: _codes[i]),
                  childCount: _codes.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ── Botón de plan ─────────────────────────────────────────────────
class _PlanButton extends StatelessWidget {
  final String label, days;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _PlanButton({
    required this.label,
    required this.days,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: loading
              ? Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color),
                  ),
                )
              : Column(
                  children: [
                    Icon(Icons.add_circle_rounded, color: color, size: 22),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      days,
                      style: TextStyle(
                          fontSize: 10, color: color.withOpacity(0.7)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Tile de código en la lista ────────────────────────────────────
class _CodeTile extends StatelessWidget {
  final PremiumCodeInfo info;
  const _CodeTile({required this.info});

  Color _typeColor() {
    switch (info.type) {
      case 'mensual':    return AppColors.accentBlue;
      case 'trimestral': return AppColors.primary;
      case 'anual':      return AppColors.accentOrange;
      default:           return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final color = _typeColor();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: info.isUsed ? AppColors.border : color.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: info.isUsed ? AppColors.textMuted : color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        info.code,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: info.isUsed
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          info.type,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    info.memberName.isNotEmpty
                        ? '${info.memberName}  ·  ${info.isUsed ? 'Usado el ${_formatDate(info.usedAt!)}' : 'Generado el ${_formatDate(info.createdAt)}'}'
                        : info.isUsed
                            ? 'Usado el ${_formatDate(info.usedAt!)}'
                            : 'Generado el ${_formatDate(info.createdAt)}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: info.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Código copiado'),
                    backgroundColor: AppColors.primary,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: const Icon(Icons.copy_rounded,
                  color: AppColors.textMuted, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
