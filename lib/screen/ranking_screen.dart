import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_models.dart';
import 'api_service.dart';

class RankingScreen extends StatefulWidget {
  final int currentUserId;
  const RankingScreen({super.key, required this.currentUserId});
  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<RankingUser> _ranking = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getRanking();
      setState(() {
        _ranking = data
            .map((u) => RankingUser.fromJson(u, widget.currentUserId))
            .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myIndex = _ranking.indexWhere((u) => u.isCurrentUser);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Ranking',
                        style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700)),
                    Text('Compara o teu progresso com outros',
                        style: GoogleFonts.inter(
                            color: AppColors.textMuted, fontSize: 13)),
                  ])),
              GestureDetector(
                onTap: _load,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.refresh,
                      color: AppColors.accent, size: 18),
                ),
              ),
            ]),
          ),

          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
                : _ranking.isEmpty
                    ? _Empty()
                    : RefreshIndicator(
                        color: AppColors.accent,
                        backgroundColor: AppColors.surface,
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                          children: [
                            // Top 3 podium (if enough users)
                            if (_ranking.length >= 3) ...[
                              _Podium(users: _ranking.take(3).toList()),
                              const SizedBox(height: 24),
                            ],

                            // My position badge
                            if (myIndex >= 0) ...[
                              _MyPositionBanner(
                                  position: myIndex + 1,
                                  user: _ranking[myIndex]),
                              const SizedBox(height: 16),
                            ],

                            // Full list
                            Text('Classificação Completa',
                                style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            ..._ranking.asMap().entries.map((e) => _RankingTile(
                                position: e.key + 1, user: e.value)),

                            // Medals section
                            const SizedBox(height: 28),
                            Text('Medalhas & Conquistas',
                                style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            _MedalsGrid(),
                          ],
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}

// ── Podium ────────────────────────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<RankingUser> users;
  const _Podium({required this.users});

  @override
  Widget build(BuildContext context) {
    // Order: 2nd, 1st, 3rd
    final order = [users[1], users[0], users[2]];
    final heights = [60.0, 90.0, 45.0];
    final medals = ['🥈', '🥇', '🥉'];
    final colors = [
      const Color(0xFF94A3B8),
      AppColors.warn,
      const Color(0xFFCD7F32),
    ];
    final positions = [2, 1, 3];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.surface2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
            3,
            (i) => _PodiumItem(
                  user: order[i],
                  height: heights[i],
                  medal: medals[i],
                  color: colors[i],
                  position: positions[i],
                )),
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final RankingUser user;
  final double height;
  final String medal;
  final Color color;
  final int position;
  const _PodiumItem(
      {required this.user,
      required this.height,
      required this.medal,
      required this.color,
      required this.position});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(medal, style: const TextStyle(fontSize: 24)),
      const SizedBox(height: 4),
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: user.isCurrentUser
              ? AppColors.accent.withAlpha(30)
              : AppColors.surface2,
          border: Border.all(
              color: user.isCurrentUser ? AppColors.accent : color, width: 2),
        ),
        child: Center(
            child: Text(user.avatarLetter,
                style: GoogleFonts.spaceGrotesk(
                    color: user.isCurrentUser ? AppColors.accent : color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700))),
      ),
      const SizedBox(height: 4),
      Text(user.name.split(' ').first,
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      Text('${user.xp} XP',
          style: GoogleFonts.inter(color: color, fontSize: 10)),
      const SizedBox(height: 8),
      Container(
        width: 64,
        height: height,
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Center(
            child: Text('$position°',
                style: GoogleFonts.spaceGrotesk(
                    color: color, fontSize: 20, fontWeight: FontWeight.w700))),
      ),
    ]);
  }
}

// ── My Position ───────────────────────────────────────────────────────────────
class _MyPositionBanner extends StatelessWidget {
  final int position;
  final RankingUser user;
  const _MyPositionBanner({required this.position, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withAlpha(20),
            AppColors.blue.withAlpha(20)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withAlpha(80)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.person, color: AppColors.accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('A tua posição',
              style:
                  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
          Text('${position}º lugar · ${user.xp} XP',
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(user.level,
              style: GoogleFonts.inter(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

// ── Ranking Tile ──────────────────────────────────────────────────────────────
class _RankingTile extends StatelessWidget {
  final int position;
  final RankingUser user;
  const _RankingTile({required this.position, required this.user});

  Color get _posColor {
    if (position == 1) return AppColors.warn;
    if (position == 2) return const Color(0xFF94A3B8);
    if (position == 3) return const Color(0xFFCD7F32);
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: user.isCurrentUser
            ? AppColors.accent.withAlpha(10)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.isCurrentUser
              ? AppColors.accent.withAlpha(80)
              : AppColors.border,
          width: user.isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        SizedBox(
            width: 28,
            child: Text('$position°',
                style: GoogleFonts.spaceGrotesk(
                    color: _posColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700))),
        const SizedBox(width: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (user.isCurrentUser ? AppColors.accent : AppColors.surface2),
            border: Border.all(
                color:
                    user.isCurrentUser ? AppColors.accent : AppColors.border),
          ),
          child: Center(
              child: Text(user.avatarLetter,
                  style: GoogleFonts.spaceGrotesk(
                      color: user.isCurrentUser ? Colors.black : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(user.name,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            if (user.isCurrentUser) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Tu',
                    style: GoogleFonts.inter(
                        color: AppColors.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
          Text(user.level,
              style:
                  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
        ])),
        Text('${user.xp} XP',
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ── Medals ────────────────────────────────────────────────────────────────────
class _MedalsGrid extends StatelessWidget {
  static const _medals = [
    ('🏆', 'Sentinela Elite', AppColors.warn),
    ('🎯', 'Mestre Phishing', Color(0xFFF57C6B)),
    ('🛡️', 'Defensor Digital', AppColors.blue),
    ('⚡', 'Velocidade', Color(0xFF8B5CF6)),
    ('🔍', 'Detetive URL', AppColors.accent),
    ('📱', 'App Expert', Color(0xFF10B981)),
    ('💬', 'SMS Guard', AppColors.warn),
    ('📧', 'Email Pro', AppColors.accent2),
  ];

  const _MedalsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.72,
      children: _medals
          .map((m) => _MedalCard(emoji: m.$1, label: m.$2, color: m.$3))
          .toList(),
    );
  }
}

class _MedalCard extends StatelessWidget {
  final String emoji, label;
  final Color color;
  const _MedalCard(
      {required this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(height: 6),
        Text(label.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 7,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      ]);
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Ranking vazio',
              style:
                  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
          Text('Completa simulações para aparecer aqui!',
              style:
                  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
        ],
      ));
}
