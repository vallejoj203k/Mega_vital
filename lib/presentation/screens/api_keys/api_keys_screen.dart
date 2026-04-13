// lib/presentation/screens/api_keys/api_keys_screen.dart
// ─────────────────────────────────────────────────────────────────
// Pantalla para gestionar las claves de IA gratuitas.
// El usuario agrega múltiples claves de Gemini y/o Groq.
// La app rota automáticamente entre ellas.
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../services/api_key_manager.dart';
import '../../widgets/shared_widgets.dart';

class ApiKeysScreen extends StatefulWidget {
  const ApiKeysScreen({super.key});
  @override
  State<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends State<ApiKeysScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    await ApiKeyManager.instance.load();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final manager = ApiKeyManager.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(children: [
        // ── Header ─────────────────────────────────────────────
        Padding(padding: const EdgeInsets.fromLTRB(20,16,20,0),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 0.5)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Claves de IA', style: AppTextStyles.displayMedium),
              Text('Más claves = más análisis gratis',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ])),
          ])),

        const SizedBox(height: 16),

        // ── Total disponible hoy ────────────────────────────────
        if (!_loading) Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _TotalCard(manager: manager),
        ),

        const SizedBox(height: 12),

        // ── Tabs ───────────────────────────────────────────────
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _ProviderTabs(controller: _tabCtrl)),

        const SizedBox(height: 8),

        // ── Contenido ──────────────────────────────────────────
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _KeysTab(
                  provider: 'gemini',
                  keys: manager.geminiKeys.toList(),
                  onAdd: (k, l) async {
                    await manager.addKey(k, l, 'gemini');
                    setState(() {});
                  },
                  onDelete: (k) async {
                    await manager.removeKey(k, 'gemini');
                    setState(() {});
                  },
                  instructions: const _GeminiInstructions(),
                ),
                _KeysTab(
                  provider: 'groq',
                  keys: manager.groqKeys.toList(),
                  onAdd: (k, l) async {
                    await manager.addKey(k, l, 'groq');
                    setState(() {});
                  },
                  onDelete: (k) async {
                    await manager.removeKey(k, 'groq');
                    setState(() {});
                  },
                  instructions: const _GroqInstructions(),
                ),
              ],
            )),
      ])),
    );
  }
}

// ── Tarjeta de total disponible hoy ──────────────────────────────
class _TotalCard extends StatelessWidget {
  final ApiKeyManager manager;
  const _TotalCard({required this.manager});

  @override
  Widget build(BuildContext context) {
    final total   = manager.totalAvailableToday;
    final gKeys   = manager.geminiKeys.length;
    final grKeys  = manager.groqKeys.length;
    final hasKeys = manager.hasAnyKey;

    return DarkCard(
      gradient: hasKeys
          ? const LinearGradient(
              colors: [Color(0xFF0F2318), Color(0xFF0A1A10)],
              begin: Alignment.topLeft, end: Alignment.bottomRight)
          : null,
      borderColor: hasKeys ? AppColors.primary.withOpacity(0.3) : null,
      child: Row(children: [
        BoxedIcon(
          icon: hasKeys ? Icons.auto_awesome_rounded : Icons.key_off_outlined,
          color: hasKeys ? AppColors.primary : AppColors.textMuted,
          size: 48,
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(hasKeys ? '$total análisis disponibles hoy' : 'Sin claves configuradas',
              style: hasKeys
                  ? AppTextStyles.headingSmall.copyWith(color: AppColors.primary)
                  : AppTextStyles.headingSmall),
          const SizedBox(height: 4),
          if (hasKeys)
            Text('$gKeys clave(s) Gemini  ·  $grKeys clave(s) Groq',
                style: AppTextStyles.caption)
          else
            Text('Agrega claves para activar el análisis con foto',
                style: AppTextStyles.bodyMedium),
        ])),
      ]),
    );
  }
}

