import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> saveRestoredFile({
  required String fileName,
  required Uint8List bytes,
  required String mime,
}) async {
  final dir = await getApplicationDocumentsDirectory();
  final restoreDir = Directory(p.join(dir.path, 'arsave_restored'));
  if (!await restoreDir.exists()) {
    await restoreDir.create(recursive: true);
  }
  final safeName = p.basename(fileName);
  final outPath = p.join(restoreDir.path, safeName);
  await File(outPath).writeAsBytes(bytes, flush: true);
  return outPath;
}
