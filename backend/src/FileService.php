<?php

declare(strict_types=1);

namespace Arsave;

use PDO;

final class FileService
{
    public function __construct(
        private PDO $db,
        private array $config,
        private OperationService $operations,
    ) {
    }

    public function listFiles(int $userId, string $status = 'active'): array
    {
        $allowed = ['active', 'trashed', 'deleted'];
        if (!in_array($status, $allowed, true)) {
            throw new \InvalidArgumentException('Statut invalide.');
        }

        $stmt = $this->db->prepare(
            'SELECT f.id, f.logical_name, f.mime, f.status, f.current_version_id, f.trashed_at, f.created_at, f.updated_at,
                    v.version_number, v.size_bytes, v.checksum_sha256, v.created_at AS version_created_at
             FROM files f
             LEFT JOIN file_versions v ON v.id = f.current_version_id
             WHERE f.user_id = ? AND f.status = ?
             ORDER BY f.updated_at DESC'
        );
        $stmt->execute([$userId, $status]);

        return array_map(static function (array $row): array {
            return [
                'id' => (int) $row['id'],
                'logical_name' => $row['logical_name'],
                'mime' => $row['mime'],
                'status' => $row['status'],
                'current_version_id' => $row['current_version_id'] !== null ? (int) $row['current_version_id'] : null,
                'current_version' => $row['version_number'] !== null ? (int) $row['version_number'] : null,
                'size_bytes' => $row['size_bytes'] !== null ? (int) $row['size_bytes'] : null,
                'checksum_sha256' => $row['checksum_sha256'],
                'trashed_at' => $row['trashed_at'],
                'created_at' => $row['created_at'],
                'updated_at' => $row['updated_at'],
                'version_created_at' => $row['version_created_at'],
            ];
        }, $stmt->fetchAll());
    }

    public function getOwnedFile(int $userId, int $fileId): array
    {
        $stmt = $this->db->prepare('SELECT * FROM files WHERE id = ? AND user_id = ? LIMIT 1');
        $stmt->execute([$fileId, $userId]);
        $file = $stmt->fetch();
        if (!$file) {
            throw new \RuntimeException('Fichier introuvable.', 404);
        }
        return $file;
    }

    /**
     * Upload encrypted blob + metadata. Creates a new file or a new version of an existing file.
     *
     * @param array{
     *   logical_name: string,
     *   mime: string,
     *   checksum_sha256: string,
     *   nonce_b64: string,
     *   wrapped_key_b64: string,
     *   wrap_nonce_b64: string,
     *   file_id?: int|null,
     *   device_id?: int|null,
     *   tmp_path: string,
     *   size: int
     * } $meta
     */
    public function upload(int $userId, array $meta): array
    {
        $max = (int) ($this->config['max_upload_bytes'] ?? 104857600);
        if ($meta['size'] <= 0 || $meta['size'] > $max) {
            throw new \InvalidArgumentException('Taille de fichier invalide ou trop grande.');
        }
        if (!preg_match('/^[a-f0-9]{64}$/i', $meta['checksum_sha256'])) {
            throw new \InvalidArgumentException('Checksum invalide.');
        }

        $actualHash = hash_file('sha256', $meta['tmp_path']);
        if ($actualHash === false || strcasecmp($actualHash, $meta['checksum_sha256']) !== 0) {
            throw new \InvalidArgumentException('Le checksum ne correspond pas au contenu uploadé.');
        }

        $storageRoot = $this->config['storage_path'];
        if (!is_dir($storageRoot) && !mkdir($storageRoot, 0750, true) && !is_dir($storageRoot)) {
            throw new \RuntimeException('Impossible de créer le dossier de stockage.');
        }

        $userDir = $storageRoot . DIRECTORY_SEPARATOR . $userId;
        if (!is_dir($userDir) && !mkdir($userDir, 0750, true) && !is_dir($userDir)) {
            throw new \RuntimeException('Impossible de créer le dossier utilisateur.');
        }

        $this->db->beginTransaction();
        try {
            $fileId = $meta['file_id'] ?? null;
            if ($fileId) {
                $file = $this->getOwnedFile($userId, (int) $fileId);
                if ($file['status'] === 'deleted') {
                    throw new \RuntimeException('Fichier définitivement supprimé.', 410);
                }
                $stmt = $this->db->prepare(
                    'SELECT COALESCE(MAX(version_number), 0) AS max_v FROM file_versions WHERE file_id = ?'
                );
                $stmt->execute([(int) $fileId]);
                $versionNumber = (int) $stmt->fetchColumn() + 1;
            } else {
                $stmt = $this->db->prepare(
                    'INSERT INTO files (user_id, logical_name, mime, status) VALUES (?, ?, ?, ?)'
                );
                $stmt->execute([$userId, $meta['logical_name'], $meta['mime'], 'active']);
                $fileId = (int) $this->db->lastInsertId();
                $versionNumber = 1;
            }

            $relative = $userId . '/' . $fileId . '_v' . $versionNumber . '_' . bin2hex(random_bytes(8)) . '.bin';
            $absolute = $storageRoot . DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $relative);

            if (!move_uploaded_file($meta['tmp_path'], $absolute) && !rename($meta['tmp_path'], $absolute)) {
                if (!copy($meta['tmp_path'], $absolute)) {
                    throw new \RuntimeException('Échec du stockage du fichier.');
                }
                @unlink($meta['tmp_path']);
            }

            $stmt = $this->db->prepare(
                'INSERT INTO file_versions
                 (file_id, device_id, version_number, size_bytes, storage_path, checksum_sha256, nonce_b64, wrapped_key_b64, wrap_nonce_b64)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $stmt->execute([
                $fileId,
                $meta['device_id'] ?? null,
                $versionNumber,
                $meta['size'],
                $relative,
                strtolower($meta['checksum_sha256']),
                $meta['nonce_b64'],
                $meta['wrapped_key_b64'],
                $meta['wrap_nonce_b64'],
            ]);
            $versionId = (int) $this->db->lastInsertId();

            $this->db->prepare(
                'UPDATE files SET logical_name = ?, mime = ?, status = ?, current_version_id = ?, trashed_at = NULL, updated_at = NOW() WHERE id = ?'
            )->execute([
                $meta['logical_name'],
                $meta['mime'],
                'active',
                $versionId,
                $fileId,
            ]);

            $this->operations->log($userId, 'backup', 'success', 'Version ' . $versionNumber . ' sauvegardée', $fileId);
            $this->db->commit();

            return $this->fileDetail($userId, $fileId);
        } catch (\Throwable $e) {
            $this->db->rollBack();
            $this->operations->log($userId, 'backup', 'failed', $e->getMessage(), $meta['file_id'] ?? null);
            throw $e;
        }
    }

