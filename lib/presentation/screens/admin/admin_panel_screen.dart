// lib/presentation/screens/admin/admin_panel_screen.dart
// Panel de administración con tres secciones:
//   1. Códigos premium (mensual / trimestral / anual)
//   2. Códigos de registro + notificaciones al dueño
//   3. Lista de todos los usuarios

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme_colors.dart';
import '../../../core/data/muscle_data.dart';
import '../../../core/providers/class_provider.dart';
import '../../../core/providers/exercise_provider.dart';
import '../../../core/providers/premium_provider.dart';
import '../../../services/class_schedule_service.dart';
import '../../../services/exercise_service.dart';
import '../../../services/registration_code_service.dart';

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
    _tabController = TabController(length: 5, vsync: this);
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
            Tab(text: 'Usuarios'),
            Tab(text: 'Ejercicios'),
            Tab(text: 'Clases'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PremiumTab(),
          _AccessTab(),
          _UsersTab(),
          _ExercisesTab(),
          _ClassSchedulesTab(),
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

// ── Modelo de usuario admin ───────────────────────────────────────
class AdminUserInfo {
  final String uid;
  final String name;
  final String email;
  final String goal;
  final double weight;
  final double height;
  final int age;
  final int streak;
  final int totalWorkouts;
  final DateTime? createdAt;
  final String? avatarUrl;
  final String? gender;
  final bool isPremium;
  final String? premiumType;
  final DateTime? premiumExpiresAt;

  const AdminUserInfo({
    required this.uid,
    required this.name,
    required this.email,
    required this.goal,
    required this.weight,
    required this.height,
    required this.age,
    required this.streak,
    required this.totalWorkouts,
    this.createdAt,
    this.avatarUrl,
    this.gender,
    required this.isPremium,
    this.premiumType,
    this.premiumExpiresAt,
  });

  factory AdminUserInfo.fromMap(Map<String, dynamic> m) => AdminUserInfo(
        uid:              m['uid'] as String,
        name:             m['name'] as String? ?? '',
        email:            m['email'] as String? ?? '',
        goal:             m['goal'] as String? ?? '',
        weight:           (m['weight'] as num?)?.toDouble() ?? 0,
        height:           (m['height'] as num?)?.toDouble() ?? 0,
        age:              m['age'] as int? ?? 0,
        streak:           m['streak'] as int? ?? 0,
        totalWorkouts:    m['total_workouts'] as int? ?? 0,
        createdAt:        m['created_at'] != null
                            ? DateTime.tryParse(m['created_at'] as String)
                            : null,
        avatarUrl:        m['avatar_url'] as String?,
        gender:           m['gender'] as String?,
        isPremium:        m['is_premium'] as bool? ?? false,
        premiumType:      m['premium_type'] as String?,
        premiumExpiresAt: m['premium_expires_at'] != null
                            ? DateTime.tryParse(m['premium_expires_at'] as String)
                            : null,
      );

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ── Pestaña de usuarios ───────────────────────────────────────────
class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _db = Supabase.instance.client;
  final _search = TextEditingController();

  bool _loading = true;
  String? _error;
  List<AdminUserInfo> _all = [];
  List<AdminUserInfo> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await _db.rpc('admin_list_users') as List;
      _all = rows.map((r) => AdminUserInfo.fromMap(r as Map<String, dynamic>)).toList();
      _filter();
    } catch (e) {
      _error = 'No se pudo cargar la lista de usuarios.\n'
               'Asegúrate de haber ejecutado el SQL de admin_list_users() en Supabase.';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _filter() {
    final q = _search.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_all)
          : _all.where((u) =>
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q)).toList();
    });
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Encabezado + buscador ─────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Usuarios registrados',
                      style: AppTextStyles.headingSmallOf(context)),
                  const Spacer(),
                  if (!_loading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${_all.length} total',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _load,
                    child: Icon(Icons.refresh_rounded,
                        color: tc.textMuted, size: 20),
                  ),
                ]),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  style: AppTextStyles.bodyLargeOf(context),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o email…',
                    hintStyle: AppTextStyles.bodyLargeOf(context)
                        .copyWith(color: tc.textMuted),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: tc.textMuted, size: 20),
                    suffixIcon: _search.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () { _search.clear(); _filter(); },
                            child: Icon(Icons.close, color: tc.textMuted, size: 18))
                        : null,
                    filled: true,
                    fillColor: tc.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),

        // ── Estado de carga / error / vacío ───────────────────────
        if (_loading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            ),
          )
        else if (_error != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Column(children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 32),
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: TextStyle(color: tc.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _load,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white),
                    child: const Text('Reintentar'),
                  ),
                ]),
              ),
            ),
          )
        else if (_filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  _search.text.isEmpty
                      ? 'No hay usuarios registrados.'
                      : 'Sin resultados para "${_search.text}".',
                  style: AppTextStyles.bodyMediumOf(context),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _UserTile(user: _filtered[i], fmt: _fmt),
              childCount: _filtered.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ── Tile de usuario ───────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final AdminUserInfo user;
  final String Function(DateTime?) fmt;
  const _UserTile({required this.user, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final hasPhoto = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: user.isPremium
                ? AppColors.accentOrange.withOpacity(0.4)
                : tc.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera: avatar + nombre + premium badge ──────────
            Row(children: [
              Container(
                width: 44, height: 44,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.12),
                ),
                alignment: Alignment.center,
                child: hasPhoto
                    ? Image.network(user.avatarUrl!,
                        width: 44, height: 44, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initials(user))
                    : _initials(user),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(user.name,
                      style: AppTextStyles.labelLargeOf(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(user.email,
                      style: TextStyle(
                          fontSize: 12,
                          color: tc.textSecondary,
                          fontWeight: FontWeight.w400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ]),
              ),
              if (user.isPremium)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.accentOrange.withOpacity(0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.accentOrange, size: 11),
                    const SizedBox(width: 3),
                    Text(
                      user.premiumType ?? 'Premium',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentOrange),
                    ),
                  ]),
                ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showCreditsDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.accentBlue.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.confirmation_number_rounded,
                      color: AppColors.accentBlue, size: 16),
                ),
              ),
            ]),

            const SizedBox(height: 12),
            Divider(color: tc.divider, height: 1),
            const SizedBox(height: 10),

            // ── Stats en fila ──────────────────────────────────────
            Row(children: [
              _Stat(icon: Icons.fitness_center_rounded,
                  label: '${user.totalWorkouts} entrenos',
                  color: AppColors.primary),
              const SizedBox(width: 16),
              _Stat(icon: Icons.local_fire_department_rounded,
                  label: '${user.streak} días',
                  color: AppColors.accentOrange),
              const SizedBox(width: 16),
              _Stat(icon: Icons.monitor_weight_outlined,
                  label: '${user.weight.toStringAsFixed(0)} kg',
                  color: AppColors.accentBlue),
            ]),

            const SizedBox(height: 8),

            // ── Info secundaria ────────────────────────────────────
            Row(children: [
              Icon(Icons.flag_outlined, size: 12, color: tc.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(user.goal,
                    style: TextStyle(
                        fontSize: 11,
                        color: tc.textSecondary,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Icon(Icons.calendar_today_outlined,
                  size: 11, color: tc.textMuted),
              const SizedBox(width: 4),
              Text('Desde ${fmt(user.createdAt)}',
                  style: TextStyle(fontSize: 11, color: tc.textMuted)),
            ]),

            if (user.isPremium && user.premiumExpiresAt != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.schedule_rounded,
                    size: 11, color: AppColors.accentOrange),
                const SizedBox(width: 4),
                Text('Premium hasta ${fmt(user.premiumExpiresAt)}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.accentOrange,
                        fontWeight: FontWeight.w600)),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _initials(AdminUserInfo u) => Text(u.initials,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.primary));

  // ── Diálogo de créditos de clases (pago en recepción) ────────────
  void _showCreditsDialog(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final service = ClassScheduleService();
    final qtyCtrl = TextEditingController(text: '1');
    int? balance;
    bool busy = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          // Consultar saldo actual al abrir (delta 0)
          if (balance == null && !busy) {
            busy = true;
            service.adminAdjustCredits(user.uid, 0).then((v) {
              if (dialogCtx.mounted) setDlg(() { balance = v ?? 0; busy = false; });
            });
          }

          Future<void> apply(int sign) async {
            final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
            if (qty <= 0 || busy) return;
            setDlg(() => busy = true);
            final v = await service.adminAdjustCredits(user.uid, sign * qty);
            if (!dialogCtx.mounted) return;
            setDlg(() { if (v != null) balance = v; busy = false; });
          }

          return AlertDialog(
            backgroundColor: tc.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Icon(Icons.confirmation_number_rounded,
                  color: AppColors.accentBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Clases de ${user.name}',
                  style: AppTextStyles.headingSmallOf(ctx),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.accentBlue.withOpacity(0.25)),
                ),
                child: Column(children: [
                  Text(balance == null ? '…' : '$balance',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentBlue)),
                  Text('clases disponibles',
                      style: TextStyle(fontSize: 11, color: tc.textSecondary)),
                ]),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLargeOf(ctx),
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  labelStyle: TextStyle(color: tc.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: tc.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : () => apply(1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Cargar',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : () => apply(-1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                          color: AppColors.error.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.remove_rounded, size: 16),
                    label: const Text('Quitar',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text('Cerrar',
                    style: TextStyle(color: tc.textSecondary)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Stat({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ]);
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

// ── Pestaña de ejercicios ─────────────────────────────────────────
class _ExercisesTab extends StatefulWidget {
  const _ExercisesTab();

  @override
  State<_ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<_ExercisesTab> {
  final _service = ExerciseService();
  String _selectedMuscle = kMuscleGroups.first.id;

  Future<void> _reload() => context.read<ExerciseProvider>().reload();

  // ── Diálogo crear / editar ──────────────────────────────────────
  void _showForm({ExerciseItem? editing}) {
    final isEdit   = editing != null;
    final idCtrl   = TextEditingController(text: editing?.id   ?? '');
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final setsCtrl = TextEditingController(text: editing?.sets ?? '3-4');
    final repsCtrl = TextEditingController(text: editing?.reps ?? '10-12');
    final restCtrl = TextEditingController(
        text: (editing?.restSeconds ?? 60).toString());
    final tipCtrl  = TextEditingController(text: editing?.tip ?? '');
    String selMuscle = editing?.muscleId ?? _selectedMuscle;
    ExerciseDifficulty selDiff = editing?.difficulty ?? ExerciseDifficulty.medio;

    final diffLabels = {
      ExerciseDifficulty.facil: 'Fácil',
      ExerciseDifficulty.medio: 'Medio',
      ExerciseDifficulty.duro:  'Difícil',
    };

    InputDecoration _dec(String label, {String? hint, String? helper}) =>
        InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintStyle: const TextStyle(color: AppColors.textMuted),
          helperStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.accentOrange, width: 1.5)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? 'Editar ejercicio' : 'Nuevo ejercicio',
              style: AppTextStyles.headingSmall),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (!isEdit) ...[
                  TextField(
                    controller: idCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _dec('ID del ejercicio',
                        hint: 'pec8, hom7, esp5…',
                        helper: 'Define la carpeta del video/imagen en Storage'),
                  ),
                  const SizedBox(height: 10),
                ],
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _dec('Nombre del ejercicio'),
                ),
                const SizedBox(height: 10),
                // Músculo
                DropdownButtonFormField<String>(
                  value: selMuscle,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: _dec('Grupo muscular'),
                  items: kMuscleGroups.map((g) => DropdownMenuItem(
                    value: g.id,
                    child: Text(g.name),
                  )).toList(),
                  onChanged: (v) { if (v != null) setSt(() => selMuscle = v); },
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(
                    controller: setsCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _dec('Series', hint: '3-4'),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: repsCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _dec('Reps', hint: '10-12'),
                  )),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(
                    controller: restCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _dec('Descanso (seg)', hint: '60'),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: DropdownButtonFormField<ExerciseDifficulty>(
                    value: selDiff,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: _dec('Dificultad'),
                    items: ExerciseDifficulty.values.map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(diffLabels[d]!),
                    )).toList(),
                    onChanged: (v) { if (v != null) setSt(() => selDiff = v); },
                  )),
                ]),
                const SizedBox(height: 10),
                TextField(
                  controller: tipCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _dec('Tip (opcional)'),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final idVal   = idCtrl.text.trim();
                final nameVal = nameCtrl.text.trim();
                if (nameVal.isEmpty || (!isEdit && idVal.isEmpty)) return;

                final ex = ExerciseItem(
                  id:          isEdit ? editing!.id : idVal,
                  name:        nameVal,
                  muscleId:    selMuscle,
                  sets:        setsCtrl.text.trim().isEmpty ? '3-4' : setsCtrl.text.trim(),
                  reps:        repsCtrl.text.trim().isEmpty ? '10-12' : repsCtrl.text.trim(),
                  restSeconds: int.tryParse(restCtrl.text.trim()) ?? 60,
                  tip:         tipCtrl.text.trim().isEmpty ? null : tipCtrl.text.trim(),
                  icon:        ExerciseItem.iconFor(selMuscle),
                  difficulty:  selDiff,
                );

                final provider = context.read<ExerciseProvider>();
                final currentCount = provider.exercises
                    .where((e) => e.muscleId == selMuscle).length;
                final ok = isEdit
                    ? await _service.update(ex)
                    : await _service.create(ex, displayOrder: currentCount);

                if (!mounted) return;
                Navigator.pop(ctx);
                if (ok) {
                  await provider.reload();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al guardar el ejercicio.')),
                  );
                }
              },
              child: Text(isEdit ? 'Guardar' : 'Crear'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _confirmDelete(ExerciseItem ex) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar ejercicio',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('¿Eliminar "${ex.name}"?\nEsto no elimina el video/imagen en Storage.',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final deleted = await _service.delete(ex.id);
      if (mounted) {
        if (deleted) {
          await _reload();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al eliminar el ejercicio.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final items = provider.exercises
        .where((e) => e.muscleId == _selectedMuscle).toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.accentOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(children: [
        // Selector de grupo muscular
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: kMuscleGroups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final g = kMuscleGroups[i];
              final sel = g.id == _selectedMuscle;
              return GestureDetector(
                onTap: () => setState(() => _selectedMuscle = g.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.accentOrange : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? AppColors.accentOrange : AppColors.surface,
                    ),
                  ),
                  child: Text(g.nameShort,
                      style: TextStyle(
                        color: sel ? Colors.white : AppColors.textSecondary,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      )),
                ),
              );
            },
          ),
        ),
        // Lista
        Expanded(
          child: provider.loading
              ? const Center(child: CircularProgressIndicator(
                  color: AppColors.accentOrange))
              : items.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.fitness_center_rounded,
                            size: 48, color: AppColors.textMuted.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text('Sin ejercicios en este grupo',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        Text('Usa el botón + para agregar',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textMuted)),
                      ]),
                    )
                  : RefreshIndicator(
                      color: AppColors.accentOrange,
                      onRefresh: _reload,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final ex = items[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              leading: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.accentOrange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.fitness_center_rounded,
                                    color: AppColors.accentOrange, size: 20),
                              ),
                              title: Text(ex.name,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              subtitle: Text(
                                '${ex.id}  ·  ${ex.sets} series  ·  ${ex.reps} reps  ·  ${ex.restSeconds}s',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 11),
                              ),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded,
                                      color: AppColors.accentOrange, size: 20),
                                  onPressed: () => _showForm(editing: ex),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded,
                                      color: Colors.red.shade400, size: 20),
                                  onPressed: () => _confirmDelete(ex),
                                  tooltip: 'Eliminar',
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}

