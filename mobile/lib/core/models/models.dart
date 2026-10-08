class UserModel {
  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.kdfSaltB64,
  });

  final int id;
  final String email;
  final String name;
  final String role;
  final String kdfSaltB64;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'user',
      kdfSaltB64: json['kdf_salt_b64'] as String? ?? '',
    );
  }
}

class FileModel {
  FileModel({
    required this.id,
    required this.logicalName,
    required this.mime,
    required this.status,
    this.currentVersion,
    this.sizeBytes,
    this.checksumSha256,
    this.trashedAt,
    this.updatedAt,
  });

  final int id;
  final String logicalName;
  final String mime;
  final String status;
  final int? currentVersion;
  final int? sizeBytes;
  final String? checksumSha256;
  final String? trashedAt;
  final String? updatedAt;

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'] as int,
      logicalName: json['logical_name'] as String,
      mime: json['mime'] as String? ?? 'application/octet-stream',
      status: json['status'] as String? ?? 'active',
      currentVersion: json['current_version'] as int?,
      sizeBytes: json['size_bytes'] as int?,
      checksumSha256: json['checksum_sha256'] as String?,
      trashedAt: json['trashed_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class FileVersionModel {
  FileVersionModel({
    required this.id,
    required this.versionNumber,
    required this.sizeBytes,
    required this.checksumSha256,
    required this.nonceB64,
    required this.wrappedKeyB64,
    required this.wrapNonceB64,
    required this.createdAt,
  });

  final int id;
  final int versionNumber;
  final int sizeBytes;
  final String checksumSha256;
  final String nonceB64;
  final String wrappedKeyB64;
  final String wrapNonceB64;
  final String createdAt;

  factory FileVersionModel.fromJson(Map<String, dynamic> json) {
    return FileVersionModel(
      id: json['id'] as int,
      versionNumber: json['version_number'] as int,
      sizeBytes: json['size_bytes'] as int,
      checksumSha256: json['checksum_sha256'] as String,
      nonceB64: json['nonce_b64'] as String,
      wrappedKeyB64: json['wrapped_key_b64'] as String,
      wrapNonceB64: json['wrap_nonce_b64'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

class OperationModel {
  OperationModel({
    required this.id,
    required this.type,
    required this.status,
    this.fileId,
    this.message,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String status;
  final int? fileId;
  final String? message;
  final String createdAt;

  factory OperationModel.fromJson(Map<String, dynamic> json) {
    return OperationModel(
      id: json['id'] as int,
      type: json['type'] as String,
      status: json['status'] as String,
      fileId: json['file_id'] as int?,
      message: json['message'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}
