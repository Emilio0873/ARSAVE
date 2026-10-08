<?php

declare(strict_types=1);

namespace Arsave;

use PDO;

final class Database
{
    private static ?PDO $pdo = null;

    public static function connection(array $config): PDO
    {
        if (self::$pdo === null) {
            self::$pdo = new PDO(
                $config['dsn'],
                $config['user'],
                $config['pass'],
                $config['options'] ?? []
            );
        }

        return self::$pdo;
    }
}
