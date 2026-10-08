<?php

declare(strict_types=1);

/**
 * Config locale (XAMPP) + production (Railway via variables d'environnement).
 */
$dbHost = getenv('MYSQLHOST') ?: getenv('DB_HOST') ?: '127.0.0.1';
$dbPort = getenv('MYSQLPORT') ?: getenv('DB_PORT') ?: '3306';
$dbName = getenv('MYSQLDATABASE') ?: getenv('DB_NAME') ?: 'arsave';
$dbUser = getenv('MYSQLUSER') ?: getenv('DB_USER') ?: 'root';
$dbPass = getenv('MYSQLPASSWORD') ?: getenv('DB_PASSWORD');
if ($dbPass === false) {
    $dbPass = '';
}

$storage = getenv('STORAGE_PATH') ?: (dirname(__DIR__) . DIRECTORY_SEPARATOR . 'storage' . DIRECTORY_SEPARATOR . 'encrypted');
$cors = getenv('CORS_ORIGIN') ?: '*';
$env = getenv('APP_ENV') ?: 'local';

return [
    'db' => [
        'dsn' => sprintf(
            'mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
            $dbHost,
            $dbPort,
            $dbName
        ),
        'user' => $dbUser,
        'pass' => $dbPass,
        'options' => [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ],
    ],
    'storage_path' => $storage,
    'session_ttl_seconds' => 60 * 60 * 24 * 14,
    'max_upload_bytes' => 500 * 1024 * 1024,
    'cors_origin' => $cors,
    'app_env' => $env,
];
