import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Placeholder animado (shimmer) usado como skeleton durante loading.
/// Cor base e highlight fixos para consistência visual no app.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8ECF2),
      highlightColor: const Color(0xFFF5F7FB),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE8ECF2),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
