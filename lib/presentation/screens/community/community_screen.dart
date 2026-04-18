// lib/presentation/screens/community/community_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/community_provider.dart';
import '../../../core/providers/stories_provider.dart';
import '../../../services/community_service.dart';
import '../../widgets/shared_widgets.dart';
import 'stories_row.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().init();
      context.read<StoriesProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _currentUserName(BuildContext ctx) {
    final profile = ctx.watch<AuthProvider>().profile;
    return profile?.name ?? 'Usuario';
  }

  String _currentUserId(BuildContext ctx) {
    final auth = ctx.watch<AuthProvider>();
    return auth.firebaseUser?.uid ?? auth.profile?.uid ?? '';
  }

  String _currentUserInitials(BuildContext ctx) =>
      ctx.watch<AuthProvider>().userInitials;

  void _openPublishDialog(String userName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PublishSheet(userName: userName),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userName     = _currentUserName(context);
    final userId       = _currentUserId(context);
    final userInitials = _currentUserInitials(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Comunidad', style: AppTextStyles.displayMedium),
                  NeonButton(
                    label: 'Publicar',
                    icon: Icons.add,
                    onTap: () => _openPublishDialog(userName),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _CustomTabBar(controller: _tabController),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _FeedTab(
                currentUserName:     userName,
                currentUserId:       userId,
                currentUserInitials: userInitials,
              ),
                  const _LeaderboardTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab bar ─────────────────────────────────────────────────────────────────

class _CustomTabBar extends StatelessWidget {
  final TabController controller;
  const _CustomTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: AppColors.background,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        dividerColor: Colors.transparent,
        tabs: const [Tab(text: 'Feed'), Tab(text: 'Clasificación')],
      ),
    );
  }
}

// ─── Feed tab ─────────────────────────────────────────────────────────────────

class _FeedTab extends StatelessWidget {
  final String currentUserName;
  final String currentUserId;
  final String currentUserInitials;

