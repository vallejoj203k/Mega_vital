import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/stories_provider.dart';

const _kStoryDuration = Duration(seconds: 5);

// ─── Fila de historias ────────────────────────────────────────────────────────

class StoriesRow extends StatelessWidget {
  final List<UserStoriesGroup> groups;
  final bool isLoading;
  final String currentUserId;
  final String currentUserName;
  final String currentUserInitials;

  const StoriesRow({
    super.key,
    required this.groups,
    required this.isLoading,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserInitials,
  });

  // Stories de otros usuarios (sin el propio para evitar duplicado con "Tú")
  List<UserStoriesGroup> get _others =>
      groups.where((g) => g.userId != currentUserId).toList();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 98,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _others.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return _MyCircle(
              userId:   currentUserId,
              userName: currentUserName,
              initials: currentUserInitials,
            );
          }
          final group = _others[i - 1];
          return _UserCircle(
            group: group,
            onTap: () => _openViewer(ctx, i - 1),
          );
        },
      ),
    );
  }

  void _openViewer(BuildContext ctx, int index) {
    Navigator.of(ctx).push(PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => StoryViewerPage(
        groups: _others,
        initialGroupIndex: index,
      ),
    ));
  }
}

// ─── Círculo "Tú" ─────────────────────────────────────────────────────────────

class _MyCircle extends StatelessWidget {
  final String userId, userName, initials;
  const _MyCircle({required this.userId, required this.userName, required this.initials});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: _CircleLayout(
        label: 'Tú',
        avatar: Stack(
          children: [
            // Anillo verde
            _Ring(hasNew: true, child: _AvatarContent(initials: initials, hasNew: true)),
            // Botón "+"
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: 22, height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Icon(Icons.add, size: 14, color: AppColors.background),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddStorySheet(userId: userId, userName: userName),
    );
  }
}

// ─── Círculo de otro usuario ──────────────────────────────────────────────────

class _UserCircle extends StatelessWidget {
  final UserStoriesGroup group;
  final VoidCallback onTap;
  const _UserCircle({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _CircleLayout(
        label: group.firstName,
        labelColor: group.hasUnviewed
            ? AppColors.textPrimary
            : AppColors.textSecondary,
        avatar: _Ring(
          hasNew: group.hasUnviewed,
          child: _AvatarContent(
            initials: group.initials,
            hasNew: group.hasUnviewed,
          ),
        ),
      ),
    );
  }
}

// ─── Helpers de layout ────────────────────────────────────────────────────────

class _CircleLayout extends StatelessWidget {
  final Widget avatar;
  final String label;
  final Color? labelColor;
  const _CircleLayout({required this.avatar, required this.label, this.labelColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 14),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 68, height: 68, child: avatar),
        const SizedBox(height: 5),
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: labelColor ?? AppColors.textSecondary,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _Ring extends StatelessWidget {
  final bool hasNew;
  final Widget child;
  const _Ring({required this.hasNew, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: 68, height: 68,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: hasNew ? AppColors.primaryGradient : null,
      color: hasNew ? null : AppColors.textMuted.withOpacity(0.35),
    ),
    alignment: Alignment.center,
    child: Container(
      width: 60, height: 60,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background,
      ),
      alignment: Alignment.center,
      child: child,
    ),
  );
}

class _AvatarContent extends StatelessWidget {
  final String initials;
  final bool hasNew;
  const _AvatarContent({required this.initials, required this.hasNew});

