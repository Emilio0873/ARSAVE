import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/feedback.dart';
import '../../core/models/file_kind.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../backup/backup_service.dart';
import 'file_detail_screen.dart';
import 'file_thumbnail.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  List<FileModel> _files = [];
  bool _loading = true;
  String? _error;
  double? _uploadProgress;
  String? _uploadingName;
  String _query = '';
  FileKind? _filter;

  List<FileModel> get _visible {
    return _files.where((f) {
      final q = _query.trim().toLowerCase();
      if (q.isNotEmpty && !f.logicalName.toLowerCase().contains(q)) {
        return false;
      }
      if (_filter != null && kindOfFile(f) != _filter) return false;
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final files = await api.listFiles(status: 'active');
      if (!mounted) return;
      setState(() {
        _files = files;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  String _guessMime(PlatformFile file) {
    final ext = (file.extension ?? '').toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      'mp4' => 'video/mp4',
      'mp3' => 'audio/mpeg',
      'zip' => 'application/zip',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _pickAndBackup() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
      withData: true,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    Uint8List? bytes = file.bytes;
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de lire ce fichier sur cette plateforme.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    final backup = context.read<BackupService>();
    setState(() {
      _uploadProgress = 0;
      _uploadingName = file.name;
    });

    try {
      await backup.backupBytes(
        bytes: bytes,
        logicalName: file.name,
        mime: _guessMime(file),
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      if (!mounted) return;
      showAppSuccess(context, '« ${file.name} » sauvegardé et chiffré.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      showAppError(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _uploadProgress = null;
          _uploadingName = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadProgress != null ? null : _pickAndBackup,
        icon: const Icon(Icons.cloud_upload_rounded),
        label: const Text('Sauvegarder'),
      ),
      body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coffre',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            '${_files.length} fichier${_files.length > 1 ? 's' : ''} protégés',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
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
              if (_uploadProgress != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: SurfacePanel(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chiffrement & envoi…',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _uploadingName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: _uploadProgress,
                            minHeight: 8,
                            backgroundColor: AppColors.line,
                            color: AppColors.coral,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? EmptyStatePanel(
                            icon: Icons.wifi_off_rounded,
                            title: 'Connexion impossible',
                            subtitle: _error!,
                            action: FilledButton(
                              onPressed: _load,
                              child: const Text('Réessayer'),
                            ),
                          )
                        : _files.isEmpty
                            ? EmptyStatePanel(
                                icon: Icons.cloud_done_outlined,
                                title: 'Rien ici pour l’instant',
                                subtitle:
                                    'PDF, images, vidéos, zip, docs… tout type de fichier est accepté et chiffré localement.',
                                action: FilledButton.icon(
                                  onPressed: _pickAndBackup,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Choisir un fichier'),
                                ),
                              )
                            : Column(
                                children: [
                                  SizedBox(
                                    height: 46,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        12,
                                        20,
                                        0,
                                      ),
                                      children: [
                                        for (final entry in <(FileKind?, String)>[
                                          (null, 'Tout'),
                                          (FileKind.image, 'Images'),
                                          (FileKind.video, 'Vidéos'),
                                          (FileKind.audio, 'Audio'),
                                          (FileKind.document, 'Docs'),
                                          (FileKind.archive, 'Archives'),
                                          (FileKind.other, 'Autres'),
                                        ])
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: FilterChip(
                                              label: Text(entry.$2),
                                              selected: _filter == entry.$1,
                                              onSelected: (_) {
                                                setState(() => _filter = entry.$1);
                                              },
                                              selectedColor: AppColors.teal
                                                  .withValues(alpha: 0.28),
                                              checkmarkColor: AppColors.mint,
                                              labelStyle: TextStyle(
                                                color: AppColors.ink,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              side: BorderSide(color: AppColors.line),
                                              backgroundColor: AppColors.panel,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                                    child: TextField(
                                      onChanged: (v) => setState(() => _query = v),
                                      style: TextStyle(color: AppColors.ink),
                                      decoration: const InputDecoration(
                                        hintText: 'Rechercher un fichier',
                                        prefixIcon: Icon(Icons.search_rounded),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: RefreshIndicator(
                                      color: AppColors.teal,
                                      onRefresh: _load,
                                      child: _visible.isEmpty
                                          ? ListView(
                                              children: const [
                                                SizedBox(height: 80),
                                                EmptyStatePanel(
                                                  icon: Icons.filter_alt_off_rounded,
                                                  title: 'Aucun résultat',
                                                  subtitle:
                                                      'Essayez un autre filtre ou une autre recherche.',
                                                ),
                                              ],
                                            )
                                          : GridView.builder(
                                              padding: const EdgeInsets.fromLTRB(
                                                20,
                                                14,
                                                20,
                                                110,
                                              ),
                                              gridDelegate:
                                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                                maxCrossAxisExtent: 240,
                                                mainAxisSpacing: 14,
                                                crossAxisSpacing: 14,
                                                childAspectRatio: 0.78,
                                              ),
                                              itemCount: _visible.length,
                                              itemBuilder: (context, index) {
                                                final f = _visible[index];
                                                return SurfacePanel(
                                                  padding: const EdgeInsets.all(10),
                                                  onTap: () async {
                                                    await Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            FileDetailScreen(file: f),
                                                      ),
                                                    );
                                                    await _load();
                                                  },
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.stretch,
                                                    children: [
                                                      Expanded(
                                                        child: FileThumbnail(file: f),
                                                      ),
                                                      const SizedBox(height: 10),
                                                      Text(
                                                        f.logicalName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${kindLabel(kindOfFile(f))} · ${formatBytes(f.sizeBytes)}',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall,
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                  ),
                                ],
                              ),
              ),
            ],
          ),
        ),
    );
  }
}
