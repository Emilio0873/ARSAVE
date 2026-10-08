<?php

declare(strict_types=1);

$password = $argv[1] ?? 'Admin@12345';
$hash = password_hash($password, PASSWORD_DEFAULT);
echo "Password: {$password}\n";
echo "Hash: {$hash}\n\n";
echo "SQL:\nUPDATE users SET password_hash = " . var_export($hash, true) . " WHERE email = 'admin@arsave.local';\n";
