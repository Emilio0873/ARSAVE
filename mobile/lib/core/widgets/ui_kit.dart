import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AuraBackground extends StatelessWidget {
  const AuraBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgTop,
            AppColors.bgMid,
            AppColors.bgBottom,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -50,
            child: _Blob(
              size: 260,
              color: AppColors.teal.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -70,
            child: _Blob(
              size: 280,
              color: const Color(0xFF1D4ED8).withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: 200,
            left: 30,
            child: _Blob(
              size: 140,
              color: AppColors.mint.withValues(alpha: 0.10),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false, this.logoOnly = false});

  final bool compact;
  final bool logoOnly;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 48.0 : (logoOnly ? 160.0 : 88.0);
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 12 : 20),
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );

    if (logoOnly || compact) {
      return logo;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(height: 14),
        Text(
          'arsave',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sauvegarde et restauration sécurisées',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.slate,
              ),
        ),
      ],
    );
  }
}

class EmptyStatePanel extends StatelessWidget {
  const EmptyStatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.foam,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.line),
              ),
              child: Icon(icon, size: 40, color: AppColors.mint),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.95)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: content,
      ),
    );
  }
}

String formatBytes(int? bytes) {
  if (bytes == null) return '—';
  if (bytes < 1024) return '$bytes o';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} Ko';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
}

IconData iconForName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
  if (lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.bmp') ||
      lower.endsWith('.svg')) {
    return Icons.image_rounded;
  }
  if (lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.mkv') ||
      lower.endsWith('.webm')) {
    return Icons.movie_rounded;
  }
  if (lower.endsWith('.mp3') ||
      lower.endsWith('.wav') ||
      lower.endsWith('.flac') ||
      lower.endsWith('.aac') ||
      lower.endsWith('.m4a')) {
    return Icons.audiotrack_rounded;
  }
  if (lower.endsWith('.zip') ||
      lower.endsWith('.rar') ||
      lower.endsWith('.7z') ||
      lower.endsWith('.tar') ||
      lower.endsWith('.gz')) {
    return Icons.folder_zip_rounded;
  }
  if (lower.endsWith('.doc') ||
      lower.endsWith('.docx') ||
      lower.endsWith('.odt') ||
      lower.endsWith('.rtf') ||
      lower.endsWith('.txt') ||
      lower.endsWith('.md')) {
    return Icons.description_rounded;
  }
  if (lower.endsWith('.xls') ||
      lower.endsWith('.xlsx') ||
      lower.endsWith('.csv')) {
    return Icons.table_chart_rounded;
  }
  if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) {
    return Icons.slideshow_rounded;
  }
  if (lower.endsWith('.apk') ||
      lower.endsWith('.exe') ||
      lower.endsWith('.dmg') ||
      lower.endsWith('.iso')) {
    return Icons.memory_rounded;
  }
  return Icons.insert_drive_file_rounded;
}
