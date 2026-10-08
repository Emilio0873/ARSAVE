<?php

declare(strict_types=1);

$configPath = dirname(__DIR__) . DIRECTORY_SEPARATOR . 'config' . DIRECTORY_SEPARATOR . 'config.php';
$config = require $configPath;

$db = $config['db'];
$options = $db['options'];
$options[PDO::ATTR_EMULATE_PREPARES] = true;
$pdo = new PDO($db['dsn'], $db['user'], $db['pass'], $options);

$sqlFile = dirname(__DIR__, 2) . DIRECTORY_SEPARATOR . 'database' . DIRECTORY_SEPARATOR . 'schema_tables.sql';
if (!is_file($sqlFile)) {
    fwrite(STDERR, "schema_tables.sql introuvable\n");
    exit(1);
}

$sql = file_get_contents($sqlFile);
if ($sql === false) {
    fwrite(STDERR, "Impossible de lire schema_tables.sql\n");
    exit(1);
}

// Exécute le script complet (MySQL multi-statements)
$pdo->exec($sql);

$storage = $config['storage_path'];
if (!is_dir($storage)) {
    mkdir($storage, 0775, true);
}

fwrite(STDOUT, "Migration ARSAVE OK\n");