// ── Tab de claves por proveedor ───────────────────────────────────
class _KeysTab extends StatelessWidget {
  final String           provider;
  final List<ApiKey>     keys;
  final Widget           instructions;
  final Future<void> Function(String key, String label) onAdd;
  final Future<void> Function(String key)               onDelete;

  const _KeysTab({required this.provider, required this.keys,
      required this.instructions, required this.onAdd, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      physics: const BouncingScrollPhysics(),
      children: [
        // Instrucciones
        instructions,
        const SizedBox(height: 16),

        // Lista de claves existentes
        if (keys.isNotEmpty) ...[
          Text('Tus claves (${keys.length})',
              style: AppTextStyles.headingSmall),
          const SizedBox(height: 10),
          ...keys.map((k) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _KeyCard(
              apiKey:   k,
              onDelete: () => onDelete(k.key),
            ),
          )),
          const SizedBox(height: 8),
        ],

        // Botón agregar clave
        _AddKeyButton(provider: provider, onAdd: onAdd),
      ],
    );
  }
}

// ── Tarjeta de una clave ──────────────────────────────────────────
class _KeyCard extends StatelessWidget {
  final ApiKey     apiKey;
  final VoidCallback onDelete;
  const _KeyCard({required this.apiKey, required this.onDelete});

  Color get _statusColor {
    if (!apiKey.isFresh) return AppColors.error;
    if (apiKey.usagePercent > 0.8) return AppColors.warning;
    return AppColors.primary;
  }

  String get _statusLabel {
    if (!apiKey.isFresh) return 'Límite alcanzado';
    if (apiKey.usagePercent > 0.8) return 'Casi agotada';
    return 'Disponible';
  }

  @override
  Widget build(BuildContext context) {
    // Enmascarar la clave: mostrar solo los últimos 8 chars
    final masked = apiKey.key.length > 8
        ? '••••••••${apiKey.key.substring(apiKey.key.length - 8)}'
        : '••••••••';

    return DarkCard(
      borderColor: _statusColor.withOpacity(0.3),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(apiKey.label, style: AppTextStyles.labelLarge),
            const SizedBox(height: 2),
            Text(masked, style: AppTextStyles.caption
                .copyWith(color: AppColors.textMuted,
                    fontFamily: 'monospace')),
          ])),
          // Badge de estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
            child: Text(_statusLabel, style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: _statusColor)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => showDialog(context: context, builder: (_) =>
              AlertDialog(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Text('¿Eliminar clave?',
                    style: AppTextStyles.headingSmall),
                content: Text('Se eliminará "${apiKey.label}".',
                    style: AppTextStyles.bodyMedium),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar',
                          style: TextStyle(color: AppColors.textSecondary))),
                  TextButton(onPressed: () { Navigator.pop(context); onDelete(); },
                      child: Text('Eliminar',
                          style: TextStyle(color: AppColors.error))),
                ],
              )),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textMuted, size: 18),
          ),
        ]),
        const SizedBox(height: 10),
        // Barra de uso
        Row(children: [
          Expanded(child: NeonProgressBar(
            progress: apiKey.usagePercent,
            gradient: LinearGradient(
                colors: [_statusColor, _statusColor.withOpacity(0.6)]),
            height: 5, showGlow: false,
          )),
          const SizedBox(width: 10),
          Text(apiKey.usageDisplay, style: AppTextStyles.caption),
        ]),
      ]),
    );
  }
}

