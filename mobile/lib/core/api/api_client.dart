import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class DownloadResult {
  DownloadResult({
    required this.bytes,
    required this.logicalName,
    required this.mime,
    required this.version,
    required this.checksumSha256,
    required this.nonceB64,
    required this.wrappedKeyB64,
    required this.wrapNonceB64,
  });

  final Uint8List bytes;
  final String logicalName;
  final String mime;
  final int version;
  final String checksumSha256;
  final String nonceB64;
  final String wrappedKeyB64;
  final String wrapNonceB64;
}

class ApiClient {
  ApiClient({required String baseUrl, required this.getToken})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(minutes: 5),
            sendTimeout: const Duration(minutes: 5),
            headers: {'Accept': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final Future<String?> Function() getToken;

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return _postJson('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
    });
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String deviceUid,
    required String deviceName,
  }) async {
    return _postJson('/auth/login', {
      'email': email,
      'password': password,
      'device_uid': deviceUid,
      'device_name': deviceName,
    });
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Ignore network errors on logout
    }
  }

  Future<UserModel> me() async {
    final data = await _getJson('/me');
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<UserModel> updateProfile(String name) async {
    final data = await _putJson('/me', {'name': name});
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> registerDevice({
    required String deviceUid,
    required String deviceName,
  }) async {
    await _postJson('/devices', {
      'device_uid': deviceUid,
      'device_name': deviceName,
    });
  }

  Future<List<FileModel>> listFiles({String status = 'active'}) async {
    final data = await _getJson('/files', query: {'status': status});
    final list = data['files'] as List<dynamic>? ?? [];
    return list
        .map((e) => FileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FileModel> uploadEncrypted({
    required Uint8List encryptedBytes,
    required String logicalName,
    required String mime,
    required String checksumSha256,
    required String nonceB64,
    required String wrappedKeyB64,
    required String wrapNonceB64,
    required String deviceUid,
    required String deviceName,
    int? fileId,
    void Function(int sent, int total)? onProgress,
  }) async {
    final form = FormData.fromMap({
      'blob': MultipartFile.fromBytes(
        encryptedBytes,
        filename: 'encrypted.bin',
      ),
      'logical_name': logicalName,
      'mime': mime,
      'checksum_sha256': checksumSha256,
      'nonce_b64': nonceB64,
      'wrapped_key_b64': wrappedKeyB64,
      'wrap_nonce_b64': wrapNonceB64,
      'device_uid': deviceUid,
      'device_name': deviceName,
      if (fileId != null) 'file_id': fileId,
    });

    try {
      final response = await _dio.post(
        '/files',
        data: form,
        onSendProgress: onProgress,
      );
      return FileModel.fromJson(
        (response.data as Map<String, dynamic>)['file'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<List<FileVersionModel>> listVersions(int fileId) async {
    final data = await _getJson('/files/$fileId/versions');
    final list = data['versions'] as List<dynamic>? ?? [];
    return list
        .map((e) => FileVersionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DownloadResult> download(int fileId, {int? version}) async {
    try {
      final response = await _dio.get<List<int>>(
        '/files/$fileId/download',
        queryParameters: {
          if (version != null) 'version': version,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      final headers = response.headers;
      String header(String name) => headers.value(name) ?? '';

      return DownloadResult(
        bytes: Uint8List.fromList(response.data ?? const []),
        logicalName: Uri.decodeComponent(
          header('x-arsave-logical-name').isEmpty
              ? 'restored.bin'
              : header('x-arsave-logical-name'),
        ),
        mime: header('x-arsave-mime').isEmpty
            ? 'application/octet-stream'
            : header('x-arsave-mime'),
        version: int.tryParse(header('x-arsave-version')) ?? 0,
        checksumSha256: header('x-arsave-checksum'),
        nonceB64: header('x-arsave-nonce'),
        wrappedKeyB64: header('x-arsave-wrapped-key'),
        wrapNonceB64: header('x-arsave-wrap-nonce'),
      );
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<FileModel> trash(int fileId) async {
    final data = await _postJson('/files/$fileId/trash', {});
    return FileModel.fromJson(data['file'] as Map<String, dynamic>);
  }

  Future<FileModel> restoreMeta(int fileId) async {
    final data = await _postJson('/files/$fileId/restore', {});
    return FileModel.fromJson(data['file'] as Map<String, dynamic>);
  }

  Future<void> purge(int fileId) async {
    await _postJson('/files/$fileId/purge', {});
  }

  Future<List<OperationModel>> listOperations({int limit = 50}) async {
    final data = await _getJson('/operations', query: {'limit': limit});
    final list = data['operations'] as List<dynamic>? ?? [];
    return list
        .map((e) => OperationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> adminStats() => _getJson('/admin/stats');

  Future<List<Map<String, dynamic>>> adminUsers() async {
    final data = await _getJson('/admin/users');
    final list = data['users'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> adminUpdateUser(int id, {String? role, String? name}) async {
    await _putJson('/admin/users/$id', {
      if (role != null) 'role': role,
      if (name != null) 'name': name,
    });
  }

  Future<void> adminDeleteUser(int id) async {
    try {
      await _dio.delete('/admin/users/$id');
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: query);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post(path, data: body);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<Map<String, dynamic>> _putJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.put(path, data: body);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  ApiException _mapDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return ApiException(
        data['error'].toString(),
        statusCode: e.response?.statusCode,
      );
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return ApiException('Pas de connexion au serveur.');
    }
    return ApiException(
      e.message ?? 'Erreur réseau',
      statusCode: e.response?.statusCode,
    );
  }
}
