import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String> saveRestoredFile({
  required String fileName,
  required Uint8List bytes,
  required String mime,
}) async {
  final safeName = p.basename(fileName).replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final dir = await getTemporaryDirectory();
  final outPath = p.join(dir.path, 'arsave_$safeName');
  final file = File(outPath);
  await file.writeAsBytes(bytes, flush: true);

  await Share.shareXFiles(
    [
      XFile(
        outPath,
        mimeType: mime.isEmpty ? 'application/octet-stream' : mime,
        name: safeName,
      ),
    ],
    subject: safeName,
    text: 'Fichier restauré avec arsave',
  );

  return 'Fichier restauré : $safeName';
}
