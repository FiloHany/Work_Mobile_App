import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary,
          ),
        ),
      );
}

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay(
      {super.key, required this.child, required this.isLoading});
  final Widget child;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          if (isLoading)
            const ColoredBox(
              color: AppColors.overlay,
              child: AppLoading(),
            ),
        ],
      );
}