    public function listVersions(int $userId, int $fileId): array
    {
        $this->getOwnedFile($userId, $fileId);
        $stmt = $this->db->prepare(
            'SELECT id, version_number, size_bytes, checksum_sha256, nonce_b64, wrapped_key_b64, wrap_nonce_b64, device_id, created_at
             FROM file_versions
             WHERE file_id = ?
             ORDER BY version_number DESC'
        );
        $stmt->execute([$fileId]);
        return array_map(static function (array $row): array {
            return [
                'id' => (int) $row['id'],
                'version_number' => (int) $row['version_number'],
                'size_bytes' => (int) $row['size_bytes'],
                'checksum_sha256' => $row['checksum_sha256'],
                'nonce_b64' => $row['nonce_b64'],
                'wrapped_key_b64' => $row['wrapped_key_b64'],
                'wrap_nonce_b64' => $row['wrap_nonce_b64'],
                'device_id' => $row['device_id'] !== null ? (int) $row['device_id'] : null,
                'created_at' => $row['created_at'],
            ];
        }, $stmt->fetchAll());
    }

    public function resolveDownload(int $userId, int $fileId, ?int $versionNumber = null): array
    {
        $file = $this->getOwnedFile($userId, $fileId);
        if ($file['status'] === 'deleted') {
            throw new \RuntimeException('Fichier définitivement supprimé.', 410);
        }

        if ($versionNumber !== null) {
            $stmt = $this->db->prepare(
                'SELECT * FROM file_versions WHERE file_id = ? AND version_number = ? LIMIT 1'
            );
            $stmt->execute([$fileId, $versionNumber]);
        } else {
            if ($file['current_version_id'] === null) {
                throw new \RuntimeException('Aucune version disponible.', 404);
            }
            $stmt = $this->db->prepare('SELECT * FROM file_versions WHERE id = ? LIMIT 1');
            $stmt->execute([(int) $file['current_version_id']]);
        }

        $version = $stmt->fetch();
        if (!$version) {
            throw new \RuntimeException('Version introuvable.', 404);
        }

        $absolute = $this->config['storage_path'] . DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $version['storage_path']);
        if (!is_file($absolute)) {
            throw new \RuntimeException('Blob manquant sur le serveur.', 404);
        }

