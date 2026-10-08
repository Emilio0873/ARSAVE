<?php

declare(strict_types=1);

namespace Arsave;

use PDO;

final class AdminController
{
    public function __construct(
        private FileService $files,
        private AuthService $auth,
        private PDO $db,
        private array $config,
    ) {
    }

    private function requireAdmin(array $user): void
    {
        if (($user['role'] ?? '') !== 'admin') {
            throw new \RuntimeException('Accès administrateur requis.', 403);
        }
    }

    public function stats(Request $req, array $user): void
    {
        $this->requireAdmin($user);
        Response::json(['stats' => $this->files->adminStats()]);
    }

    public function listUsers(Request $req, array $user): void
    {
        $this->requireAdmin($user);
        Response::json(['users' => $this->auth->adminListUsers()]);
    }

    public function updateUser(Request $req, array $user, array $params): void
    {
        $this->requireAdmin($user);
        $targetId = (int) ($params['id'] ?? 0);
        $role = $req->input('role');
        $name = $req->input('name');

        $updated = $this->auth->adminUpdateUser(
            $targetId,
            (int) $user['id'],
            $role !== null ? (string) $role : null,
            $name !== null ? (string) $name : null,
        );
        Response::json(['user' => $updated]);
    }

    public function deleteUser(Request $req, array $user, array $params): void
    {
        $this->requireAdmin($user);
        $targetId = (int) ($params['id'] ?? 0);
        if ($targetId === (int) $user['id']) {
            throw new \RuntimeException('Vous ne pouvez pas supprimer votre propre compte admin.', 400);
        }

        // Remove ciphertext blobs before FK cascade
        $this->files->adminPurgeUserStorage($targetId);
        $this->auth->adminDeleteUser($targetId, (int) $user['id']);
        Response::json(['message' => 'Utilisateur supprimé.']);
    }
}
