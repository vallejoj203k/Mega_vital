// lib/presentation/screens/community/community_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/challenges_provider.dart';
import '../../../core/providers/premium_provider.dart';
import '../../../core/providers/community_provider.dart';
import '../../../core/providers/follow_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/stories_provider.dart';
import '../../../services/challenges_service.dart';
import '../../../services/community_service.dart';
import '../../widgets/shared_widgets.dart';
import '../notifications/notifications_screen.dart';
import 'stories_row.dart';
import 'user_profile_screen.dart';
import '../premium/premium_locked_widget.dart';

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
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().init();
      context.read<StoriesProvider>().load();
      context.read<FollowProvider>().load();
      context.read<NotificationProvider>().load();
      context.read<ChallengesProvider>().init();
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

    if (!context.watch<PremiumProvider>().hasAccess) {
      return const PremiumLockedWidget(
        sectionName: 'Comunidad',
        sectionIcon: Icons.people_rounded,
      );
    }

    final userName      = _currentUserName(context);
    final userId        = _currentUserId(context);
    final userInitials  = _currentUserInitials(context);
    final userAvatarUrl = context.watch<AuthProvider>().profile?.avatarUrl;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text('Comunidad', style: AppTextStyles.displayMedium),
                  const Spacer(),
                  // Campana de notificaciones
                  Consumer<NotificationProvider>(
                    builder: (_, np, __) => GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen()),
                      ).then((_) => np.load()),
                      child: Stack(clipBehavior: Clip.none, children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border, width: 0.5),
                          ),
                          child: const Icon(Icons.notifications_outlined,
                              color: AppColors.textSecondary, size: 20),
                        ),
                        if (np.unreadCount > 0)
                          Positioned(
                            top: -4, right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                np.unreadCount > 9 ? '9+' : '${np.unreadCount}',
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                    currentUserName:      userName,
                    currentUserId:        userId,
                    currentUserInitials:  userInitials,
                    currentUserAvatarUrl: userAvatarUrl,
                  ),
                  const _LeaderboardTab(),
                  _ChallengesTab(
                    currentUserId:   userId,
                    currentUserName: userName,
                  ),
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
        tabs: const [Tab(text: 'Feed'), Tab(text: 'Clasificación'), Tab(text: 'Retos')],
      ),
    );
  }
}

// ─── Feed tab ─────────────────────────────────────────────────────────────────

class _FeedTab extends StatelessWidget {
  final String currentUserName;
  final String currentUserId;
  final String currentUserInitials;
  final String? currentUserAvatarUrl;

  const _FeedTab({
    required this.currentUserName,
    required this.currentUserId,
    required this.currentUserInitials,
    this.currentUserAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Fila de historias ──
        Consumer<StoriesProvider>(
          builder: (ctx, sp, _) => StoriesRow(
            groups:                sp.groups,
            isLoading:             sp.isLoading,
            currentUserId:         currentUserId,
            currentUserName:       currentUserName,
            currentUserInitials:   currentUserInitials,
            currentUserAvatarUrl:  currentUserAvatarUrl,
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
                    currentUserId: currentUserId,
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
  final String currentUserId;
  const _PostCard({
    required this.post,
    required this.currentUserName,
    required this.currentUserId,
  });

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
    final isOwn = post.userId == currentUserId;

    return DarkCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileScreen(
                      userId: post.userId,
                      userName: post.userName,
                      userInitials: post.userInitials,
                    ),
                  ),
                ),
                child: InitialsAvatar(
                  initials: post.userInitials,
                  size: 40,
                  bgColor: AppColors.surfaceVariant,
                  photoUrl: post.avatarUrl,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(
                        userId: post.userId,
                        userName: post.userName,
                        userInitials: post.userInitials,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.userName, style: AppTextStyles.labelLarge),
                      Text(_timeAgo(post.createdAt),
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ),
              if (!isOwn) _FollowButton(targetId: post.userId),
              if (isOwn)
                GestureDetector(
                  onTap: () => _confirmDelete(context, provider),
                  child: const Icon(Icons.more_horiz_rounded,
                      color: AppColors.textMuted, size: 20),
                ),
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

          // Post image
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 200,
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary, strokeWidth: 2),
                        ),
                      ),
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: AppColors.textMuted, size: 32),
                  ),
                ),
              ),
            ),
          ],

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

