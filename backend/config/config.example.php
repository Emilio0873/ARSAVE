<?php

declare(strict_types=1);

/**
 * Copiez vers config.php pour le local, ou utilisez les variables d'environnement
 * (MYSQLHOST, MYSQLPORT, MYSQLUSER, MYSQLPASSWORD, MYSQLDATABASE, STORAGE_PATH, CORS_ORIGIN).
 */
return [
    'db' => [
        'dsn' => 'mysql:host=127.0.0.1;port=3306;dbname=arsave;charset=utf8mb4',
        'user' => 'root',
        'pass' => '',
        'options' => [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ],
    ],
    'storage_path' => dirname(__DIR__) . DIRECTORY_SEPARATOR . 'storage' . DIRECTORY_SEPARATOR . 'encrypted',
    'session_ttl_seconds' => 60 * 60 * 24 * 14,
    'max_upload_bytes' => 500 * 1024 * 1024,
    'cors_origin' => '*',
    'app_env' => 'local',
];
