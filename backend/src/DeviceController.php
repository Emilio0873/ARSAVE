<?php

declare(strict_types=1);

namespace Arsave;

final class DeviceController
{
    public function __construct(private AuthService $auth)
    {
    }

    public function register(Request $req, array $user): void
    {
        $uid = trim((string) $req->input('device_uid', ''));
        $name = trim((string) $req->input('device_name', 'Android'));
        if ($uid === '') {
            Response::error('device_uid requis.', 400);
            return;
        }
        $id = $this->auth->upsertDevice((int) $user['id'], $uid, $name);
        Response::json([
            'device' => [
                'id' => $id,
                'device_uid' => $uid,
                'device_name' => $name,
            ],
        ], 201);
    }
}
