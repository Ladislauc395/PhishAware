import 'package:flutter/material.dart';

/// Sistema de Staggered Animations (entradas escalonadas).
/// Faz os elementos de uma lista entrar um a um com delay acumulado.
///
/// ─── Uso directo em ListView ────────────────────────────────────────────────
///
///   ListView.builder(
///     itemCount: items.length,
///     itemBuilder: (ctx, i) => StaggeredItem(
///       index: i,
///       child: MyCard(item: items[i]),
///     ),
///   )
///
/// ─── Uso em Column com múltiplos tipos ──────────────────────────────────────
///
///   StaggeredColumn(
///     children: [
///       _RiskRing(...),
///       _XpBar(...),
///       _QuickActions(...),
///     ],
///   )

// ─── StaggeredItem ────────────────────────────────────────────────────────────

class StaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration baseDuration;
  final Duration staggerDelay;
  final Offset beginOffset;
  final Curve curve;

  const StaggeredItem({
    super.key,
    required this.index,
    required this.child,
    this.baseDuration = const Duration(milliseconds: 450),
    this.staggerDelay = const Duration(milliseconds: 60),
    this.beginOffset = const Offset(0, 0.25),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.baseDuration);
    _fade = CurvedAnimation(parent: _ctrl, curve: widget.curve);
    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: widget.curve));

    final delay = widget.staggerDelay * widget.index;
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─── StaggeredColumn ─────────────────────────────────────────────────────────

class StaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration baseDuration;
  final Offset beginOffset;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 70),
    this.baseDuration = const Duration(milliseconds: 500),
    this.beginOffset = const Offset(0, 0.18),
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.asMap().entries.map((e) {
        return StaggeredItem(
          index: e.key,
          staggerDelay: staggerDelay,
          baseDuration: baseDuration,
          beginOffset: beginOffset,
          child: e.value,
        );
      }).toList(),
    );
  }
}

// ─── StaggeredSliverList ──────────────────────────────────────────────────────
// Para usar dentro de CustomScrollView (SliverList)

class StaggeredSliverList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Duration staggerDelay;

  const StaggeredSliverList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.staggerDelay = const Duration(milliseconds: 55),
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => StaggeredItem(
          index: i,
          staggerDelay: staggerDelay,
          child: itemBuilder(ctx, i),
        ),
        childCount: itemCount,
      ),
    );
  }
}