        return [
            'file' => $file,
            'version' => $version,
            'absolute_path' => $absolute,
        ];
    }

    public function trash(int $userId, int $fileId): array
    {
        $file = $this->getOwnedFile($userId, $fileId);
        if ($file['status'] !== 'active') {
            throw new \RuntimeException('Le fichier n’est pas actif.', 400);
        }
        $this->db->prepare('UPDATE files SET status = ?, trashed_at = NOW() WHERE id = ? AND user_id = ?')
            ->execute(['trashed', $fileId, $userId]);
        $this->operations->log($userId, 'trash', 'success', 'Fichier mis en corbeille', $fileId);
        return $this->fileDetail($userId, $fileId);
    }

    public function restoreFromTrash(int $userId, int $fileId): array
    {
        $file = $this->getOwnedFile($userId, $fileId);
        if ($file['status'] !== 'trashed') {
            throw new \RuntimeException('Le fichier n’est pas en corbeille.', 400);
        }
        $this->db->prepare('UPDATE files SET status = ?, trashed_at = NULL WHERE id = ? AND user_id = ?')
            ->execute(['active', $fileId, $userId]);
        $this->operations->log($userId, 'restore_meta', 'success', 'Fichier restauré depuis la corbeille', $fileId);
        return $this->fileDetail($userId, $fileId);
    }

    public function purge(int $userId, int $fileId): void
    {
        $file = $this->getOwnedFile($userId, $fileId);
        if ($file['status'] === 'deleted') {
            return;
        }

        $stmt = $this->db->prepare('SELECT storage_path FROM file_versions WHERE file_id = ?');
        $stmt->execute([$fileId]);
        $paths = $stmt->fetchAll();

        $this->db->beginTransaction();
        try {
            $this->db->prepare('UPDATE files SET current_version_id = NULL WHERE id = ?')->execute([$fileId]);
            $this->db->prepare('DELETE FROM file_versions WHERE file_id = ?')->execute([$fileId]);
            $this->db->prepare('UPDATE files SET status = ?, trashed_at = NOW() WHERE id = ?')
                ->execute(['deleted', $fileId]);
            $this->operations->log($userId, 'purge', 'success', 'Fichier définitivement supprimé', $fileId);
            $this->db->commit();
        } catch (\Throwable $e) {
            $this->db->rollBack();
            throw $e;
        }

        foreach ($paths as $row) {
            $absolute = $this->config['storage_path'] . DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $row['storage_path']);
            if (is_file($absolute)) {
                @unlink($absolute);
            }
        }
    }

    public function fileDetail(int $userId, int $fileId): array
    {
        $list = $this->listFiles($userId, 'active');
        foreach ($list as $item) {
            if ($item['id'] === $fileId) {
                return $item;
            }
        }
        $trashed = $this->listFiles($userId, 'trashed');
        foreach ($trashed as $item) {
            if ($item['id'] === $fileId) {
                return $item;
            }
        }
        $file = $this->getOwnedFile($userId, $fileId);
        return [
            'id' => (int) $file['id'],
            'logical_name' => $file['logical_name'],
            'mime' => $file['mime'],
            'status' => $file['status'],
            'current_version_id' => $file['current_version_id'] !== null ? (int) $file['current_version_id'] : null,
            'trashed_at' => $file['trashed_at'],
            'created_at' => $file['created_at'],
            'updated_at' => $file['updated_at'],
        ];
    }

    public function adminStats(): array
    {
        $users = (int) $this->db->query('SELECT COUNT(*) FROM users')->fetchColumn();
        $files = (int) $this->db->query("SELECT COUNT(*) FROM files WHERE status != 'deleted'")->fetchColumn();
        $bytes = (int) $this->db->query('SELECT COALESCE(SUM(size_bytes), 0) FROM file_versions')->fetchColumn();
        return [
            'users' => $users,
            'files' => $files,
            'ciphertext_bytes' => $bytes,
        ];
    }

    public function adminPurgeUserStorage(int $userId): void
    {
        $stmt = $this->db->prepare(
            'SELECT fv.storage_path
             FROM file_versions fv
             INNER JOIN files f ON f.id = fv.file_id
             WHERE f.user_id = ?'
        );
        $stmt->execute([$userId]);
        foreach ($stmt->fetchAll() as $row) {
            $absolute = $this->config['storage_path'] . DIRECTORY_SEPARATOR
                . str_replace('/', DIRECTORY_SEPARATOR, $row['storage_path']);
            if (is_file($absolute)) {
                @unlink($absolute);
            }
        }
    }
}
