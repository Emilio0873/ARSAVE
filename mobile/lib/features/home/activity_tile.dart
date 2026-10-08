import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';

String activityTitle(String type) {
  return switch (type) {
    'backup' => 'Sauvegarde',
    'download' => 'Téléchargement',
    'trash' => 'Mise en corbeille',
    'restore_meta' => 'Restauration',
    'purge' => 'Suppression définitive',
    'upload' => 'Envoi',
    _ => type,
  };
}

String activityStatusLabel(String status) {
  return switch (status) {
    'success' => 'Réussi',
    'failed' => 'Échec',
    'started' => 'En cours',
    'interrupted' => 'Interrompu',
    _ => status,
  };
}

IconData activityIcon(String type, String status) {
  if (status == 'failed' || status == 'interrupted') {
    return Icons.error_outline_rounded;
  }
  return switch (type) {
    'backup' || 'upload' => Icons.cloud_upload_rounded,
    'download' => Icons.cloud_download_rounded,
    'restore_meta' => Icons.restore_rounded,
    'trash' => Icons.delete_outline_rounded,
    'purge' => Icons.delete_forever_rounded,
    _ => Icons.check_circle_outline_rounded,
  };
}

Color activityColor(String status) {
  return switch (status) {
    'success' => AppColors.teal,
    'failed' || 'interrupted' => const Color(0xFFF87171),
    _ => AppColors.sun,
  };
}

class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.operation});

  final OperationModel operation;

  @override
  Widget build(BuildContext context) {
    final color = activityColor(operation.status);
    final message = (operation.message ?? '').trim();
    return SurfacePanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              activityIcon(operation.type, operation.status),
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activityTitle(operation.type),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        activityStatusLabel(operation.status),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(message, style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 6),
                Text(
                  operation.createdAt,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
