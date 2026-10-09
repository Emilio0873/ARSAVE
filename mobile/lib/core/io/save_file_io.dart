import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> saveRestoredFile({
  required String fileName,
  required Uint8List bytes,
  required String mime,
}) async {
  final safeName = p.basename(fileName).replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final ext = p.extension(safeName).replaceFirst('.', '');
  final baseName = ext.isEmpty
      ? safeName
      : p.basenameWithoutExtension(safeName);

  try {
    // Enregistre dans le dossier Téléchargements du téléphone
    final saved = await FileSaver.instance.saveFile(
      name: baseName.isEmpty ? 'arsave_fichier' : baseName,
      bytes: bytes,
      fileExtension: ext.isEmpty ? 'bin' : ext,
      mimeType: _mimeFrom(mime, ext),
    );
    if (saved.isNotEmpty) {
      return 'Téléchargé dans le téléphone : $safeName';
    }
  } catch (_) {
    // Repli ci-dessous
  }

  // Repli : dossier Download public si accessible
  final downloadDir = await _downloadDirectory();
  if (downloadDir != null) {
    final out = File(p.join(downloadDir.path, safeName));
    await out.writeAsBytes(bytes, flush: true);
    return 'Téléchargé dans le téléphone : $safeName';
  }

  final docs = await getApplicationDocumentsDirectory();
  final fallback = File(p.join(docs.path, 'arsave_restored', safeName));
  await fallback.parent.create(recursive: true);
  await fallback.writeAsBytes(bytes, flush: true);
  return 'Fichier enregistré : $safeName';
}

MimeType _mimeFrom(String mime, String ext) {
  final m = mime.toLowerCase();
  if (m.contains('pdf') || ext == 'pdf') return MimeType.pdf;
  if (m.contains('png') || ext == 'png') return MimeType.png;
  if (m.contains('jpeg') || m.contains('jpg') || ext == 'jpg' || ext == 'jpeg') {
    return MimeType.jpeg;
  }
  if (m.contains('gif') || ext == 'gif') return MimeType.gif;
  if (m.contains('webp') || ext == 'webp') return MimeType.webp;
  if (m.contains('mp4') || ext == 'mp4') return MimeType.mp4Video;
  if (m.contains('mp3') || ext == 'mp3') return MimeType.mp3;
  if (m.contains('zip') || ext == 'zip') return MimeType.zip;
  if (m.contains('json') || ext == 'json') return MimeType.json;
  if (m.contains('text') || ext == 'txt') return MimeType.text;
  if (m.contains('csv') || ext == 'csv') return MimeType.csv;
  return MimeType.other;
}

Future<Directory?> _downloadDirectory() async {
  try {
    final dir = await getDownloadsDirectory();
    if (dir != null) return dir;
  } catch (_) {}

  final candidates = <String>[
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Downloads',
    '/sdcard/Download',
  ];
  for (final path in candidates) {
    final d = Directory(path);
    try {
      if (await d.exists()) return d;
    } catch (_) {}
  }
  return null;
}
