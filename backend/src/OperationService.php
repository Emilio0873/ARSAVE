<?php

declare(strict_types=1);

namespace Arsave;

use PDO;

final class OperationService
{
    public function __construct(private PDO $db)
    {
    }

    public function log(int $userId, string $type, string $status, ?string $message = null, ?int $fileId = null): void
    {
        $stmt = $this->db->prepare(
            'INSERT INTO operations (user_id, file_id, type, status, message) VALUES (?, ?, ?, ?, ?)'
        );
        $stmt->execute([$userId, $fileId, $type, $status, $message]);
    }

    public function listForUser(int $userId, int $limit = 50): array
    {
        $limit = max(1, min(200, $limit));
        $stmt = $this->db->prepare(
            'SELECT id, file_id, type, status, message, created_at
             FROM operations
             WHERE user_id = ?
             ORDER BY created_at DESC, id DESC
             LIMIT ' . $limit
        );
        $stmt->execute([$userId]);
        return array_map(static function (array $row): array {
            return [
                'id' => (int) $row['id'],
                'file_id' => $row['file_id'] !== null ? (int) $row['file_id'] : null,
                'type' => $row['type'],
                'status' => $row['status'],
                'message' => $row['message'],
                'created_at' => $row['created_at'],
            ];
        }, $stmt->fetchAll());
    }
}
