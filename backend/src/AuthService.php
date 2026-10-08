<?php

declare(strict_types=1);

namespace Arsave;

use PDO;

final class AuthService
{
    public function __construct(
        private PDO $db,
        private array $config,
    ) {
    }

    public function register(string $email, string $password, string $name): array
    {
        $email = strtolower(trim($email));
        $name = trim($name);

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new \InvalidArgumentException('Email invalide.');
        }
        if (strlen($password) < 8) {
            throw new \InvalidArgumentException('Le mot de passe doit contenir au moins 8 caractères.');
        }
        if ($name === '') {
            throw new \InvalidArgumentException('Le nom est requis.');
        }

        $stmt = $this->db->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
        $stmt->execute([$email]);
        if ($stmt->fetch()) {
            throw new \RuntimeException('Cet email est déjà utilisé.', 409);
        }

        $salt = random_bytes(32);
        $hash = password_hash($password, PASSWORD_DEFAULT);
        if ($hash === false) {
            throw new \RuntimeException('Impossible de hasher le mot de passe.');
        }

        $stmt = $this->db->prepare(
            'INSERT INTO users (email, password_hash, name, role, kdf_salt) VALUES (?, ?, ?, ?, ?)'
        );
        $stmt->execute([$email, $hash, $name, 'user', $salt]);
        $userId = (int) $this->db->lastInsertId();

