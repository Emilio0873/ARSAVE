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
      ? (safeName.isEmpty ? 'arsave_fichier' : safeName)
      : p.basenameWithoutExtension(safeName);
  final extension = ext.isEmpty ? 'bin' : ext;
  final mimeType = _mimeFrom(mime, extension);

  // 1) Dialogue système Android : l'utilisateur voit où enregistrer
  //    (choisir "Téléchargements" / Download)
  try {
    final path = await FileSaver.instance.saveAs(
      name: baseName,
      bytes: bytes,
      fileExtension: extension,
      mimeType: mimeType,
    );
    if (path != null && path.isNotEmpty) {
      return 'Fichier enregistré sur le téléphone.\nEmplacement : $path';
    }
  } catch (_) {
    // continue vers les replis
  }

  // 2) Enregistrement auto dans Téléchargements/arsave
  final downloadRoot = await _publicDownloadDir();
  if (downloadRoot != null) {
    final arsaveDir = Directory(p.join(downloadRoot.path, 'arsave'));
    if (!await arsaveDir.exists()) {
      await arsaveDir.create(recursive: true);
    }
    final out = File(p.join(arsaveDir.path, safeName));
    await out.writeAsBytes(bytes, flush: true);
    return 'Fichier enregistré dans Téléchargements → arsave → $safeName';
  }

  // 3) Dernier repli
  try {
    final saved = await FileSaver.instance.saveFile(
      name: baseName,
      bytes: bytes,
      fileExtension: extension,
      mimeType: mimeType,
    );
    if (saved.isNotEmpty) {
      return 'Fichier téléchargé : $safeName\nOuvrez l’application Fichiers → Téléchargements.';
    }
  } catch (_) {}

  final docs = await getApplicationDocumentsDirectory();
  final fallback = File(p.join(docs.path, 'arsave_restored', safeName));
  await fallback.parent.create(recursive: true);
  await fallback.writeAsBytes(bytes, flush: true);
  return 'Fichier enregistré dans l’application : $safeName';
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

Future<Directory?> _publicDownloadDir() async {
  try {
    final dir = await getDownloadsDirectory();
    if (dir != null && await dir.exists()) return dir;
  } catch (_) {}

  for (final path in const [
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Downloads',
    '/sdcard/Download',
  ]) {
    final d = Directory(path);
    try {
      if (await d.exists()) return d;
    } catch (_) {}
  }
  return null;
}
