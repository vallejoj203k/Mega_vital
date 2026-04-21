import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/data/muscle_data.dart';
import '../../../core/providers/community_provider.dart';
import '../../../core/providers/follow_provider.dart';
import '../../../services/community_service.dart';
import '../../../services/routine_service.dart';
import '../../widgets/shared_widgets.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userInitials;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userInitials,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _db = Supabase.instance.client;

  bool _loading = true;
  String? _goal;
  String? _avatarUrl;
  int _followerCount = 0;
  List<CommunityPost> _posts = [];
  List<SavedRoutine> _routines = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_fetchProfile(), _fetchPosts(), _fetchFollowers(), _fetchRoutines()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchProfile() async {
    try {
      final row = await _db
          .from('user_profiles')
          .select('goal, avatar_url')
          .eq('uid', widget.userId)
          .maybeSingle();
      if (row != null) {
        _goal = row['goal'] as String?;
        _avatarUrl = row['avatar_url'] as String?;
      }
    } catch (_) {}
  }

  Future<void> _fetchPosts() async {
    try {
      final uid = _db.auth.currentUser?.id ?? '';
      final postsRaw = await _db
          .from('community_posts')
          .select()
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false)
          .limit(20);

      final likesRaw = await _db
          .from('post_likes')
          .select('post_id')
          .eq('user_id', uid);
      final likedIds = <String>{
        for (final l in likesRaw as List) l['post_id'] as String,
      };
      _posts = [
        for (final m in postsRaw as List)
          CommunityPost.fromMap(m as Map<String, dynamic>, likedIds.contains(m['id'])),
      ];
    } catch (_) {}
  }

  Future<void> _fetchFollowers() async {
    try {
      final rows = await _db
          .from('user_follows')
          .select('id')
          .eq('following_id', widget.userId);
      _followerCount = (rows as List).length;
    } catch (_) {}
  }

  Future<void> _fetchRoutines() async {
    _routines = await RoutineService().loadRoutinesForUser(widget.userId);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Header ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.userName,
                              style: AppTextStyles.headingMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // ── Tarjeta de perfil ────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DarkCard(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F2318), Color(0xFF0A1A10)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderColor: AppColors.primary.withOpacity(0.2),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                InitialsAvatar(
                                  initials: widget.userInitials,
                                  size: 72,
                                  photoUrl: _avatarUrl,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(widget.userName,
                                          style: AppTextStyles.headingMedium),
                                      if (_goal != null) ...[
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          const Icon(Icons.flag_outlined,
                                              size: 13,
                                              color: AppColors.textMuted),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(_goal!,
                                                style:
                                                    AppTextStyles.bodyMedium),
                                          ),
                                        ]),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Stats row
                            Row(
                              children: [
                                _StatChip(
                                    value: '$_followerCount',
                                    label: 'Seguidores'),
                                const SizedBox(width: 12),
                                _StatChip(
                                    value: '${_posts.length}',
                                    label: 'Publicaciones'),
                                const SizedBox(width: 12),
                                _StatChip(
                                    value: '${_routines.length}',
                                    label: 'Rutinas'),
                                const Spacer(),
                                // Follow button
                                Consumer<FollowProvider>(
                                  builder: (_, fp, __) {
                                    final isMe = widget.userId ==
                                        (_db.auth.currentUser?.id ?? '');
                                    if (isMe) return const SizedBox.shrink();
                                    final following =
                                        fp.isFollowing(widget.userId);
                                    return GestureDetector(
                                      onTap: () =>
                                          fp.toggleFollow(widget.userId),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 18, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: following
                                              ? null
                                              : AppColors.primaryGradient,
                                          color: following
                                              ? AppColors.surfaceVariant
                                              : null,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: following
                                              ? Border.all(
                                                  color: AppColors.border,
                                                  width: 0.5)
                                              : null,
                                        ),
                                        child: Text(
                                          following ? 'Siguiendo' : 'Seguir',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: following
                                                ? AppColors.textSecondary
                                                : AppColors.background,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // ── Sección rutinas ──────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Rutinas', style: AppTextStyles.headingSmall),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  if (_routines.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Center(
                          child: Text(
                            'Sin rutinas aún',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: _RoutineCard(routine: _routines[i]),
                        ),
                        childCount: _routines.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // ── Sección publicaciones ────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Publicaciones',
                          style: AppTextStyles.headingSmall),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  if (_posts.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 24),
                        child: Center(
                          child: Text(
                            'Sin publicaciones aún',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          if (i == _posts.length) {
                            return const SizedBox(height: 100);
                          }
                          final post = _posts[i];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: _ProfilePostCard(
                              post: post,
                              timeAgo: _timeAgo(post.createdAt),
                            ),
                          );
                        },
                        childCount: _posts.length + 1,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTextStyles.headingSmall
                .copyWith(color: AppColors.primary)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final SavedRoutine routine;
  const _RoutineCard({required this.routine});

  @override
  Widget build(BuildContext context) {
    final muscle = kMuscleGroups.cast<MuscleGroup?>()
        .firstWhere((m) => m?.id == routine.muscleId, orElse: () => null);
    final color = muscle?.color ?? AppColors.primary;

    return DarkCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(
                  routine.muscleName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  routine.name,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${routine.exercises.length} ejerc.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          if (routine.exercises.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...routine.exercises.take(4).map((ex) {
              final weight = routine.exerciseWeights[ex.id];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(ex.icon, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(ex.name, style: AppTextStyles.caption),
                    ),
                    const SizedBox(width: 6),
                    // Series chip
                    _ExerciseChip(
                      label: '${ex.sets} series',
                      icon: Icons.repeat_rounded,
                    ),
                    const SizedBox(width: 4),
                    // Reps chip
                    _ExerciseChip(
                      label: '${ex.reps} reps',
                      icon: Icons.format_list_numbered_rounded,
                    ),
                    if (weight != null && weight > 0) ...[
                      const SizedBox(width: 4),
                      // Weight chip
                      _ExerciseChip(
                        label: '${weight % 1 == 0 ? weight.toInt() : weight}kg',
                        icon: Icons.fitness_center_rounded,
                        highlight: true,
                      ),
                    ],
                  ],
                ),
              );
            }),
            if (routine.exercises.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+${routine.exercises.length - 4} más',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool highlight;
  const _ExerciseChip({required this.label, required this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.primary : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25), width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 9, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

class _ProfilePostCard extends StatelessWidget {
  final CommunityPost post;
  final String timeAgo;
  const _ProfilePostCard({required this.post, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CommunityProvider>();
    return DarkCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.achievement != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            ),
          Text(post.content, style: AppTextStyles.bodyMedium),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 160,
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary, strokeWidth: 2),
                        ),
                      ),
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () => provider.toggleLike(post.id),
                child: Row(children: [
                  Icon(
                    post.likedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 16,
                    color: post.likedByMe
                        ? AppColors.error
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text('${post.likesCount}',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('${post.commentsCount}',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
              const Spacer(),
              Text(timeAgo,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
