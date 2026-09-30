import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HolographicRibbon extends StatefulWidget {
  final double width;
  final double height;

  const HolographicRibbon({
    super.key,
    this.width = double.infinity,
    this.height = 14,
  });

  @override
  State<HolographicRibbon> createState() => _HolographicRibbonState();
}

class _HolographicRibbonState extends State<HolographicRibbon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (_controller.value * 1.5), -1.0),
              end: Alignment(1.0 + (_controller.value * 1.5), 1.0),
              colors: const [
                AppColors.goldDark,
                AppColors.goldPrimary,
                AppColors.goldLight,
                Colors.white,
                AppColors.goldLight,
                AppColors.goldPrimary,
                AppColors.goldDark,
              ],
              stops: const [0.0, 0.2, 0.4, 0.5, 0.6, 0.8, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldPrimary.withAlpha(50),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              6,
              (index) => Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.obsidianBlack.withAlpha(140),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
