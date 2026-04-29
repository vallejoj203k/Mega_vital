import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final String? currentUserAvatarUrl;

  const StoriesRow({
    super.key,
    required this.groups,
    required this.isLoading,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserInitials,
    this.currentUserAvatarUrl,
  });

  UserStoriesGroup? get _myGroup =>
      groups.cast<UserStoriesGroup?>().firstWhere(
        (g) => g!.userId == currentUserId,
        orElse: () => null,
      );

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
              userId:    currentUserId,
              userName:  currentUserName,
              initials:  currentUserInitials,
              avatarUrl: currentUserAvatarUrl,
              myGroup:   _myGroup,
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
  final String? avatarUrl;
  final UserStoriesGroup? myGroup;
  const _MyCircle({
    required this.userId,
    required this.userName,
    required this.initials,
    this.avatarUrl,
    this.myGroup,
  });

  bool get _hasStories => myGroup != null && myGroup!.stories.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _hasStories ? _openViewer(context) : _openSheet(context),
      child: _CircleLayout(
        label: 'Tú',
        avatar: Stack(children: [
          _Ring(
            hasNew: _hasStories,
            child: _AvatarContent(
              initials: initials,
              hasNew: _hasStories,
              avatarUrl: avatarUrl,
            ),
          ),
          Positioned(
            right: 0, bottom: 0,
            child: GestureDetector(
              onTap: () => _openSheet(context),
              child: Container(
                width: 22, height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Icon(Icons.add, size: 14, color: AppColors.background),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _openViewer(BuildContext ctx) {
    Navigator.of(ctx).push(PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => StoryViewerPage(
        groups: [myGroup!],
        initialGroupIndex: 0,
        isOwner: true,
        onAddStory: () => _openSheet(ctx),
      ),
    ));
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
            avatarUrl: group.avatarUrl,
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
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.background),
      alignment: Alignment.center,
      child: child,
    ),
  );
}

class _AvatarContent extends StatelessWidget {
  final String initials;
  final bool hasNew;
  final String? avatarUrl;
  const _AvatarContent({required this.initials, required this.hasNew, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = avatarUrl != null && avatarUrl!.isNotEmpty;
    return Container(
      width: 56, height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasNew
            ? AppColors.primary.withOpacity(0.12)
            : AppColors.surfaceVariant,
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? Image.network(
              avatarUrl!,
              width: 56, height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialsWidget(),
            )
          : _initialsWidget(),
    );
  }

  Widget _initialsWidget() => Text(
    initials,
    style: AppTextStyles.headingMedium.copyWith(
      color: hasNew ? AppColors.primary : AppColors.textSecondary,
      fontWeight: FontWeight.w800,
    ),
  );
}

// ─── Visor de historias ───────────────────────────────────────────────────────

class StoryViewerPage extends StatefulWidget {
  final List<UserStoriesGroup> groups;
  final int initialGroupIndex;
  final bool isOwner;
  final VoidCallback? onAddStory;
  const StoryViewerPage({
    super.key,
    required this.groups,
    required this.initialGroupIndex,
    this.isOwner = false,
    this.onAddStory,
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
  bool _paused = false;
  bool _deleting = false;
  late List<UserStoriesGroup> _groups;

  @override
  void initState() {
    super.initState();
    _groups = List.from(widget.groups);
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

  UserStoriesGroup get _group => _groups[_gIdx];
  StoryModel       get _story => _group.stories[_sIdx];

  void _start() {
    _timer?.cancel();
    _progress.reset();
    _progress.forward();
    context.read<StoriesProvider>().markViewed(_story.id);
    _timer = Timer(_kStoryDuration, _next);
  }

  void _pause() {
    _timer?.cancel();
    _progress.stop();
    if (mounted) setState(() => _paused = true);
  }

  void _resume() {
    if (!mounted) return;
    setState(() => _paused = false);
    final remaining = _kStoryDuration * (1 - _progress.value);
    _progress.forward();
    _timer = Timer(remaining, _next);
  }

  void _next() {
    if (_sIdx < _group.stories.length - 1) {
      setState(() => _sIdx++);
    } else if (_gIdx < _groups.length - 1) {
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
      setState(() { _gIdx--; _sIdx = _groups[_gIdx].stories.length - 1; });
    }
    _start();
  }

  Future<void> _deleteCurrentStory() async {
    _pause();
    final storyId = _story.id;
    setState(() => _deleting = true);
    final ok = await context.read<StoriesProvider>().deleteStory(storyId);
    if (!mounted) return;
    setState(() => _deleting = false);

    if (!ok) {
      _resume();
      return;
    }

    final currentGroup = _group;
    final updatedStories = currentGroup.stories.where((s) => s.id != storyId).toList();

    if (updatedStories.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final updatedGroup = UserStoriesGroup(
      userId:    currentGroup.userId,
      userName:  currentGroup.userName,
      avatarUrl: currentGroup.avatarUrl,
      stories:   updatedStories,
    );

    setState(() {
      _groups[_gIdx] = updatedGroup;
      if (_sIdx >= updatedStories.length) _sIdx = updatedStories.length - 1;
    });
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
        onTapUp: (d) {
          if (_deleting) return;
          final w = MediaQuery.of(context).size.width;
          if (d.globalPosition.dx < w / 2) { _prev(); } else { _next(); }
        },
        onLongPressStart: (_) => _pause(),
        onLongPressEnd:   (_) => _resume(),
        child: Stack(fit: StackFit.expand, children: [

          // ── Fondo e imagen ────────────────────────────────────────
          if (story.hasImage)
            Positioned.fill(
              child: Image.network(
                story.imageUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2),
                      ),
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppColors.textMuted, size: 48),
                ),
              ),
            ),

          // Gradiente inferior para que el texto sea legible sobre la foto
          if (story.hasImage && story.content != null && story.content!.isNotEmpty)
            Positioned(
              left: 0, right: 0, bottom: 0,
              height: 180,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),

          // ── Texto centrado (sin foto) o sobre la foto ─────────────
          if (!story.hasImage)
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
                      child: Text(group.initials,
                          style: AppTextStyles.displayLarge
                              .copyWith(color: AppColors.background)),
                    ),
                    const SizedBox(height: 36),
                    if (story.content != null && story.content!.isNotEmpty)
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

          // Texto sobre la foto (posición inferior)
          if (story.hasImage && story.content != null && story.content!.isNotEmpty)
            Positioned(
              left: 20, right: 20, bottom: 40,
              child: Text(
                story.content!,
                style: AppTextStyles.headingMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  shadows: [
                    const Shadow(blurRadius: 8, color: Colors.black87),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // ── Barra superior: progreso + info ───────────────────────
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
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(group.userName,
                          style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
                      Text(_timeAgo(story.createdAt),
                          style: AppTextStyles.caption.copyWith(color: Colors.white60)),
                    ]),
                    const Spacer(),
                    if (widget.isOwner) ...[
                      GestureDetector(
                        onTap: widget.onAddStory != null
                            ? () {
                                Navigator.of(context).pop();
                                widget.onAddStory!();
                              }
                            : null,
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _deleting ? null : _deleteCurrentStory,
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: _deleting
                              ? const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.delete_outline_rounded,
                                  color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ]),
                ),
              ],
            ),
          ),

          if (_deleting)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: Colors.white),
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
  final _ctrl    = TextEditingController();
  final _picker  = ImagePicker();
  XFile? _image;
  bool   _posting = false;
  static const _maxChars = 200;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 72,    // compresión razonable
      maxWidth:     1080,
    );
    if (file != null) setState(() => _image = file);
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
            ),
            title: Text('Cámara', style: AppTextStyles.bodyLarge),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
          ),
          ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.photo_library_rounded, color: AppColors.accentBlue),
            ),
            title: Text('Galería', style: AppTextStyles.bodyLarge),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _publish() async {
    final text  = _ctrl.text.trim();
    final hasContent = text.isNotEmpty || _image != null;
    if (!hasContent) return;

    setState(() => _posting = true);

    final ok = await context.read<StoriesProvider>().addStory(
      userId:    widget.userId,
      userName:  widget.userName,
      content:   text.isEmpty ? null : text,
      imageFile: _image != null ? File(_image!.path) : null,
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

  bool get _canPost => (_ctrl.text.trim().isNotEmpty || _image != null) && !_posting;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

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
            decoration: BoxDecoration(color: AppColors.border,
                borderRadius: BorderRadius.circular(2)),
          )),

          Row(children: [
            Text('Nueva historia', style: AppTextStyles.headingMedium),
            const Spacer(),
            Text('24 h', style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
            )),
          ]),
          const SizedBox(height: 16),

          // ── Selector de foto ──
          GestureDetector(
            onTap: _showSourcePicker,
            child: _image == null
                ? Container(
                    width: double.infinity, height: 130,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border,
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_a_photo_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(height: 10),
                      Text('Añadir foto',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                          )),
                      const SizedBox(height: 2),
                      Text('Cámara o galería',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          )),
                    ]),
                  )
                : Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_image!.path),
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _image = null),
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8, right: 8,
                      child: GestureDetector(
                        onTap: _showSourcePicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text('Cambiar', style: AppTextStyles.caption
                                .copyWith(color: Colors.white)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
          ),
          const SizedBox(height: 12),

          // ── Texto (opcional) ──
          TextField(
            controller: _ctrl,
            maxLines: 3,
            maxLength: _maxChars,
            style: AppTextStyles.bodyLarge,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: _image != null
                  ? 'Añadir texto (opcional)…'
                  : '¿Qué quieres compartir?',
              hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
              counterStyle: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 12),

          // ── Botón publicar ──
          SizedBox(
            width: double.infinity, height: 50,
            child: _posting
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : GestureDetector(
                    onTap: _canPost ? _publish : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: _canPost ? AppColors.primaryGradient : null,
                        color: _canPost ? null : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.auto_awesome_rounded, size: 16,
                            color: _canPost
                                ? AppColors.background
                                : AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text('Publicar historia',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: _canPost
                                  ? AppColors.background
                                  : AppColors.textMuted,
                            )),
                      ]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
