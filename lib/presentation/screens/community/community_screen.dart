// lib/presentation/screens/community/community_screen.dart
// ──────────────────────────────────────────────────────
// Pantalla de Comunidad con:
//   • Feed de publicaciones
//   • Logros compartidos
//   • Likes y comentarios
//   • Clasificación semanal
// ──────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/mock/mock_data.dart';
import '../../widgets/shared_widgets.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Comunidad', style: AppTextStyles.displayMedium),
                  NeonButton(
                    label: 'Publicar',
                    icon: Icons.add,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // TabBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _CustomTabBar(controller: _tabController),
            ),

            const SizedBox(height: 16),

            // Contenido de los tabs
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _FeedTab(),
                  _LeaderboardTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab bar personalizado ───
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
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Feed'),
          Tab(text: 'Clasificación'),
        ],
      ),
    );
  }
}

// ─── Tab Feed ───
class _FeedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: MockData.communityPosts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _PostCard(post: MockData.communityPosts[i]),
    );
  }
}

// ─── Tarjeta de post ───
class _PostCard extends StatefulWidget {
  final CommunityPostModel post;
  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _liked = false;
  late int _likes;

  @override
  void initState() {
    super.initState();
    _likes = widget.post.likes;
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del post
          Row(
            children: [
              InitialsAvatar(
                initials: widget.post.initials,
                size: 40,
                bgColor: AppColors.surfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.post.userName,
                        style: AppTextStyles.labelLarge),
                    Text(widget.post.time, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Icon(Icons.more_horiz_rounded,
                  color: AppColors.textMuted, size: 20),
            ],
          ),

          // Badge de logro si existe
          if (widget.post.achievement != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.post.achievement!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.background,
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Contenido
          Text(widget.post.content, style: AppTextStyles.bodyMedium),

          const SizedBox(height: 14),

          // Separador
          Divider(color: AppColors.divider, height: 1),

          const SizedBox(height: 10),

          // Acciones
          Row(
            children: [
              _ActionButton(
                icon: _liked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: '$_likes',
                color: _liked ? AppColors.error : AppColors.textMuted,
                onTap: _toggleLike,
              ),
              const SizedBox(width: 20),
              _ActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${widget.post.comments}',
                color: AppColors.textMuted,
                onTap: () {},
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
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Clasificación ───
class _LeaderboardTab extends StatelessWidget {
  final _leaders = const [
    {'name': 'Carlos Méndez', 'initials': 'CM', 'pts': 2340, 'rank': 1},
    {'name': 'Ana Torres', 'initials': 'AT', 'pts': 2180, 'rank': 2},
    {'name': 'Juan García', 'initials': 'JG', 'pts': 1950, 'rank': 3},
    {'name': 'Luis Herrera', 'initials': 'LH', 'pts': 1720, 'rank': 4},
    {'name': 'María Rodríguez', 'initials': 'MR', 'pts': 1540, 'rank': 5},
    {'name': 'Pedro López', 'initials': 'PL', 'pts': 1320, 'rank': 6},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Top 3 podio
        _PodiumRow(leaders: _leaders.take(3).toList()),
        const SizedBox(height: 20),
        Text('Clasificación completa', style: AppTextStyles.headingSmall),
        const SizedBox(height: 12),
        // Lista del 4 en adelante
        ..._leaders.skip(3).map(
          (l) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LeaderCard(
              rank: l['rank'] as int,
              name: l['name'] as String,
              initials: l['initials'] as String,
              points: l['pts'] as int,
              isMe: l['initials'] == 'JG',
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _PodiumRow extends StatelessWidget {
  final List<Map<String, dynamic>> leaders;
  const _PodiumRow({required this.leaders});

  @override
  Widget build(BuildContext context) {
    if (leaders.length < 3) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2do lugar
        Expanded(
          child: _PodiumCard(
            rank: 2,
            name: leaders[1]['name'],
            initials: leaders[1]['initials'],
            points: leaders[1]['pts'],
            height: 100,
            color: AppColors.accentBlue,
          ),
        ),
        const SizedBox(width: 8),
        // 1er lugar
        Expanded(
          child: _PodiumCard(
            rank: 1,
            name: leaders[0]['name'],
            initials: leaders[0]['initials'],
            points: leaders[0]['pts'],
            height: 130,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        // 3er lugar
        Expanded(
          child: _PodiumCard(
            rank: 3,
            name: leaders[2]['name'],
            initials: leaders[2]['initials'],
            points: leaders[2]['pts'],
            height: 80,
            color: AppColors.accentOrange,
          ),
        ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final int rank;
  final String name;
  final String initials;
  final int points;
  final double height;
  final Color color;

  const _PodiumCard({
    required this.rank,
    required this.name,
    required this.initials,
    required this.points,
    required this.height,
    required this.color,
  });

  String get _rankEmoji {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_rankEmoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        InitialsAvatar(initials: initials, size: 36, bgColor: color.withOpacity(0.2)),
        const SizedBox(height: 4),
        Text(
          name.split(' ').first,
          style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: color.withOpacity(0.3), width: 0.5),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$points',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text('pts', style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderCard extends StatelessWidget {
  final int rank;
  final String name;
  final String initials;
  final int points;
  final bool isMe;

  const _LeaderCard({
    required this.rank,
    required this.name,
    required this.initials,
    required this.points,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      borderColor: isMe ? AppColors.primary.withOpacity(0.4) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: AppTextStyles.labelMedium,
            ),
          ),
          InitialsAvatar(
            initials: initials,
            size: 38,
            bgColor: isMe ? null : AppColors.surfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMe ? '$name (tú)' : name,
              style: AppTextStyles.labelLarge.copyWith(
                color: isMe ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '$points pts',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
