import 'package:couple_app/core/theme/app_tokens.dart';
import 'package:couple_app/core/widgets/app_surface_card.dart';
import 'package:flutter/material.dart';

enum AppStateKind { loading, empty, error, permission }

class AppStatePanel extends StatelessWidget {
  const AppStatePanel({
    required this.kind,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(actionLabel == null || onAction != null);

  final AppStateKind kind;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (kind) {
      AppStateKind.loading => (null, Theme.of(context).colorScheme.primary),
      AppStateKind.empty => (
          Icons.inbox_outlined,
          Theme.of(context).colorScheme.primary
        ),
      AppStateKind.error => (
          Icons.cloud_off_outlined,
          Theme.of(context).colorScheme.error
        ),
      AppStateKind.permission => (
          Icons.lock_outline,
          Theme.of(context).colorScheme.primary
        ),
    };

    return Semantics(
      liveRegion: kind == AppStateKind.loading,
      label: title,
      child: AppSurfaceCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.x4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) Icon(icon, color: color, size: AppSpace.x8),
                if (icon == null)
                  const SizedBox(
                    height: AppSpace.x8,
                    width: AppSpace.x8,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 3),
                  ),
                const SizedBox(height: AppSpace.x3),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (message != null) ...[
                  const SizedBox(height: AppSpace.x1),
                  Text(message!, textAlign: TextAlign.center),
                ],
                if (actionLabel != null) ...[
                  const SizedBox(height: AppSpace.x3),
                  FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
