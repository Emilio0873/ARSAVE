import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/feedback.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../backup/backup_service.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<FileModel> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final files = await context.read<ApiClient>().listFiles(status: 'trashed');
      if (!mounted) return;
      setState(() {
        _files = files;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppError(context, e);
    }
  }

  Future<void> _restoreMeta(FileModel file) async {
    try {
      await context.read<ApiClient>().restoreMeta(file.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      showAppError(context, e);
    }
  }

  Future<void> _restoreContent(FileModel file) async {
    try {
      final message =
          await context.read<BackupService>().restoreFile(fileId: file.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Fichier téléchargé'),
          content: Text(
            '$message\n\n'
            'Où le trouver : Fichiers → Téléchargements '
            '(ou Téléchargements → arsave).',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showAppError(context, e);
    }
  }

  Future<void> _purge(FileModel file) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Suppression définitive'),
        content: Text('Supprimer définitivement « ${file.logicalName} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    try {
      await context.read<ApiClient>().purge(file.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      showAppError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Corbeille',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _load,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.foam,
                      foregroundColor: AppColors.deepTeal,
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _files.isEmpty
                      ? const EmptyStatePanel(
                          icon: Icons.delete_outline_rounded,
                          title: 'Corbeille vide',
                          subtitle:
                              'Les fichiers mis de côté apparaîtront ici.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: _files.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final f = _files[index];
                            return SurfacePanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        iconForName(f.logicalName),
                                        color: AppColors.coral,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          f.logicalName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'meta':
                                              _restoreMeta(f);
                                            case 'content':
                                              _restoreContent(f);
                                            case 'purge':
                                              _purge(f);
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'meta',
                                            child: Text('Remettre dans le coffre'),
                                          ),
                                          PopupMenuItem(
                                            value: 'content',
                                            child: Text('Télécharger / déchiffrer'),
                                          ),
                                          PopupMenuItem(
                                            value: 'purge',
                                            child: Text('Supprimer définitivement'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Supprimé : ${f.trashedAt ?? '—'}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
