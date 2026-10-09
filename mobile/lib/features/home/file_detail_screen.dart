import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/feedback.dart';
import '../../core/models/file_kind.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../backup/backup_service.dart';
import 'file_thumbnail.dart';

class FileDetailScreen extends StatefulWidget {
  const FileDetailScreen({super.key, required this.file});

  final FileModel file;

  @override
  State<FileDetailScreen> createState() => _FileDetailScreenState();
}

class _FileDetailScreenState extends State<FileDetailScreen> {
  List<FileVersionModel> _versions = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final versions =
          await context.read<ApiClient>().listVersions(widget.file.id);
      if (!mounted) return;
      setState(() {
        _versions = versions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppError(context, e);
    }
  }

  Future<void> _restore([int? version]) async {
    setState(() => _busy = true);
    try {
      final message = await context.read<BackupService>().restoreFile(
            fileId: widget.file.id,
            version: version,
          );
      if (!mounted) return;
      showAppSuccess(context, message);
    } catch (e) {
      if (!mounted) return;
      showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _trash() async {
    setState(() => _busy = true);
    try {
      await context.read<ApiClient>().trash(widget.file.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.file.logicalName),
          actions: [
            IconButton(
              onPressed: _busy ? null : _trash,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Corbeille',
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  SizedBox(
                    height: 220,
                    child: FileThumbnail(file: widget.file, expand: true),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    kindLabel(kindOfFile(widget.file)),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  SurfacePanel(
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.foam,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            iconForName(widget.file.logicalName),
                            color: AppColors.teal,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.file.logicalName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${formatBytes(widget.file.sizeBytes)} · v${widget.file.currentVersion ?? '-'}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _restore(),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download_rounded),
                    label: const Text('Restaurer la version courante'),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Versions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ..._versions.map(
                    (v) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SurfacePanel(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Version ${v.versionNumber}',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    v.createdAt,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              onPressed: _busy
                                  ? null
                                  : () => _restore(v.versionNumber),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.foam,
                                foregroundColor: AppColors.deepTeal,
                              ),
                              icon: const Icon(Icons.restore_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
