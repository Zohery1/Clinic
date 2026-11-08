import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Premium Enterprise SaaS scaffold. Handles the three shell patterns:
///   - sidebar + topBar + body
///   - sidebar + body
///   - topBar + body + bottomBar
class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? sidebar;
  final Widget? topBar;
  final Widget? bottomBar;
  final EdgeInsetsGeometry padding;
  final Color? background;

  const AppScaffold({
    super.key,
    required this.body,
    this.sidebar,
    this.topBar,
    this.bottomBar,
    this.padding = EdgeInsets.zero,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final bg = background ?? AppColors.canvas(context);
    final bodyContent = Padding(padding: padding, child: body);

    if (sidebar != null) {
      final main = topBar != null
          ? Expanded(
              child: Column(
                children: [
                  topBar!,
                  if (topBar != null) const SizedBox(height: 0),
                  Expanded(child: bodyContent),
                ],
              ),
            )
          : Expanded(child: bodyContent);

      return Material(
        color: bg,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sidebar!,
            main,
          ],
        ),
      );
    }

    return Material(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (topBar != null) topBar!,
          Expanded(child: bodyContent),
          if (bottomBar != null)
            SafeArea(
              top: false,
              child: bottomBar!,
            ),
        ],
      ),
    );
  }
}