// ── Botón agregar clave ───────────────────────────────────────────
class _AddKeyButton extends StatelessWidget {
  final String provider;
  final Future<void> Function(String, String) onAdd;
  const _AddKeyButton({required this.provider, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddDialog(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1,
              style: BorderStyle.solid)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add_circle_outline_rounded,
              color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text('Agregar clave de ${provider == 'gemini' ? 'Gemini' : 'Groq'}',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
        ]),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final keyCtrl   = TextEditingController();
    final labelCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Nueva clave ${provider == 'gemini' ? 'Gemini' : 'Groq'}',
            style: AppTextStyles.headingSmall),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: labelCtrl,
            style: AppTextStyles.bodyLarge,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              labelText: 'Nombre (opcional)',
              hintText: 'Ej: Cuenta principal',
              labelStyle: AppTextStyles.caption,
              filled: true, fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: keyCtrl,
            autofocus: true,
            style: AppTextStyles.bodyLarge.copyWith(fontFamily: 'monospace'),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              labelText: 'Clave de API *',
              hintText: provider == 'gemini' ? 'AIzaSy...' : 'gsk_...',
              labelStyle: AppTextStyles.caption,
              filled: true, fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              // Botón pegar
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_rounded,
                    size: 18, color: AppColors.textMuted),
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) keyCtrl.text = data!.text!.trim();
                },
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              final k = keyCtrl.text.trim();
              if (k.isEmpty) return;
              await onAdd(k, labelCtrl.text.trim());
              if (context.mounted) Navigator.pop(context);
              HapticFeedback.mediumImpact();
            },
            child: Text('Agregar',
                style: TextStyle(color: AppColors.primary,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Tabs de proveedores ───────────────────────────────────────────
class _ProviderTabs extends StatelessWidget {
  final TabController controller;
  const _ProviderTabs({required this.controller});

  @override
  Widget build(BuildContext context) => Container(
    height: 42,
    decoration: BoxDecoration(color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5)),
    child: TabBar(controller: controller,
      indicator: BoxDecoration(gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(10)),
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: const EdgeInsets.all(4),
      labelColor: AppColors.background,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 13),
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(text: 'Gemini  (Google)'),
        Tab(text: 'Groq'),
      ],
    ),
  );
}

// ── Instrucciones por proveedor ───────────────────────────────────
class _GeminiInstructions extends StatelessWidget {
  const _GeminiInstructions();
  @override
  Widget build(BuildContext context) => _InstructionCard(
    icon: Icons.auto_awesome_rounded,
    color: AppColors.primary,
    title: 'Google Gemini Flash',
    subtitle: '1,500 análisis GRATIS por clave/día',
    steps: const [
      'Ve a aistudio.google.com/apikey',
      'Inicia sesión con tu cuenta Google',
      'Toca "Create API Key" → copia la clave',
      'Con 3 cuentas Google = 4,500/día gratis',
    ],
    tip: 'Puedes crear múltiples cuentas de Gmail para obtener más claves.',
  );
}

class _GroqInstructions extends StatelessWidget {
  const _GroqInstructions();
  @override
  Widget build(BuildContext context) => _InstructionCard(
    icon: Icons.bolt_rounded,
    color: AppColors.accentBlue,
    title: 'Groq — LLaVA Vision',
    subtitle: 'Sin límite diario estricto · Sin tarjeta',
    steps: const [
      'Ve a console.groq.com',
      'Crea una cuenta gratuita',
      'Ve a "API Keys" → "Create API Key"',
      'Copia la clave (empieza con gsk_...)',
    ],
    tip: 'Groq usa hardware especializado. Es más rápido que Gemini en muchos casos.',
  );
}

class _InstructionCard extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title, subtitle;
  final List<String> steps;
  final String   tip;
  const _InstructionCard({required this.icon, required this.color,
      required this.title, required this.subtitle,
      required this.steps, required this.tip});

  @override
  Widget build(BuildContext context) => DarkCard(
    borderColor: color.withOpacity(0.25),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        BoxedIcon(icon: icon, color: color, size: 40),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(title, style: AppTextStyles.headingSmall),
          Text(subtitle, style: AppTextStyles.caption
              .copyWith(color: color)),
        ])),
      ]),
      const SizedBox(height: 14),
      ...steps.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 22, height: 22,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Center(child: Text('${e.key + 1}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: color)))),
          const SizedBox(width: 10),
          Expanded(child: Text(e.value, style: AppTextStyles.bodyMedium)),
        ]),
      )),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.lightbulb_outline_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(tip, style: AppTextStyles.bodySmall
              .copyWith(color: color.withOpacity(0.9)))),
        ]),
      ),
    ]),
  );
}
