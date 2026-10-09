<?php

declare(strict_types=1);

namespace Arsave;

final class FileController
{
    public function __construct(
        private FileService $files,
        private AuthService $auth,
        private OperationService $operations,
    ) {
    }

    public function index(Request $req, array $user): void
    {
        $status = (string) ($req->query['status'] ?? 'active');
        Response::json(['files' => $this->files->listFiles((int) $user['id'], $status)]);
    }

    public function upload(Request $req, array $user): void
    {
        if (!isset($req->files['blob']) || !is_array($req->files['blob'])) {
            Response::error('Fichier blob manquant (champ multipart "blob").', 400);
            return;
        }
        $upload = $req->files['blob'];
        if (($upload['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
            Response::error('Erreur d’upload (code ' . (int) ($upload['error'] ?? -1) . ').', 400);
            return;
        }

        $deviceId = null;
        $deviceUid = $req->input('device_uid');
        if ($deviceUid) {
            $deviceId = $this->auth->upsertDevice(
                (int) $user['id'],
                (string) $deviceUid,
                (string) ($req->input('device_name') ?: 'Android')
            );
        } elseif (!empty($user['device_id'])) {
            $deviceId = (int) $user['device_id'];
        }

        $fileIdRaw = $req->input('file_id');
        $meta = [
            'logical_name' => (string) $req->input('logical_name', $upload['name'] ?? 'file.bin'),
            'mime' => (string) $req->input('mime', 'application/octet-stream'),
            'checksum_sha256' => (string) $req->input('checksum_sha256', ''),
            'nonce_b64' => (string) $req->input('nonce_b64', ''),
            'wrapped_key_b64' => (string) $req->input('wrapped_key_b64', ''),
            'wrap_nonce_b64' => (string) $req->input('wrap_nonce_b64', ''),
            'file_id' => $fileIdRaw !== null && $fileIdRaw !== '' ? (int) $fileIdRaw : null,
            'device_id' => $deviceId,
            'tmp_path' => $upload['tmp_name'],
            'size' => (int) ($upload['size'] ?? 0),
        ];

        foreach (['checksum_sha256', 'nonce_b64', 'wrapped_key_b64', 'wrap_nonce_b64'] as $required) {
            if ($meta[$required] === '') {
                Response::error("Champ requis manquant: {$required}", 400);
                return;
            }
        }

        $result = $this->files->upload((int) $user['id'], $meta);
        Response::json(['file' => $result], 201);
    }

    public function versions(Request $req, array $user, array $params): void
    {
        $fileId = (int) $params['id'];
        Response::json([
            'file_id' => $fileId,
            'versions' => $this->files->listVersions((int) $user['id'], $fileId),
        ]);
    }

    public function download(Request $req, array $user, array $params): void
    {
        $fileId = (int) $params['id'];
        $version = isset($req->query['version']) ? (int) $req->query['version'] : null;
        $resolved = $this->files->resolveDownload((int) $user['id'], $fileId, $version);
        $v = $resolved['version'];
        $f = $resolved['file'];

        $this->operations->log((int) $user['id'], 'download', 'success', 'Téléchargement version ' . $v['version_number'], $fileId);

        $meta = [
            'logical_name' => $f['logical_name'],
            'mime' => $f['mime'],
            'version' => (int) $v['version_number'],
            'checksum_sha256' => $v['checksum_sha256'],
            'nonce_b64' => $v['nonce_b64'],
            'wrapped_key_b64' => $v['wrapped_key_b64'],
            'wrap_nonce_b64' => $v['wrap_nonce_b64'],
        ];

        header('Content-Type: application/octet-stream');
        header('Content-Length: ' . (string) filesize($resolved['absolute_path']));
        header('X-Arsave-Logical-Name: ' . rawurlencode($f['logical_name']));
        header('X-Arsave-Mime: ' . $f['mime']);
        header('X-Arsave-Version: ' . (string) $v['version_number']);
        header('X-Arsave-Checksum: ' . $v['checksum_sha256']);
        header('X-Arsave-Nonce: ' . $v['nonce_b64']);
        header('X-Arsave-Wrapped-Key: ' . $v['wrapped_key_b64']);
        header('X-Arsave-Wrap-Nonce: ' . $v['wrap_nonce_b64']);
        header('X-Arsave-Meta: ' . rtrim(strtr(base64_encode(json_encode($meta, JSON_UNESCAPED_UNICODE)), '+/', '-_'), '='));
        header('Content-Disposition: attachment; filename="encrypted.bin"');
        readfile($resolved['absolute_path']);
    }

    public function trash(Request $req, array $user, array $params): void
    {
        Response::json(['file' => $this->files->trash((int) $user['id'], (int) $params['id'])]);
    }

    public function restore(Request $req, array $user, array $params): void
    {
        Response::json(['file' => $this->files->restoreFromTrash((int) $user['id'], (int) $params['id'])]);
    }

    public function purge(Request $req, array $user, array $params): void
    {
        $this->files->purge((int) $user['id'], (int) $params['id']);
        Response::json(['message' => 'Fichier définitivement supprimé.']);
    }

    public function show(Request $req, array $user, array $params): void
    {
        Response::json(['file' => $this->files->fileDetail((int) $user['id'], (int) $params['id'])]);
    }
}
