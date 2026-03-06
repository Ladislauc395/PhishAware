import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';
import 'api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  HistoryScreenState createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> with RouteAware {
  List<HistoryEntry> _entries = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  static final routeObserver = RouteObserver<ModalRoute<void>>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _load();
  }

  void reload() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getHistory();

      final parsed = <HistoryEntry>[];
      for (final raw in data) {
        try {
          parsed.add(HistoryEntry.fromJson(raw as Map<String, dynamic>));
        } catch (e) {
          debugPrint('[HistoryScreen] Failed to parse entry: $raw\nError: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _entries = parsed;
        _loading = false;
      });
    } catch (e, stack) {
      debugPrint('[HistoryScreen] _load error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<HistoryEntry> get _filtered {
    if (_filter == 'correct')
      return _entries.where((e) => e.isCorrect).toList();
    if (_filter == 'wrong') return _entries.where((e) => !e.isCorrect).toList();
    return _entries;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalXp = _entries.fold<int>(0, (sum, e) => sum + e.points);
    final correct = _entries.where((e) => e.isCorrect).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Text('Histórico',
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accent),
                      )
                    : GestureDetector(
                        onTap: _load,
                        child: const Icon(Icons.refresh,
                            color: AppColors.textMuted),
                      ),
              ]),
              const SizedBox(height: 20),
              if (_entries.isNotEmpty) ...[
                Row(children: [
                  _MiniCard('${_entries.length}', 'Questões', AppColors.blue),
                  const SizedBox(width: 10),
                  _MiniCard('$correct', 'Acertos', AppColors.accent),
                  const SizedBox(width: 10),
                  _MiniCard('$totalXp XP', 'Ganhos', AppColors.warn),
                ]),
                const SizedBox(height: 16),
              ],
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _Chip('Todos', 'all', _filter,
                      (v) => setState(() => _filter = v)),
                  const SizedBox(width: 8),
                  _Chip('Acertos', 'correct', _filter,
                      (v) => setState(() => _filter = v)),
                  const SizedBox(width: 8),
                  _Chip('Erros', 'wrong', _filter,
                      (v) => setState(() => _filter = v)),
                ]),
              ),
              const SizedBox(height: 16),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
                : _error != null
                    ? _ErrorState(message: _error!, onRetry: _load)
                    : filtered.isEmpty
                        ? _EmptyState(_entries.isEmpty)
                        : RefreshIndicator(
                            color: AppColors.accent,
                            backgroundColor: AppColors.surface,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) =>
                                  _HistoryCard(entry: filtered[i]),
                            ),
                          ),
          ),
        ]),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Erro ao carregar histórico',
                style: GoogleFonts.spaceGrotesk(
                    color: AppColors.danger,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message,
                style:
                    GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withAlpha(60)),
                ),
                child: Text('Tentar novamente',
                    style: GoogleFonts.inter(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      );
}

class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.isCorrect
              ? AppColors.accent.withAlpha(60)
              : AppColors.danger.withAlpha(40),
        ),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: entry.categoryColor.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
              child: Text(entry.categoryIcon,
                  style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry.scenario,
              style: GoogleFonts.inter(
                  color: AppColors.text, fontSize: 12, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(entry.timeAgo,
              style:
                  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (entry.isCorrect ? AppColors.accent : AppColors.danger)
                  .withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(entry.isCorrect ? '✓ Acerto' : '✗ Erro',
                style: GoogleFonts.inter(
                  color: entry.isCorrect ? AppColors.accent : AppColors.danger,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                )),
          ),
          if (entry.points > 0) ...[
            const SizedBox(height: 4),
            Text('+${entry.points} XP',
                style: GoogleFonts.inter(
                    color: AppColors.warn,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ]),
      ]),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String value, label;
  final Color color;
  const _MiniCard(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Column(children: [
            Text(value,
                style: GoogleFonts.spaceGrotesk(
                    color: color, fontSize: 16, fontWeight: FontWeight.w700)),
            Text(label,
                style: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 10)),
          ]),
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label, value, selected;
  final ValueChanged<String> onTap;
  const _Chip(this.label, this.value, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) {
    final active = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.accent.withAlpha(20) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: active ? AppColors.accent : AppColors.border),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
              color: active ? AppColors.accent : AppColors.textMuted,
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            )),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool noData;
  const _EmptyState(this.noData);
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(noData ? '📋' : '🔍', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(noData ? 'Ainda sem atividade' : 'Nenhum resultado encontrado',
              style:
                  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
              noData
                  ? 'Completa uma simulação para ver o teu histórico aqui.'
                  : 'Tenta um filtro diferente.',
              style:
                  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center),
        ]),
      );
}