// ─── Follow button ────────────────────────────────────────────────────────────

class _FollowButton extends StatelessWidget {
  final String targetId;
  const _FollowButton({required this.targetId});

  @override
  Widget build(BuildContext context) {
    return Consumer<FollowProvider>(
      builder: (_, fp, __) {
        final following = fp.isFollowing(targetId);
        return GestureDetector(
          onTap: () => fp.toggleFollow(targetId),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: following ? null : AppColors.primaryGradient,
              color: following ? AppColors.surfaceVariant : null,
              borderRadius: BorderRadius.circular(20),
              border: following
                  ? Border.all(color: AppColors.border, width: 0.5)
                  : null,
            ),
            child: Text(
              following ? 'Siguiendo' : 'Seguir',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: following ? AppColors.textSecondary : AppColors.background,
              ),
            ),
          ),
        );
      },
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
  File? _pickedImage;

  @override
  void dispose() {
    _controller.dispose();
    _achievementController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (xfile != null && mounted) {
      setState(() => _pickedImage = File(xfile.path));
    }
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
        .createPost(widget.userName, text, achievement: achievement, imageFile: _pickedImage);
    if (mounted) {
      if (error == null) {
        Navigator.pop(context);
      } else if (error == 'warn:image') {
        // Post creado pero imagen no pudo subirse (configura el bucket en Supabase)
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Publicación creada, pero la foto no se pudo subir. '
              'Ejecuta el SQL de configuración en Supabase para habilitar imágenes.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.accentOrange,
            duration: Duration(seconds: 6),
          ),
        );
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

          // Image preview
          if (_pickedImage != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _pickedImage!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: () => setState(() => _pickedImage = null),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          Row(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Row(
                  children: [
                    Icon(
                      _pickedImage != null
                          ? Icons.image_rounded
                          : Icons.image_outlined,
                      color: AppColors.primary, size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _pickedImage != null ? 'Cambiar foto' : 'Añadir foto',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => setState(() => _showAchievement = !_showAchievement),
                child: Row(
                  children: [
                    Icon(
                      _showAchievement
                          ? Icons.emoji_events_rounded
                          : Icons.emoji_events_outlined,
                      color: AppColors.primary, size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Añadir logro',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
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

// ═══════════════════════════════════════════════════════════════════════════
// RETOS TAB
// ═══════════════════════════════════════════════════════════════════════════

class _ChallengesTab extends StatelessWidget {
  final String currentUserId;
  final String currentUserName;
  const _ChallengesTab({required this.currentUserId, required this.currentUserName});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengesProvider>(
      builder: (ctx, cp, _) {
        if (cp.loading && cp.challenges.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: cp.load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Retos activos', style: AppTextStyles.headingSmall),
                          Text('${cp.challenges.where((c) => c.isActive).length} en curso',
                              style: AppTextStyles.caption),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _openCreate(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add, size: 15, color: AppColors.background),
                              const SizedBox(width: 5),
                              Text('Crear reto',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.background,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (cp.challenges.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events_outlined,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('Aún no hay retos',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        Text('¡Sé el primero en crear uno!',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChallengeCard(
                          challenge:       cp.challenges[i],
                          currentUserId:   currentUserId,
                          currentUserName: currentUserName,
                          provider:        cp,
                        ),
                      ),
                      childCount: cp.challenges.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        );
      },
    );
  }

  void _openCreate(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateChallengeSheet(
        creatorName: currentUserName,
        provider: ctx.read<ChallengesProvider>(),
      ),
    );
  }
}

// ─── Challenge card ───────────────────────────────────────────────────────────

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final String currentUserId;
  final String currentUserName;
  final ChallengesProvider provider;

  const _ChallengeCard({
    required this.challenge,
    required this.currentUserId,
    required this.currentUserName,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = challenge.creatorId == currentUserId;
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: challenge.isActive
                ? AppColors.primary.withOpacity(0.25)
                : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_exerciseIcon(challenge.exercise),
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(challenge.title,
                          style: AppTextStyles.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(challenge.exercise,
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(challenge: challenge),
                if (isOwner) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _confirmDelete(context),
                    child: const Icon(Icons.more_horiz,
                        size: 18, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
            if (challenge.description != null) ...[
              const SizedBox(height: 10),
              Text(challenge.description!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.people_outline,
                  label: '${challenge.participantsCount} participantes',
                ),
                const SizedBox(width: 10),
                _InfoChip(
                  icon: Icons.straighten,
                  label: challenge.unit,
                ),
                const Spacer(),
                if (challenge.myRecord != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.3), width: 0.5),
                    ),
                    child: Text(
                      'Mi marca: ${_formatRecord(challenge.myRecord!, challenge.unit, challenge.myReps)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openDetail(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text('Ver ranking',
                          style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ),
                  ),
                ),
                if (challenge.isActive) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openSubmit(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          challenge.myRecord != null ? 'Actualizar marca' : 'Registrar marca',
                          style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.background),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChallengeDetailSheet(
        challenge:       challenge,
        currentUserId:   currentUserId,
        currentUserName: currentUserName,
        provider:        provider,
      ),
    );
  }

  void _openSubmit(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmitRecordSheet(
        challenge:       challenge,
        currentUserName: currentUserName,
        provider:        provider,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Eliminar reto', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Se borrarán todos los registros. ¿Continuar?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(d, true),
              child: const Text('Eliminar', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true) await provider.deleteChallenge(challenge.id);
  }

  IconData _exerciseIcon(String ex) {
    final lower = ex.toLowerCase();
    if (lower.contains('km') || lower.contains('corre') || lower.contains('carrera')) {
      return Icons.directions_run;
    }
    if (lower.contains('nata') || lower.contains('swim')) return Icons.pool;
    if (lower.contains('bici') || lower.contains('cicl')) return Icons.directions_bike;
    if (lower.contains('flexion') || lower.contains('push')) return Icons.fitness_center;
    return Icons.emoji_events_outlined;
  }
}

// ─── Challenge detail sheet ───────────────────────────────────────────────────

class _ChallengeDetailSheet extends StatefulWidget {
  final Challenge challenge;
  final String currentUserId;
  final String currentUserName;
  final ChallengesProvider provider;
  const _ChallengeDetailSheet({
    required this.challenge,
    required this.currentUserId,
    required this.currentUserName,
    required this.provider,
  });

  @override
  State<_ChallengeDetailSheet> createState() => _ChallengeDetailSheetState();
}

class _ChallengeDetailSheetState extends State<_ChallengeDetailSheet> {
  late Future<List<ChallengeRecord>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = widget.provider.fetchLeaderboard(
      widget.challenge.id,
      higherIsBetter: widget.challenge.higherIsBetter,
      unit:           widget.challenge.unit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ch = widget.challenge;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.93,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(ch.title, style: AppTextStyles.headingSmall),
                      ),
                      _StatusBadge(challenge: ch),
                    ],
                  ),
                  if (ch.description != null) ...[
                    const SizedBox(height: 6),
                    Text(ch.description!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _InfoChip(icon: Icons.straighten, label: ch.unit),
                      _InfoChip(
                          icon: Icons.people_outline,
                          label: '${ch.participantsCount} participantes'),
                      _InfoChip(
                          icon: ch.higherIsBetter
                              ? Icons.arrow_upward
                              : Icons.timer_outlined,
                          label: ch.higherIsBetter ? 'Mayor es mejor' : 'Menor es mejor'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.divider, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Text('Ranking', style: AppTextStyles.labelLarge),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(_reload),
                    child: const Icon(Icons.refresh,
                        size: 18, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ChallengeRecord>>(
                future: _future,
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2));
                  }
                  final records = snap.data ?? [];
                  if (records.isEmpty) {
                    return Center(
                      child: Text('Aún no hay marcas registradas.',
                          style: AppTextStyles.caption),
                    );
                  }
                  return ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: records.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.divider, height: 1),
                    itemBuilder: (_, i) => _RecordRow(
                      record: records[i],
                      unit: ch.unit,
                      isMe: records[i].userId == widget.currentUserId,
                    ),
                  );
                },
              ),
            ),
            if (ch.isActive)
              Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _SubmitRecordSheet(
                        challenge:       ch,
                        currentUserName: widget.currentUserName,
                        provider:        widget.provider,
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ch.myRecord != null ? 'Actualizar mi marca' : 'Registrar mi marca',
                      style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.background),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Record row (leaderboard item) ───────────────────────────────────────────

class _RecordRow extends StatelessWidget {
  final ChallengeRecord record;
  final String unit;
  final bool isMe;
  const _RecordRow({required this.record, required this.unit, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      color: isMe ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: record.rank <= 3
                ? Text(_medal(record.rank),
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center)
                : Text('#${record.rank}',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted)),
          ),
          const SizedBox(width: 10),
          InitialsAvatar(
            initials: record.initials,
            size: 36,
            photoUrl: record.avatarUrl,
            bgColor: AppColors.surfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              record.userName + (isMe ? ' (tú)' : ''),
              style: AppTextStyles.labelMedium.copyWith(
                  color: isMe ? AppColors.primary : AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatRecord(record.value, unit, record.reps),
                style: AppTextStyles.labelLarge.copyWith(
                  color: record.rank == 1 ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              if (unit == 'kg×reps')
                Text(
                  '${record.volume.toInt()} vol',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _medal(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '';
    }
  }
}

// ─── Submit record sheet ──────────────────────────────────────────────────────

class _SubmitRecordSheet extends StatefulWidget {
  final Challenge challenge;
  final String currentUserName;
  final ChallengesProvider provider;
  const _SubmitRecordSheet({
    required this.challenge,
    required this.currentUserName,
    required this.provider,
  });

  @override
  State<_SubmitRecordSheet> createState() => _SubmitRecordSheetState();
}

class _SubmitRecordSheetState extends State<_SubmitRecordSheet> {
  final _weightCtrl = TextEditingController();
  final _repsCtrl   = TextEditingController();
  bool _loading = false;

  bool get _isWeightReps => widget.challenge.unit == 'kg×reps';

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final rawWeight = _weightCtrl.text.trim().replaceAll(',', '.');
    final value = double.tryParse(rawWeight);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isWeightReps
            ? 'Ingresa un peso válido mayor que cero.'
            : 'Ingresa un valor válido mayor que cero.')),
      );
      return;
    }
    int? reps;
    if (_isWeightReps) {
      reps = int.tryParse(_repsCtrl.text.trim());
      if (reps == null || reps <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa un número de repeticiones válido.')),
        );
        return;
      }
    }
    setState(() => _loading = true);
    final err = await widget.provider.upsertRecord(
      challengeId: widget.challenge.id,
      userName:    widget.currentUserName,
      value:       value,
      reps:        reps,
    );
    if (mounted) {
      if (err == null) {
        Navigator.pop(context);
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $err'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final ch = widget.challenge;
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
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(ch.title, style: AppTextStyles.headingSmall),
          const SizedBox(height: 4),
          Text(
            ch.myRecord != null
                ? 'Tu marca actual: ${_formatRecord(ch.myRecord!, ch.unit, ch.myReps)}'
                : 'Registra tu primera marca',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          if (_isWeightReps) ...[
            Row(
              children: [
                Expanded(child: _numField(_weightCtrl, '0', autofocus: true, decimal: true)),
                const SizedBox(width: 10),
                _unitLabel('kg'),
                const SizedBox(width: 16),
                const Text('×', style: TextStyle(fontSize: 22, color: AppColors.textMuted)),
                const SizedBox(width: 16),
                Expanded(child: _numField(_repsCtrl, '0', decimal: false)),
                const SizedBox(width: 10),
                _unitLabel('reps'),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'El ranking se ordena por volumen (kg × reps)',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(child: _numField(_weightCtrl, '0', autofocus: true, decimal: ch.unit == 'kg' || ch.unit == 'km')),
                const SizedBox(width: 12),
                _unitLabel(ch.unit),
              ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.background, strokeWidth: 2))
                    : Text('Guardar marca',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.background)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String hint,
      {bool autofocus = false, bool decimal = true}) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      autofocus: autofocus,
      style: AppTextStyles.headingMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.headingMedium.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
      ),
    );
  }

  Widget _unitLabel(String unit) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    decoration: BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(unit,
        style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
  );
}

// ─── Create challenge sheet ───────────────────────────────────────────────────

class _CreateChallengeSheet extends StatefulWidget {
  final String creatorName;
  final ChallengesProvider provider;
  const _CreateChallengeSheet({required this.creatorName, required this.provider});

  @override
  State<_CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends State<_CreateChallengeSheet> {
  final _titleCtrl       = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _exerciseCtrl    = TextEditingController();
  String _unit           = 'kg';
  bool   _higherIsBetter = true;
  DateTime _deadline     = DateTime.now().add(const Duration(days: 7));
  bool _loading          = false;

  static const _units = ['kg', 'reps', 'seg', 'km', 'kg×reps'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _exerciseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (_, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: AppColors.background,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _exerciseCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Título y ejercicio son obligatorios.')),
      );
      return;
    }
    setState(() => _loading = true);
    final err = await widget.provider.createChallenge(
      creatorName:    widget.creatorName,
      title:          _titleCtrl.text,
      description:    _descCtrl.text.isEmpty ? null : _descCtrl.text,
      exercise:       _exerciseCtrl.text,
      unit:           _unit,
      higherIsBetter: _higherIsBetter,
      deadline:       _deadline,
    );
    if (mounted) {
      if (err == null) {
        Navigator.pop(context);
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $err'),
              backgroundColor: AppColors.error),
        );
      }
    }
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Nuevo reto', style: AppTextStyles.headingSmall),
            const SizedBox(height: 16),
            _buildField(_titleCtrl, 'Título del reto *', maxLines: 1),
            const SizedBox(height: 12),
            _buildField(_exerciseCtrl, 'Ejercicio *  (ej. Peso muerto, 5 km carrera…)', maxLines: 1),
            const SizedBox(height: 12),
            _buildField(_descCtrl, 'Descripción (opcional)', maxLines: 3),
            const SizedBox(height: 16),
            Text('Unidad de medida', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            Row(
              children: _units.map((u) {
                final sel = u == _unit;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _unit = u),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: sel ? AppColors.primaryGradient : null,
                        color: sel ? null : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: sel
                            ? null
                            : Border.all(
                                color: AppColors.border, width: 0.5),
                      ),
                      child: Text(u,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? AppColors.background
                                : AppColors.textSecondary,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_unit == 'kg×reps') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ranking por volumen: kg × reps. Gana quien acumule más volumen total.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Criterio de victoria', style: AppTextStyles.labelMedium),
                        const SizedBox(height: 4),
                        Text(
                          _higherIsBetter
                              ? 'Gana el mayor valor'
                              : 'Gana el menor valor',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _higherIsBetter,
                    onChanged: (v) => setState(() => _higherIsBetter = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fecha límite', style: AppTextStyles.labelMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${_deadline.day}/${_deadline.month}/${_deadline.year}',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Cambiar',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _loading ? null : _submit,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.background, strokeWidth: 2))
                      : Text('Publicar reto',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.background)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final Challenge challenge;
  const _StatusBadge({required this.challenge});

  @override
  Widget build(BuildContext context) {
    if (!challenge.isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('Finalizado',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textMuted)),
      );
    }
    final days = challenge.daysLeft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: days <= 2
            ? AppColors.accentOrange.withOpacity(0.15)
            : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        days == 0 ? 'Hoy' : '${days}d',
        style: AppTextStyles.caption.copyWith(
          color: days <= 2 ? AppColors.accentOrange : AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textMuted)),
        ],
      );
}

String _formatValue(double v, String unit) {
  switch (unit) {
    case 'seg':
      final m = (v ~/ 60).toString().padLeft(2, '0');
      final s = (v % 60).toInt().toString().padLeft(2, '0');
      return '$m:$s';
    case 'kg':
    case 'km':
      return v == v.truncateToDouble() ? '${v.toInt()} $unit' : '${v.toStringAsFixed(1)} $unit';
    default:
      return '${v.toInt()} $unit';
  }
}

String _formatRecord(double v, String unit, int? reps) {
  if (unit != 'kg×reps') return _formatValue(v, unit);
  final kgStr = v == v.truncateToDouble() ? '${v.toInt()} kg' : '${v.toStringAsFixed(1)} kg';
  return reps != null && reps > 0 ? '$kgStr × $reps reps' : kgStr;
}
