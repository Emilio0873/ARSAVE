<?php

declare(strict_types=1);

// Router for: php -S 0.0.0.0:8080 router.php
$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$file = __DIR__ . $path;

if ($path !== '/') {
    if (is_file($file)) {
        return false;
    }
    if (is_dir($file)) {
        $index = rtrim($file, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . 'index.html';
        if (is_file($index)) {
            header('Content-Type: text/html; charset=utf-8');
            readfile($index);
            return true;
        }
    }
}

require __DIR__ . '/index.php';