  const _FeedTab({
    required this.currentUserName,
    required this.currentUserId,
    required this.currentUserInitials,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Fila de historias ──
        Consumer<StoriesProvider>(
          builder: (ctx, sp, _) => StoriesRow(
            groups:              sp.groups,
            isLoading:           sp.isLoading,
            currentUserId:       currentUserId,
            currentUserName:     currentUserName,
            currentUserInitials: currentUserInitials,
          ),
        ),
        const Divider(height: 1, thickness: 0.5, color: AppColors.divider),
        const SizedBox(height: 4),
        // ── Posts ──
        Expanded(
          child: Consumer<CommunityProvider>(
            builder: (context, provider, _) {
              if (provider.loadingPosts && provider.posts.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (provider.posts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 56, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text('Aún no hay publicaciones',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 6),
                      Text('¡Sé el primero en compartir algo!',
                          style: AppTextStyles.caption),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: () async {
                  await provider.loadPosts();
                  await context.read<StoriesProvider>().load();
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: provider.posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _PostCard(
                    post: provider.posts[i],
                    currentUserName: currentUserName,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Post card ────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final String currentUserName;
  const _PostCard({required this.post, required this.currentUserName});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        post: post,
        currentUserName: currentUserName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CommunityProvider>();
    final isOwn = post.userName == currentUserName;

    return DarkCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              InitialsAvatar(
                initials: post.userInitials,
                size: 40,
                bgColor: AppColors.surfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.userName, style: AppTextStyles.labelLarge),
                    Text(_timeAgo(post.createdAt),
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (isOwn)
                GestureDetector(
                  onTap: () => _confirmDelete(context, provider),
                  child: Icon(Icons.more_horiz_rounded,
                      color: AppColors.textMuted, size: 20),
                )
              else
                Icon(Icons.more_horiz_rounded,
                    color: AppColors.textMuted, size: 20),
            ],
          ),

          // Achievement badge
          if (post.achievement != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                post.achievement!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.background,
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),
          Text(post.content, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 14),
          Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 10),

          // Actions
          Row(
            children: [
              _ActionButton(
                icon: post.likedByMe
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: '${post.likesCount}',
                color:
                    post.likedByMe ? AppColors.error : AppColors.textMuted,
                onTap: () => provider.toggleLike(post.id),
              ),
              const SizedBox(width: 20),
              _ActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${post.commentsCount}',
                color: AppColors.textMuted,
                onTap: () => _showComments(context),
              ),
              const Spacer(),
              _ActionButton(
                icon: Icons.share_outlined,
                label: 'Compartir',
                color: AppColors.textMuted,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, CommunityProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Eliminar publicación',
            style: AppTextStyles.labelLarge),
        content: Text('¿Seguro que quieres eliminar este post?',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text('Eliminar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deletePost(post.id);
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color)),
        ],
      ),
    );
  }
}

// ─── Publish sheet ────────────────────────────────────────────────────────────

class _PublishSheet extends StatefulWidget {
  final String userName;
  const _PublishSheet({required this.userName});

  @override
  State<_PublishSheet> createState() => _PublishSheetState();
}

class _PublishSheetState extends State<_PublishSheet> {
  final _controller = TextEditingController();
  final _achievementController = TextEditingController();
  bool _loading = false;
  bool _showAchievement = false;

  @override
  void dispose() {
    _controller.dispose();
    _achievementController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    final achievement = _showAchievement && _achievementController.text.trim().isNotEmpty
        ? _achievementController.text.trim()
        : null;
    final error = await context
        .read<CommunityProvider>()
        .createPost(widget.userName, text, achievement: achievement);
    if (mounted) {
      if (error == null) {
        Navigator.pop(context);
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _friendlyError(error),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('relation') && lower.contains('does not exist')) {
      return 'Las tablas de comunidad no existen aún. Ejecuta el SQL en Supabase primero.';
    }
    if (lower.contains('violates foreign key')) {
      return 'Error de perfil: completa tu perfil antes de publicar.';
    }
    if (lower.contains('row-level security') || lower.contains('rls')) {
      return 'Sin permiso para publicar. Verifica que estés autenticado.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Sin conexión. Verifica tu internet.';
    }
    if (lower.contains('no hay sesión')) {
      return 'Inicia sesión para publicar.';
    }
    return 'Error al publicar: $raw';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text('Nueva publicación', style: AppTextStyles.headingSmall),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: 500,
            autofocus: true,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: '¿Qué quieres compartir con la comunidad?',
              hintStyle:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1),
              ),
              counterStyle:
                  AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _showAchievement = !_showAchievement),
            child: Row(
              children: [
                Icon(
                  _showAchievement
                      ? Icons.emoji_events_rounded
                      : Icons.emoji_events_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Añadir logro',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          if (_showAchievement) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _achievementController,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Ej: Récord Personal, Racha de 30 días…',
                hintStyle: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                disabledBackgroundColor:
                    AppColors.primary.withOpacity(0.4),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.background),
                    )
                  : Text('Publicar',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.background)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Comments sheet ───────────────────────────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  final CommunityPost post;
  final String currentUserName;
  const _CommentsSheet({required this.post, required this.currentUserName});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  late Future<List<CommunityComment>> _commentsFuture;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  void _loadComments() {
    _commentsFuture = context
        .read<CommunityProvider>()
        .fetchComments(widget.post.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final ok = await context.read<CommunityProvider>().addComment(
          widget.post.id,
          widget.currentUserName,
          text,
        );
    if (mounted) {
      if (ok) {
        _controller.clear();
        setState(() {
          _sending = false;
          _loadComments();
        });
      } else {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al enviar comentario.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle + title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Column(
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Comentarios', style: AppTextStyles.headingSmall),
                    const Spacer(),
                    Text(
                      '${widget.post.commentsCount}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: AppColors.divider, height: 1),

          // Post preview
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InitialsAvatar(
                    initials: widget.post.userInitials,
                    size: 32,
                    bgColor: AppColors.surfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.post.userName,
                          style: AppTextStyles.labelMedium),
                      const SizedBox(height: 2),
                      Text(widget.post.content,
                          style: AppTextStyles.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.divider, height: 1),

          // Comments list
          Expanded(
            child: FutureBuilder<List<CommunityComment>>(
              future: _commentsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                final comments = snap.data ?? [];
                if (comments.isEmpty) {
                  return Center(
                    child: Text('Sé el primero en comentar',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final c = comments[i];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InitialsAvatar(
                            initials: c.userInitials,
                            size: 30,
                            bgColor: AppColors.surfaceVariant),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(c.userName,
                                      style: AppTextStyles.labelMedium),
                                  const SizedBox(width: 6),
                                  Text(_timeAgo(c.createdAt),
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textMuted)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(c.content,
                                  style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: AppTextStyles.bodyMedium,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Añadir un comentario…',
                      hintStyle: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            BorderSide(color: AppColors.border, width: 0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            BorderSide(color: AppColors.border, width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const Center(
                            child: SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.background),
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            color: AppColors.background, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Leaderboard tab ──────────────────────────────────────────────────────────

enum _LeaderMode { weekly, total }

class _LeaderboardTab extends StatefulWidget {
  const _LeaderboardTab();

  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<_LeaderboardTab> {
  _LeaderMode _mode = _LeaderMode.weekly;

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityProvider>(
      builder: (context, provider, _) {
        final leaders = _mode == _LeaderMode.weekly
            ? provider.leaderboardWeekly
            : provider.leaderboardTotal;
        final isLoading =
            provider.loadingLeaderboard && leaders.isEmpty;

        return Column(
          children: [
            // Toggle Semanal / Histórico
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ModeToggle(
                mode: _mode,
                onChanged: (m) => setState(() => _mode = m),
              ),
            ),
            const SizedBox(height: 4),

            // Descripción de puntos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _mode == _LeaderMode.weekly
                  ? Text(
                      'Puntos ganados esta semana · se reinicia cada lunes',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    )
                  : Text(
                      'Puntos acumulados desde el inicio',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    )
                  : leaders.isEmpty
                      ? _LeaderboardEmpty(mode: _mode)
                      : _LeaderboardList(
                          leaders: leaders,
                          onRefresh: () => provider.loadLeaderboard(),
                        ),
            ),
          ],
        );
      },
    );
  }
}

// Toggle Semanal / Histórico
class _ModeToggle extends StatelessWidget {
  final _LeaderMode mode;
  final ValueChanged<_LeaderMode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _ToggleBtn(
            label: 'Esta semana',
            icon: Icons.calendar_today_rounded,
            selected: mode == _LeaderMode.weekly,
            onTap: () => onChanged(_LeaderMode.weekly),
          ),
          _ToggleBtn(
            label: 'Histórico',
            icon: Icons.emoji_events_rounded,
            selected: mode == _LeaderMode.total,
            onTap: () => onChanged(_LeaderMode.total),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 13,
                  color: selected
                      ? AppColors.background
                      : AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: selected
                      ? AppColors.background
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardEmpty extends StatelessWidget {
  final _LeaderMode mode;
  const _LeaderboardEmpty({required this.mode});

  @override
  Widget build(BuildContext context) {
    final isWeekly = mode == _LeaderMode.weekly;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isWeekly
                  ? Icons.calendar_today_rounded
                  : Icons.emoji_events_rounded,
              size: 52,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 14),
            Text(
              isWeekly
                  ? 'Nadie ha ganado puntos esta semana todavía'
                  : 'Aún no hay puntos acumulados',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isWeekly
                  ? '¡Entrena, publica y comenta para subir!'
                  : 'Completa entrenamientos y participa en la comunidad',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<LeaderboardEntry> leaders;
  final Future<void> Function() onRefresh;
  const _LeaderboardList({required this.leaders, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: leaders.length + 2,
        itemBuilder: (_, i) {
          if (i < leaders.length) {
            final entry = leaders[i];
            return entry.rank <= 3
                ? _TopThreeCard(entry: entry)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LeaderCard(entry: entry),
                  );
          }
          if (i == leaders.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _PointsLegend(),
            );
          }
          return const SizedBox(height: 80);
        },
      ),
    );
  }
}

// Leyenda que explica cómo se ganan puntos
class _PointsLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.fitness_center_rounded,    'Completar entrenamiento',    '+100'),
      (Icons.restaurant_menu_rounded,   'Cumplir meta calórica diaria', '+ 50'),
      (Icons.post_add_rounded,          'Publicar en el feed',         '+ 20'),
      (Icons.favorite_rounded,          'Recibir un like',             '+  3'),
      (Icons.chat_bubble_rounded,       'Dejar un comentario',         '+  5'),
    ];
    return DarkCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.info_outline_rounded,
                size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('Cómo ganar puntos',
                style:
                    AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
          ]),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Icon(item.$1, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(item.$2, style: AppTextStyles.caption)),
                Text(
                  item.$3,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopThreeCard extends StatelessWidget {
  final LeaderboardEntry entry;
  const _TopThreeCard({required this.entry});

  Color get _medalColor {
    switch (entry.rank) {
      case 1: return const Color(0xFFFFD700);
      case 2: return const Color(0xFFB8C4CF);
      case 3: return const Color(0xFFCD8B5A);
      default: return AppColors.primary;
    }
  }

  String get _medalEmoji {
    switch (entry.rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _medalColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.55), width: 1.5),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(14)),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(_medalEmoji,
                    style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: InitialsAvatar(
                  initials: entry.initials,
                  size: 48,
                  bgColor: entry.isMe ? null : color.withOpacity(0.15),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        entry.isMe ? '${entry.name} (tú)' : entry.name,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: entry.isMe
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${entry.rank} lugar',
                        style: AppTextStyles.caption
                            .copyWith(color: color.withOpacity(0.85)),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.points}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: color,
                        height: 1,
                      ),
                    ),
                    Text('pts', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderCard extends StatelessWidget {
  final LeaderboardEntry entry;
  const _LeaderCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      borderColor:
          entry.isMe ? AppColors.primary.withOpacity(0.4) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('#${entry.rank}', style: AppTextStyles.labelMedium),
          ),
          InitialsAvatar(
            initials: entry.initials,
            size: 38,
            bgColor: entry.isMe ? null : AppColors.surfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.isMe ? '${entry.name} (tú)' : entry.name,
              style: AppTextStyles.labelLarge.copyWith(
                color: entry.isMe
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${entry.points} pts',
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
