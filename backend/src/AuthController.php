<?php

declare(strict_types=1);

namespace Arsave;

final class AuthController
{
    public function __construct(private AuthService $auth)
    {
    }

    public function register(Request $req): void
    {
        $user = $this->auth->register(
            (string) $req->input('email', ''),
            (string) $req->input('password', ''),
            (string) $req->input('name', '')
        );
        Response::json(['user' => $user], 201);
    }

    public function login(Request $req): void
    {
        $result = $this->auth->login(
            (string) $req->input('email', ''),
            (string) $req->input('password', ''),
            $req->input('device_uid') !== null ? (string) $req->input('device_uid') : null,
            $req->input('device_name') !== null ? (string) $req->input('device_name') : null
        );
        Response::json($result);
    }

    public function logout(Request $req, array $user): void
    {
        $token = $req->bearerToken();
        if ($token) {
            $this->auth->logout($token);
        }
        Response::json(['message' => 'Déconnecté.']);
    }

    public function me(Request $req, array $user): void
    {
        Response::json(['user' => $this->auth->userPublic($user)]);
    }

    public function updateMe(Request $req, array $user): void
    {
        $updated = $this->auth->updateProfile((int) $user['id'], (string) $req->input('name', ''));
        Response::json(['user' => $updated]);
    }

    public function forgotPassword(Request $req): void
    {
        $result = $this->auth->requestPasswordReset((string) $req->input('email', ''));
        Response::json($result);
    }

    public function resetPassword(Request $req): void
    {
        $this->auth->resetPassword(
            (string) $req->input('token', ''),
            (string) $req->input('password', '')
        );
        Response::json(['message' => 'Mot de passe mis à jour.']);
    }
}
