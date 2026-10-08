import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/feedback.dart';
import '../../core/models/file_kind.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../backup/backup_service.dart';

class FileThumbnail extends StatefulWidget {
  const FileThumbnail({
    super.key,
    required this.file,
    this.expand = false,
  });

  final FileModel file;
  final bool expand;

  @override
  State<FileThumbnail> createState() => _FileThumbnailState();
}

class _FileThumbnailState extends State<FileThumbnail> {
  Uint8List? _bytes;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _maybeLoad();
  }

  @override
  void didUpdateWidget(covariant FileThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.id != widget.file.id) {
      _bytes = null;
      _error = null;
      _maybeLoad();
    }
  }

  Future<void> _maybeLoad() async {
    final theme = context.read<ThemeController>();
    final kind = kindOfFile(widget.file);
    final size = widget.file.sizeBytes ?? 0;
    if (!theme.showThumbnails || kind != FileKind.image || size > 8 * 1024 * 1024) {
      return;
    }
    setState(() => _loading = true);
    try {
      final bytes = await context.read<BackupService>().decryptFileBytes(
            fileId: widget.file.id,
          );
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = kindOfFile(widget.file);
    final child = _bytes != null
        ? Image.memory(
            _bytes!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          )
        : _FallbackArt(kind: kind, loading: _loading, error: _error);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.expand ? 18 : 16),
      child: ColoredBox(
        color: AppColors.foam,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            Positioned(
              left: 8,
              top: 8,
              child: _KindChip(kind: kind),
            ),
            if (kind == FileKind.video)
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  size: 42,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.kind});

  final FileKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        kindLabel(kind),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FallbackArt extends StatelessWidget {
  const _FallbackArt({
    required this.kind,
    required this.loading,
    this.error,
  });

  final FileKind kind;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (kind) {
      FileKind.image => (Icons.image_rounded, AppColors.mint),
      FileKind.video => (Icons.movie_rounded, const Color(0xFF7C9CFF)),
      FileKind.audio => (Icons.audiotrack_rounded, const Color(0xFF38BDF8)),
      FileKind.document => (Icons.description_rounded, const Color(0xFF93C5FD)),
      FileKind.archive => (Icons.folder_zip_rounded, const Color(0xFF60A5FA)),
      FileKind.other => (Icons.insert_drive_file_rounded, AppColors.slate),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.28),
            AppColors.panel,
          ],
        ),
      ),
      child: Center(
        child: loading
            ? SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.teal,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 46, color: color),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        error!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
