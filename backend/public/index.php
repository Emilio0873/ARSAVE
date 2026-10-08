<?php

declare(strict_types=1);

// Accepte n'importe quel fichier jusqu'à 500 Mo (local / XAMPP)
@ini_set('upload_max_filesize', '500M');
@ini_set('post_max_size', '512M');
@ini_set('max_execution_time', '600');
@ini_set('max_input_time', '600');
@ini_set('memory_limit', '512M');

spl_autoload_register(static function (string $class): void {
    $prefix = 'Arsave\\';
    if (!str_starts_with($class, $prefix)) {
        return;
    }
    $relative = substr($class, strlen($prefix));
    $path = dirname(__DIR__) . DIRECTORY_SEPARATOR . 'src' . DIRECTORY_SEPARATOR . str_replace('\\', DIRECTORY_SEPARATOR, $relative) . '.php';
    if (is_file($path)) {
        require_once $path;
    }
});

$configPath = dirname(__DIR__) . DIRECTORY_SEPARATOR . 'config' . DIRECTORY_SEPARATOR . 'config.php';
if (!is_file($configPath)) {
    http_response_code(500);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'config.php manquant. Copiez config.example.php.']);
    exit;
}

$config = require $configPath;

use Arsave\App;
use Arsave\Request;

$app = new App($config);
$app->run(Request::fromGlobals());