// ── Pestaña de horarios de clases ─────────────────────────────────

class _ClassSchedulesTab extends StatefulWidget {
  const _ClassSchedulesTab();

  @override
  State<_ClassSchedulesTab> createState() => _ClassSchedulesTabState();
}

class _ClassSchedulesTabState extends State<_ClassSchedulesTab> {
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().loadSchedules();
    });
  }

  void _showForm({ClassSchedule? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleFormSheet(
        editing: editing,
        onSave: (s) async {
          final provider = context.read<ClassProvider>();
          final ok = editing == null
              ? await provider.createSchedule(s)
              : await provider.updateSchedule(s);
          if (!context.mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok
                ? (editing == null ? 'Horario creado.' : 'Horario actualizado.')
                : 'Error al guardar.'),
            backgroundColor: ok ? AppColors.primary : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        },
      ),
    );
  }

  void _confirmDelete(ClassSchedule s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Eliminar horario', style: AppTextStyles.headingSmall),
        content: Text('¿Deseas eliminar "${s.name}"?',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context.read<ClassProvider>().deleteSchedule(s.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? 'Horario eliminado.' : 'Error al eliminar.'),
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  static const _dayLabels = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  String _scheduleDescription(ClassSchedule s) {
    switch (s.scheduleType) {
      case 'daily':   return 'Todos los días';
      case 'monthly': return 'Día ${s.dayOfMonth} de cada mes';
      case 'weekly':
      case 'custom':
        final days = s.daysOfWeek.map((d) => _dayLabels[d]).join(', ');
        return days.isEmpty ? 'Sin días' : days;
      default: return s.scheduleType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClassProvider>();
    final schedules = provider.schedules;
    final spinning = schedules.where((s) => s.activity == 'spinning').toList();
    final running  = schedules.where((s) => s.activity == 'running').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _showCalendar
          ? null
          : FloatingActionButton(
              onPressed: () => _showForm(),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
      body: Column(children: [
        // ── Toggle Horarios / Calendario ───────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(children: [
              _ViewToggleBtn(
                label: 'Horarios',
                icon: Icons.list_alt_rounded,
                active: !_showCalendar,
                onTap: () => setState(() => _showCalendar = false),
              ),
              _ViewToggleBtn(
                label: 'Calendario',
                icon: Icons.calendar_month_rounded,
                active: _showCalendar,
                onTap: () => setState(() => _showCalendar = true),
              ),
            ]),
          ),
        ),
        Expanded(
          child: _showCalendar
              ? const _ClassCalendarView()
              : schedules.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.event_note_rounded,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('Sin horarios creados',
                            style: AppTextStyles.headingSmall.copyWith(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text('Pulsa + para agregar un horario.',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMuted)),
                      ]),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      children: [
                        if (spinning.isNotEmpty) ...[
                          _SectionHeader(
                            icon: Icons.directions_bike_rounded,
                            label: 'Spinning',
                            color: const Color(0xFFFF6B35),
                          ),
                          ...spinning.map((s) => _ScheduleTile(
                            schedule:    s,
                            description: _scheduleDescription(s),
                            onEdit:      () => _showForm(editing: s),
                            onDelete:    () => _confirmDelete(s),
                          )),
                          const SizedBox(height: 8),
                        ],
                        if (running.isNotEmpty) ...[
                          _SectionHeader(
                            icon: Icons.directions_run_rounded,
                            label: 'Running',
                            color: AppColors.accentBlue,
                          ),
                          ...running.map((s) => _ScheduleTile(
                            schedule:    s,
                            description: _scheduleDescription(s),
                            onEdit:      () => _showForm(editing: s),
                            onDelete:    () => _confirmDelete(s),
                          )),
                        ],
                      ],
                    ),
        ),
      ]),
    );
  }
}

