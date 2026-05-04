// lib/presentation/screens/admin/admin_panel_screen.dart
// Panel de administración con dos secciones:
//   1. Códigos premium (mensual / trimestral / anual)
//   2. Códigos de registro + notificaciones al dueño

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/premium_provider.dart';
import '../../../services/registration_code_service.dart';

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
              onSubmitted: (_) => _submit(),
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

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'Premium'),
            Tab(text: 'Acceso'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PremiumTab(),
          _AccessTab(),
        ],
      ),
    );
  }
}

// ── Pestaña de códigos premium ────────────────────────────────────
class _PremiumTab extends StatefulWidget {
  const _PremiumTab();

  @override
  State<_PremiumTab> createState() => _PremiumTabState();
}

class _PremiumTabState extends State<_PremiumTab> {
  bool _generating = false;
  bool _loadingCodes = true;
  List<PremiumCodeInfo> _codes = [];

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    setState(() => _loadingCodes = true);
    _codes = await context.read<PremiumProvider>().listCodes();
    if (mounted) setState(() => _loadingCodes = false);
  }

  Future<void> _generateCode(String type) async {
    setState(() => _generating = true);
    final code = await context.read<PremiumProvider>().generateCode(type);
    if (!mounted) return;
    setState(() => _generating = false);
    if (code != null) {
      await _loadCodes();
      _showCodeDialog(code, type);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al generar el código. Verifica la conexión.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCodeDialog(String code, String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              'Plan: ${type[0].toUpperCase()}${type.substring(1)}',
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
            Text(
              'Entrega este código al socio en la caja del gimnasio.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                    content: Text('Código copiado'),
                    backgroundColor: AppColors.primary),
              );
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
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Generar código premium',
                    style: AppTextStyles.headingSmall),
                const SizedBox(height: 6),
                Text(
                  'Selecciona el tipo de plan y entrega el código al socio.',
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Códigos generados', style: AppTextStyles.headingSmall),
                Row(
                  children: [
                    Text('${_codes.length} total',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _loadCodes,
                      child: const Icon(Icons.refresh_rounded,
                          color: AppColors.textMuted, size: 18),
                    ),
                  ],
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
                  'No hay códigos premium generados aún.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _PremiumCodeTile(info: _codes[i]),
              childCount: _codes.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ── Pestaña de códigos de acceso + notificaciones ─────────────────
class _AccessTab extends StatefulWidget {
  const _AccessTab();

  @override
  State<_AccessTab> createState() => _AccessTabState();
}

class _AccessTabState extends State<_AccessTab> {
  final _service = RegistrationCodeService();
  final _forCtrl = TextEditingController();

  bool _generating = false;
  bool _loading = true;
  List<RegistrationCodeInfo> _codes = [];
  List<AdminNotificationInfo> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _forCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _service.listCodes(),
      _service.listOwnerNotifications(),
    ]);
    if (!mounted) return;
    setState(() {
      _codes         = results[0] as List<RegistrationCodeInfo>;
      _notifications = results[1] as List<AdminNotificationInfo>;
      _loading       = false;
    });
  }

  Future<void> _generateCode() async {
    final name = _forCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el nombre de la persona'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _generating = true);
    final code = await _service.generateCode(name);
    if (!mounted) return;
    setState(() => _generating = false);
    if (code != null) {
      _forCtrl.clear();
      await _load();
      _showCodeDialog(code, name);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al generar el código. Verifica la conexión.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCodeDialog(String code, String forName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              'Para: $forName',
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
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Entrega este código a $forName para que pueda crear su cuenta.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                    content: Text('Código copiado'),
                    backgroundColor: AppColors.primary),
              );
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
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Generar nuevo código ──────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nuevo código de registro',
                    style: AppTextStyles.headingSmall),
                const SizedBox(height: 6),
                Text(
                  'Genera un código único para que un nuevo miembro pueda crear su cuenta.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _forCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Para quién es el código',
                    hintText: 'Ej: Juan García',
                    labelStyle:
                        const TextStyle(color: AppColors.textSecondary),
                    hintStyle:
                        const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        color: AppColors.textMuted, size: 20),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generating ? null : _generateCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      disabledBackgroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _generating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary),
                          )
                        : const Icon(Icons.key_rounded, size: 18),
                    label: Text(
                      _generating ? 'Generando...' : 'Generar código',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Lista de códigos ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Códigos de registro',
                    style: AppTextStyles.headingSmall),
                Row(
                  children: [
                    Text('${_codes.length} total',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _load,
                      child: const Icon(Icons.refresh_rounded,
                          color: AppColors.textMuted, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        if (_loading)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          )
        else if (_codes.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No hay códigos de registro generados aún.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _RegCodeTile(info: _codes[i]),
              childCount: _codes.length,
            ),
          ),

        // ── Notificaciones del dueño ──────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
            child: Row(
              children: [
                const Icon(Icons.notifications_rounded,
                    color: AppColors.accentOrange, size: 20),
                const SizedBox(width: 8),
                Text('Actividad reciente', style: AppTextStyles.headingSmall),
              ],
            ),
          ),
        ),

        if (!_loading && _notifications.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Sin actividad registrada aún.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _NotificationTile(info: _notifications[i]),
              childCount: _notifications.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ── Botón de plan premium ─────────────────────────────────────────
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
                      style:
                          TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Tile de código premium ────────────────────────────────────────
class _PremiumCodeTile extends StatelessWidget {
  final PremiumCodeInfo info;
  const _PremiumCodeTile({required this.info});

  Color _typeColor() {
    switch (info.type) {
      case 'mensual':    return AppColors.accentBlue;
      case 'trimestral': return AppColors.primary;
      case 'anual':      return AppColors.accentOrange;
      default:           return AppColors.textSecondary;
    }
  }

  String _fmt(DateTime dt) =>
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
              width: 8, height: 8,
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
                    info.isUsed
                        ? 'Usado el ${_fmt(info.usedAt!)}'
                        : 'Generado el ${_fmt(info.createdAt)}',
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

// ── Tile de código de registro ────────────────────────────────────
class _RegCodeTile extends StatelessWidget {
  final RegistrationCodeInfo info;
  const _RegCodeTile({required this.info});

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final used = info.isUsed;
    final color = used ? AppColors.textMuted : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: used ? AppColors.border : AppColors.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
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
                          color: used
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
                          used ? 'usado' : 'disponible',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Para: ${info.createdFor}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    used && info.usedAt != null
                        ? 'Usado el ${_fmt(info.usedAt!)}'
                        : 'Generado el ${_fmt(info.createdAt)}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (!used)
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

// ── Tile de notificación del dueño ────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final AdminNotificationInfo info;
  const _NotificationTile({required this.info});

  String _fmt(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.accentOrange.withOpacity(0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.key_rounded,
                  color: AppColors.accentOrange, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(info.body,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(_fmt(info.createdAt),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
