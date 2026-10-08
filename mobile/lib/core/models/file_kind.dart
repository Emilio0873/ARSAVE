import '../../core/models/models.dart';

enum FileKind { image, video, audio, document, archive, other }

FileKind kindOfFile(FileModel file) {
  final mime = file.mime.toLowerCase();
  final name = file.logicalName.toLowerCase();
  if (mime.startsWith('image/') ||
      _hasExt(name, const [
        '.png',
        '.jpg',
        '.jpeg',
        '.gif',
        '.webp',
        '.bmp',
        '.svg',
      ])) {
    return FileKind.image;
  }
  if (mime.startsWith('video/') ||
      _hasExt(name, const ['.mp4', '.mov', '.avi', '.mkv', '.webm'])) {
    return FileKind.video;
  }
  if (mime.startsWith('audio/') ||
      _hasExt(name, const ['.mp3', '.wav', '.flac', '.aac', '.m4a'])) {
    return FileKind.audio;
  }
  if (_hasExt(name, const [
        '.pdf',
        '.doc',
        '.docx',
        '.txt',
        '.md',
        '.xls',
        '.xlsx',
        '.csv',
        '.ppt',
        '.pptx',
        '.odt',
        '.rtf',
      ]) ||
      mime.contains('pdf') ||
      mime.startsWith('text/')) {
    return FileKind.document;
  }
  if (_hasExt(name, const ['.zip', '.rar', '.7z', '.tar', '.gz'])) {
    return FileKind.archive;
  }
  return FileKind.other;
}

String kindLabel(FileKind kind) {
  return switch (kind) {
    FileKind.image => 'Image',
    FileKind.video => 'Vidéo',
    FileKind.audio => 'Audio',
    FileKind.document => 'Document',
    FileKind.archive => 'Archive',
    FileKind.other => 'Fichier',
  };
}

bool _hasExt(String name, List<String> exts) {
  for (final ext in exts) {
    if (name.endsWith(ext)) return true;
  }
  return false;
}