class _ViewToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ViewToggleBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 15,
                  color: active ? Colors.black : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.black : AppColors.textMuted)),
            ]),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
// CALENDARIO SEMANAL DE CLASES (vista admin)
// Réplica digital de la pizarra: días en columnas, horas en filas.
// Tocar una clase muestra los nombres de quienes reservaron.
// ─────────────────────────────────────────────────────────────────
class _ClassCalendarView extends StatefulWidget {
  const _ClassCalendarView();

  @override
  State<_ClassCalendarView> createState() => _ClassCalendarViewState();
}

class _ClassCalendarViewState extends State<_ClassCalendarView> {
  final _service = ClassScheduleService();
  late DateTime _weekStart; // lunes de la semana visible
  List<ClassSession> _sessions = [];
  bool _loading = true;

  static const _dayNames   = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _monthNames = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                              'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
  static const _spinColor = Color(0xFFFF6B35);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _weekStart = today.subtract(Duration(days: today.weekday - 1));
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final sessions = await _service.fetchWeekSessionsAdmin(_weekStart);
    if (!mounted) return;
    setState(() { _sessions = sessions; _loading = false; });
  }

  void _changeWeek(int delta) {
    setState(() => _weekStart = _weekStart.add(Duration(days: 7 * delta)));
    _load();
  }

  String get _weekLabel {
    final end = _weekStart.add(const Duration(days: 6));
    if (_weekStart.month == end.month) {
      return '${_weekStart.day} – ${end.day} ${_monthNames[end.month]} ${end.year}';
    }
    return '${_weekStart.day} ${_monthNames[_weekStart.month]} – ${end.day} ${_monthNames[end.month]} ${end.year}';
  }

  String _fmtHour(int hour) {
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12 ${hour < 12 ? 'am' : 'pm'}';
  }

  void _showSessionDetail(ClassSession s) {
    final color = s.activity == 'spinning' ? _spinColor : AppColors.accentBlue;
    final time = formatTime12h(s.startsAt.hour, s.startsAt.minute);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(
              s.activity == 'spinning'
                  ? Icons.directions_bike_rounded
                  : Icons.directions_run_rounded,
              color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text(s.scheduleName,
                  style: AppTextStyles.headingSmall,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Icon(Icons.calendar_today_rounded,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                  '${_dayNames[s.sessionDate.weekday]} ${s.sessionDate.day} ${_monthNames[s.sessionDate.month]} · $time',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${s.bookedCount}/${s.capacity}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ),
            ]),
            const SizedBox(height: 14),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _service.fetchSessionAttendees(s.id),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  );
                }
                final attendees = snap.data ?? [];
                if (attendees.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(children: [
                      const Icon(Icons.person_off_rounded,
                          size: 32, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text('Sin reservas aún',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textMuted)),
                    ]),
                  );
                }
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: attendees.length,
                    itemBuilder: (_, i) {
                      final name = attendees[i]['user_name'] as String? ?? '—';
                      final seat = attendees[i]['seat_index'] as int?;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Container(
                            width: 26, height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: color)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(name,
                                  style: AppTextStyles.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                          if (seat != null)
                            Text('Puesto $seat',
                                style: AppTextStyles.caption
                                    .copyWith(color: color)),
                        ]),
                      );
                    },
                  ),
                );
              },
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Horas distintas con clases esta semana (filas de la pizarra)
    final hours = _sessions.map((s) => s.startsAt.hour).toSet().toList()..sort();

    return Column(children: [
      // ── Navegación de semana ────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(children: [
          IconButton(
            onPressed: () => _changeWeek(-1),
            icon: const Icon(Icons.chevron_left_rounded,
                color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(_weekLabel,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelLarge),
          ),
          IconButton(
            onPressed: () => _changeWeek(1),
            icon: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ),
        ]),
      ),
      Expanded(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : hours.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.event_busy_rounded,
                          size: 44, color: AppColors.textMuted),
                      const SizedBox(height: 10),
                      Text('Sin clases esta semana',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                    ]),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _buildGrid(hours),
                      ),
                    ),
                  ),
      ),
    ]);
  }

  Widget _buildGrid(List<int> hours) {
    const cellW = 86.0;
    const hourW = 56.0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Widget headerCell(String label, {bool highlight = false}) => Container(
          width: cellW,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlight
                ? AppColors.primary.withOpacity(0.18)
                : AppColors.surface,
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: highlight ? AppColors.primary : AppColors.textSecondary)),
        );

    return Column(children: [
      // Encabezado: días
      Row(children: [
        Container(
          width: hourW,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: const Text('HORA',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted)),
        ),
        for (int d = 0; d < 7; d++)
          headerCell(
            '${_dayNames[d + 1]} ${_weekStart.add(Duration(days: d)).day}',
            highlight: _weekStart.add(Duration(days: d)) == today,
          ),
      ]),
      // Filas por hora
      for (final hour in hours)
        IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            width: hourW,
            constraints: const BoxConstraints(minHeight: 54),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Text(_fmtHour(hour),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
          ),
          for (int d = 0; d < 7; d++)
            _buildCell(_weekStart.add(Duration(days: d)), hour, cellW),
        ])),
    ]);
  }

  Widget _buildCell(DateTime day, int hour, double width) {
    final cellSessions = _sessions.where((s) =>
        s.sessionDate.year == day.year &&
        s.sessionDate.month == day.month &&
        s.sessionDate.day == day.day &&
        s.startsAt.hour == hour).toList();

    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: cellSessions.map((s) {
          final color =
              s.activity == 'spinning' ? _spinColor : AppColors.accentBlue;
          return GestureDetector(
            onTap: () => _showSessionDetail(s),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 1.5),
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(s.isCompleted ? 0.06 : 0.14),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                    color: color.withOpacity(s.isCompleted ? 0.2 : 0.45),
                    width: 0.8),
              ),
              child: Column(children: [
                Text(s.scheduleName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: color.withOpacity(s.isCompleted ? 0.5 : 1))),
                const SizedBox(height: 1),
                Text('${s.bookedCount}/${s.capacity}',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: color.withOpacity(s.isCompleted ? 0.4 : 0.8))),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _SectionHeader({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.headingSmall.copyWith(color: color)),
      ]),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final ClassSchedule schedule;
  final String        description;
  final VoidCallback  onEdit;
  final VoidCallback  onDelete;

  const _ScheduleTile({
    required this.schedule,
    required this.description,
    required this.onEdit,
    required this.onDelete,
  });

  String _timeLabel() =>
      formatTime12h(schedule.timeOfDay.hour, schedule.timeOfDay.minute);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(schedule.name,
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
        subtitle: Text(
          '$description · ${_timeLabel()} · ${schedule.durationMinutes} min · ${schedule.capacity} cupos',
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                color: AppColors.accentOrange, size: 20),
            onPressed: onEdit,
            tooltip: 'Editar',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: Colors.red.shade400, size: 20),
            onPressed: onDelete,
            tooltip: 'Eliminar',
          ),
        ]),
      ),
    );
  }
}

