import 'dart:html' as html;
import 'dart:typed_data';

Future<String> saveRestoredFile({
  required String fileName,
  required Uint8List bytes,
  required String mime,
}) async {
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return 'Téléchargé : $fileName';
}