  @override
  Widget build(BuildContext context) => Container(
    width: 56, height: 56,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: hasNew
          ? AppColors.primary.withOpacity(0.12)
          : AppColors.surfaceVariant,
    ),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: AppTextStyles.headingMedium.copyWith(
        color: hasNew ? AppColors.primary : AppColors.textSecondary,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

// ─── Visor de historias ───────────────────────────────────────────────────────

class StoryViewerPage extends StatefulWidget {
  final List<UserStoriesGroup> groups;
  final int initialGroupIndex;

  const StoryViewerPage({
    super.key,
    required this.groups,
    required this.initialGroupIndex,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with SingleTickerProviderStateMixin {
  late int _gIdx;
  int _sIdx = 0;
  Timer? _timer;
  late AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _gIdx = widget.initialGroupIndex;
    _progress = AnimationController(vsync: this, duration: _kStoryDuration);
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progress.dispose();
    super.dispose();
  }

  UserStoriesGroup get _group => widget.groups[_gIdx];
  StoryModel       get _story => _group.stories[_sIdx];

  void _start() {
    _timer?.cancel();
    _progress.reset();
    _progress.forward();
    context.read<StoriesProvider>().markViewed(_story.id);
    _timer = Timer(_kStoryDuration, _next);
  }

  void _next() {
    if (_sIdx < _group.stories.length - 1) {
      setState(() => _sIdx++);
    } else if (_gIdx < widget.groups.length - 1) {
      setState(() { _gIdx++; _sIdx = 0; });
    } else {
      Navigator.of(context).pop();
      return;
    }
    _start();
  }

  void _prev() {
    if (_sIdx > 0) {
      setState(() => _sIdx--);
    } else if (_gIdx > 0) {
      setState(() {
        _gIdx--;
        _sIdx = widget.groups[_gIdx].stories.length - 1;
      });
    }
    _start();
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1)  return 'Ahora';
    if (d.inMinutes < 60) return 'Hace ${d.inMinutes} min';
    if (d.inHours < 24)   return 'Hace ${d.inHours}h';
    return 'Ayer';
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    final story = _story;
    final total = group.stories.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) {
          final w = MediaQuery.of(context).size.width;
          if (d.globalPosition.dx < w / 2) _prev() else _next();
        },
        child: Stack(children: [

          // ── Contenido de la historia ──
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88, height: 88,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      group.initials,
                      style: AppTextStyles.displayLarge
                          .copyWith(color: AppColors.background),
                    ),
                  ),
                  const SizedBox(height: 36),
                  if (story.content != null)
                    Text(
                      story.content!,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),

          // ── Barra superior: progreso + info de usuario ──
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barras de progreso
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Row(
                    children: List.generate(total, (i) {
                      Widget bar;
                      if (i < _sIdx) {
                        bar = const ColoredBox(color: Colors.white,
                            child: SizedBox.expand());
                      } else if (i == _sIdx) {
                        bar = AnimatedBuilder(
                          animation: _progress,
                          builder: (_, __) => LinearProgressIndicator(
                            value: _progress.value,
                            backgroundColor: Colors.white30,
                            color: Colors.white,
                            minHeight: 2.5,
                          ),
                        );
                      } else {
                        bar = const ColoredBox(color: Colors.white30,
                            child: SizedBox.expand());
                      }
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: SizedBox(height: 2.5, child: bar),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Info de usuario
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      alignment: Alignment.center,
                      child: Text(group.initials,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.background,
                            fontWeight: FontWeight.w800,
                          )),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.userName,
                            style: AppTextStyles.labelLarge
                                .copyWith(color: Colors.white)),
                        Text(_timeAgo(story.createdAt),
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white60)),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ]),
                ),
              ],
            ),
          ),

        ]),
      ),
    );
  }
}

// ─── Sheet para crear historia ────────────────────────────────────────────────

class AddStorySheet extends StatefulWidget {
  final String userId, userName;
  const AddStorySheet({super.key, required this.userId, required this.userName});

  @override
  State<AddStorySheet> createState() => _AddStorySheetState();
}

class _AddStorySheetState extends State<AddStorySheet> {
  final _ctrl     = TextEditingController();
  bool  _posting  = false;
  static const _max = 200;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _publish() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    final ok = await context.read<StoriesProvider>().addStory(
      userId: widget.userId, userName: widget.userName, content: text,
    );
    if (!mounted) return;
    setState(() => _posting = false);
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Historia publicada'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom   = MediaQuery.of(context).viewInsets.bottom;
    final canPost  = _ctrl.text.trim().isNotEmpty && !_posting;

    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.border, borderRadius: BorderRadius.circular(2),
            ),
          )),
          Text('Nueva historia', style: AppTextStyles.headingMedium),
          const SizedBox(height: 4),
          Text('Visible durante 24 horas',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            maxLines: 5,
            maxLength: _max,
            autofocus: true,
            style: AppTextStyles.bodyLarge,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '¿Qué quieres compartir hoy?',
              hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
              counterStyle: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: _posting
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : GestureDetector(
                    onTap: canPost ? _publish : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: canPost ? AppColors.primaryGradient : null,
                        color: canPost ? null : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 16,
                              color: canPost
                                  ? AppColors.background
                                  : AppColors.textMuted),
                          const SizedBox(width: 8),
                          Text('Publicar historia',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: canPost
                                    ? AppColors.background
                                    : AppColors.textMuted,
                              )),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