        return $this->userPublic($this->findUserById($userId));
    }

    public function login(string $email, string $password, ?string $deviceUid = null, ?string $deviceName = null): array
    {
        $email = strtolower(trim($email));
        $stmt = $this->db->prepare('SELECT * FROM users WHERE email = ? LIMIT 1');
        $stmt->execute([$email]);
        $user = $stmt->fetch();
        if (!$user || !password_verify($password, $user['password_hash'])) {
            throw new \RuntimeException('Identifiants invalides.', 401);
        }

        $deviceId = null;
        if ($deviceUid !== null && $deviceUid !== '') {
            $deviceId = $this->upsertDevice((int) $user['id'], $deviceUid, $deviceName ?: 'Android');
        }

        $token = bin2hex(random_bytes(32));
        $tokenHash = hash('sha256', $token);
        $ttl = (int) ($this->config['session_ttl_seconds'] ?? 1209600);
        $expires = (new \DateTimeImmutable("+{$ttl} seconds"))->format('Y-m-d H:i:s');

        $stmt = $this->db->prepare(
            'INSERT INTO sessions (user_id, device_id, token_hash, expires_at) VALUES (?, ?, ?, ?)'
        );
        $stmt->execute([(int) $user['id'], $deviceId, $tokenHash, $expires]);

        return [
            'token' => $token,
            'expires_at' => $expires,
            'user' => $this->userPublic($user),
            'kdf_salt_b64' => base64_encode($user['kdf_salt']),
        ];
    }

    public function logout(string $token): void
    {
        $stmt = $this->db->prepare('DELETE FROM sessions WHERE token_hash = ?');
        $stmt->execute([hash('sha256', $token)]);
    }

    public function authenticate(?string $token): array
    {
        if ($token === null || $token === '') {
            throw new \RuntimeException('Non authentifié.', 401);
        }

        $stmt = $this->db->prepare(
            'SELECT s.id AS session_id, s.device_id, s.expires_at, u.*
             FROM sessions s
             INNER JOIN users u ON u.id = s.user_id
             WHERE s.token_hash = ?
             LIMIT 1'
        );
        $stmt->execute([hash('sha256', $token)]);
        $row = $stmt->fetch();
        if (!$row) {
            throw new \RuntimeException('Session invalide.', 401);
        }
        if (strtotime($row['expires_at']) < time()) {
            $this->db->prepare('DELETE FROM sessions WHERE id = ?')->execute([(int) $row['session_id']]);
            throw new \RuntimeException('Session expirée.', 401);
        }

        return $row;
    }

    public function updateProfile(int $userId, string $name): array
    {
        $name = trim($name);
        if ($name === '') {
            throw new \InvalidArgumentException('Le nom est requis.');
        }
        $stmt = $this->db->prepare('UPDATE users SET name = ? WHERE id = ?');
        $stmt->execute([$name, $userId]);
        return $this->userPublic($this->findUserById($userId));
    }

    public function requestPasswordReset(string $email): array
    {
        $email = strtolower(trim($email));
        $stmt = $this->db->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
        $stmt->execute([$email]);
        $user = $stmt->fetch();

        // Always return success to avoid email enumeration
        if (!$user) {
            return ['message' => 'Si le compte existe, un jeton de réinitialisation a été créé.'];
        }

        $token = bin2hex(random_bytes(32));
        $expires = (new \DateTimeImmutable('+1 hour'))->format('Y-m-d H:i:s');
        $stmt = $this->db->prepare(
            'INSERT INTO password_resets (user_id, token_hash, expires_at) VALUES (?, ?, ?)'
        );
        $stmt->execute([(int) $user['id'], hash('sha256', $token), $expires]);

        $payload = ['message' => 'Si le compte existe, un jeton de réinitialisation a été créé.'];
        if (($this->config['app_env'] ?? 'local') === 'local') {
            $payload['debug_reset_token'] = $token;
        }
        return $payload;
    }

    public function resetPassword(string $token, string $newPassword): void
    {
        if (strlen($newPassword) < 8) {
            throw new \InvalidArgumentException('Le mot de passe doit contenir au moins 8 caractères.');
        }

        $stmt = $this->db->prepare(
            'SELECT * FROM password_resets WHERE token_hash = ? AND used_at IS NULL LIMIT 1'
        );
        $stmt->execute([hash('sha256', $token)]);
        $reset = $stmt->fetch();
        if (!$reset || strtotime($reset['expires_at']) < time()) {
            throw new \RuntimeException('Jeton de réinitialisation invalide ou expiré.', 400);
        }

        $hash = password_hash($newPassword, PASSWORD_DEFAULT);
        $this->db->beginTransaction();
        try {
            // New master key salt — previous wrapped keys become unusable (by design when password changes)
            $newSalt = random_bytes(32);
            $this->db->prepare('UPDATE users SET password_hash = ?, kdf_salt = ? WHERE id = ?')
                ->execute([$hash, $newSalt, (int) $reset['user_id']]);
            $this->db->prepare('UPDATE password_resets SET used_at = NOW() WHERE id = ?')
                ->execute([(int) $reset['id']]);
            $this->db->prepare('DELETE FROM sessions WHERE user_id = ?')
                ->execute([(int) $reset['user_id']]);
            $this->db->commit();
        } catch (\Throwable $e) {
            $this->db->rollBack();
            throw $e;
        }
    }

    public function upsertDevice(int $userId, string $deviceUid, string $deviceName): int
    {
        $stmt = $this->db->prepare(
            'SELECT id FROM devices WHERE user_id = ? AND device_uid = ? LIMIT 1'
        );
        $stmt->execute([$userId, $deviceUid]);
        $existing = $stmt->fetch();
        if ($existing) {
            $this->db->prepare(
                'UPDATE devices SET device_name = ?, last_seen_at = NOW() WHERE id = ?'
            )->execute([$deviceName, (int) $existing['id']]);
            return (int) $existing['id'];
        }

        $this->db->prepare(
            'INSERT INTO devices (user_id, device_name, device_uid, last_seen_at) VALUES (?, ?, ?, NOW())'
        )->execute([$userId, $deviceName, $deviceUid]);
        return (int) $this->db->lastInsertId();
    }

    private function findUserById(int $id): array
    {
        $stmt = $this->db->prepare('SELECT * FROM users WHERE id = ? LIMIT 1');
        $stmt->execute([$id]);
        $user = $stmt->fetch();
        if (!$user) {
            throw new \RuntimeException('Utilisateur introuvable.', 404);
        }
        return $user;
    }

    public function userPublic(array $user): array
    {
        return [
            'id' => (int) $user['id'],
            'email' => $user['email'],
            'name' => $user['name'],
            'role' => $user['role'],
            'kdf_salt_b64' => base64_encode($user['kdf_salt']),
            'created_at' => $user['created_at'],
        ];
    }

    public function adminListUsers(): array
    {
        $stmt = $this->db->query(
            'SELECT u.id, u.email, u.name, u.role, u.created_at, u.updated_at,
                    (SELECT COUNT(*) FROM files f WHERE f.user_id = u.id AND f.status != \'deleted\') AS files_count
             FROM users u
             ORDER BY u.created_at DESC'
        );
        $rows = $stmt->fetchAll();
        $out = [];
        foreach ($rows as $row) {
            $out[] = [
                'id' => (int) $row['id'],
                'email' => $row['email'],
                'name' => $row['name'],
                'role' => $row['role'],
                'created_at' => $row['created_at'],
                'updated_at' => $row['updated_at'],
                'files_count' => (int) $row['files_count'],
            ];
        }
        return $out;
    }

    public function adminUpdateUser(
        int $targetId,
        int $actorId,
        ?string $role,
        ?string $name,
    ): array {
        $user = $this->findUserById($targetId);

        if ($role !== null) {
            $role = strtolower(trim($role));
            if (!in_array($role, ['user', 'admin'], true)) {
                throw new \InvalidArgumentException('Rôle invalide (user|admin).');
            }
            if ($targetId === $actorId && $role !== 'admin') {
                throw new \RuntimeException('Vous ne pouvez pas retirer votre propre rôle admin.', 400);
            }
            $admins = (int) $this->db->query(
                "SELECT COUNT(*) FROM users WHERE role = 'admin'"
            )->fetchColumn();
            if ($user['role'] === 'admin' && $role !== 'admin' && $admins <= 1) {
                throw new \RuntimeException('Impossible de retirer le dernier administrateur.', 400);
            }
        }

        if ($name !== null) {
            $name = trim($name);
            if ($name === '') {
                throw new \InvalidArgumentException('Le nom est requis.');
            }
        }

        $newRole = $role ?? $user['role'];
        $newName = $name ?? $user['name'];
        $stmt = $this->db->prepare('UPDATE users SET role = ?, name = ? WHERE id = ?');
        $stmt->execute([$newRole, $newName, $targetId]);

        return [
            'id' => $targetId,
            'email' => $user['email'],
            'name' => $newName,
            'role' => $newRole,
            'created_at' => $user['created_at'],
        ];
    }

    public function adminDeleteUser(int $targetId, int $actorId): void
    {
        if ($targetId === $actorId) {
            throw new \RuntimeException('Vous ne pouvez pas supprimer votre propre compte.', 400);
        }
        $user = $this->findUserById($targetId);
        if ($user['role'] === 'admin') {
            $admins = (int) $this->db->query(
                "SELECT COUNT(*) FROM users WHERE role = 'admin'"
            )->fetchColumn();
            if ($admins <= 1) {
                throw new \RuntimeException('Impossible de supprimer le dernier administrateur.', 400);
            }
        }

        $stmt = $this->db->prepare('DELETE FROM users WHERE id = ?');
        $stmt->execute([$targetId]);
    }
}
