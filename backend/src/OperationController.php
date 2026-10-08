<?php

declare(strict_types=1);

namespace Arsave;

final class OperationController
{
    public function __construct(private OperationService $operations)
    {
    }

    public function index(Request $req, array $user): void
    {
        $limit = isset($req->query['limit']) ? (int) $req->query['limit'] : 50;
        Response::json(['operations' => $this->operations->listForUser((int) $user['id'], $limit)]);
    }
}