// ── Formulario de horario (bottom sheet) ─────────────────────────

class _ScheduleFormSheet extends StatefulWidget {
  final ClassSchedule? editing;
  final void Function(ClassSchedule) onSave;

  const _ScheduleFormSheet({this.editing, required this.onSave});

  @override
  State<_ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<_ScheduleFormSheet> {
  final _nameCtrl     = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _domCtrl      = TextEditingController();

  String       _activity     = 'spinning';
  String       _scheduleType = 'weekly';
  Set<int>     _daysOfWeek   = {};
  TimeOfDay    _time         = const TimeOfDay(hour: 7, minute: 0);

  static const _dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _nameCtrl.text     = e.name;
      _capacityCtrl.text = e.capacity.toString();
      _durationCtrl.text = e.durationMinutes.toString();
      _activity          = e.activity;
      _scheduleType      = e.scheduleType;
      _daysOfWeek        = e.daysOfWeek.toSet();
      _time              = e.timeOfDay;
      if (e.dayOfMonth != null) _domCtrl.text = e.dayOfMonth.toString();
    } else {
      _capacityCtrl.text = '18';
      _durationCtrl.text = '60';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _capacityCtrl.dispose();
    _durationCtrl.dispose();
    _domCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => MediaQuery(
        // Forzar formato de 12 horas (AM/PM) en el selector
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (t != null) setState(() => _time = t);
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final schedule = ClassSchedule(
      id:              widget.editing?.id ?? '',
      activity:        _activity,
      name:            name,
      scheduleType:    _scheduleType,
      daysOfWeek:      _daysOfWeek.toList()..sort(),
      dayOfMonth:      _scheduleType == 'monthly'
                         ? int.tryParse(_domCtrl.text)
                         : null,
      timeOfDay:       _time,
      durationMinutes: int.tryParse(_durationCtrl.text) ?? 60,
      capacity:        int.tryParse(_capacityCtrl.text) ?? 18,
      active:          true,
    );
    widget.onSave(schedule);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editing != null;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(isEditing ? 'Editar horario' : 'Nuevo horario',
              style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textPrimary)),
          const SizedBox(height: 20),

          // Actividad
          Text('Actividad', style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(children: [
            _ActivityChip(
              label: 'Spinning',
              icon: Icons.directions_bike_rounded,
              selected: _activity == 'spinning',
              onTap: () => setState(() => _activity = 'spinning'),
            ),
            const SizedBox(width: 8),
            _ActivityChip(
              label: 'Running',
              icon: Icons.directions_run_rounded,
              selected: _activity == 'running',
              onTap: () => setState(() => _activity = 'running'),
            ),
          ]),
          const SizedBox(height: 16),

          // Nombre
          TextField(
            controller: _nameCtrl,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            decoration: _inputDecoration('Nombre de la clase'),
          ),
          const SizedBox(height: 12),

          // Tipo de horario
          Text('Tipo de horario', style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _scheduleType,
            dropdownColor: AppColors.surface,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            decoration: _inputDecoration('Tipo'),
            items: const [
              DropdownMenuItem(value: 'daily',   child: Text('Diario')),
              DropdownMenuItem(value: 'weekly',  child: Text('Semanal')),
              DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
              DropdownMenuItem(value: 'custom',  child: Text('Personalizado')),
            ],
            onChanged: (v) => setState(() => _scheduleType = v!),
          ),
          const SizedBox(height: 12),

          // Días de semana (weekly / custom)
          if (_scheduleType == 'weekly' || _scheduleType == 'custom') ...[
            Text('Días de la semana', style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                final dayNum = i + 1; // 1=Mon..7=Sun
                final selected = _daysOfWeek.contains(dayNum);
                return FilterChip(
                  label: Text(_dayNames[i]),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) _daysOfWeek.add(dayNum);
                    else   _daysOfWeek.remove(dayNum);
                  }),
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 12,
                  ),
                  backgroundColor: AppColors.background,
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
          ],

          // Día del mes (monthly)
          if (_scheduleType == 'monthly') ...[
            TextField(
              controller: _domCtrl,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: _inputDecoration('Día del mes (1–28)'),
            ),
            const SizedBox(height: 12),
          ],

          // Hora
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                const Icon(Icons.access_time_rounded,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Text(
                  formatTime12h(_time.hour, _time.minute),
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary),
                ),
                const Spacer(),
                Text('Toca para cambiar',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted)),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Duración y capacidad
          Row(children: [
            Expanded(
              child: TextField(
                controller: _durationCtrl,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: _inputDecoration('Duración (min)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _capacityCtrl,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: _inputDecoration('Capacidad'),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // Botón guardar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(isEditing ? 'Guardar cambios' : 'Crear horario',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
    filled: true,
    fillColor: AppColors.background,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

class _ActivityChip extends StatelessWidget {
  final String     label;
  final IconData   icon;
  final bool       selected;
  final VoidCallback onTap;

  const _ActivityChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16,
              color: selected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              )),
        ]),
      ),
    );
  }
}
