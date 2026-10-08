<?php

declare(strict_types=1);

namespace Arsave;

use PDO;

final class App
{
    private Router $router;
    private PDO $db;
    private array $config;
    private AuthService $auth;
    private FileService $files;
    private OperationService $operations;

    public function __construct(array $config)
    {
        $this->config = $config;
        $this->db = Database::connection($config['db']);
        $this->auth = new AuthService($this->db, $config);
        $this->operations = new OperationService($this->db);
        $this->files = new FileService($this->db, $config, $this->operations);
        $this->router = new Router();
        $this->registerRoutes();
    }

    private function registerRoutes(): void
    {
        $authCtrl = new AuthController($this->auth);
        $fileCtrl = new FileController($this->files, $this->auth, $this->operations);
        $deviceCtrl = new DeviceController($this->auth);
        $opCtrl = new OperationController($this->operations);
        $adminCtrl = new AdminController($this->files, $this->auth, $this->db, $this->config);

        $this->router->get('/', fn () => Response::json([
            'name' => 'arsave',
            'status' => 'ok',
        ]), false);

        $this->router->post('/auth/register', fn (Request $r) => $authCtrl->register($r), false);
        $this->router->post('/auth/login', fn (Request $r) => $authCtrl->login($r), false);
        $this->router->post('/auth/forgot-password', fn (Request $r) => $authCtrl->forgotPassword($r), false);
        $this->router->post('/auth/reset-password', fn (Request $r) => $authCtrl->resetPassword($r), false);
        $this->router->post('/auth/logout', fn (Request $r, array $u) => $authCtrl->logout($r, $u));
        $this->router->get('/me', fn (Request $r, array $u) => $authCtrl->me($r, $u));
        $this->router->put('/me', fn (Request $r, array $u) => $authCtrl->updateMe($r, $u));

        $this->router->post('/devices', fn (Request $r, array $u) => $deviceCtrl->register($r, $u));
        $this->router->get('/operations', fn (Request $r, array $u) => $opCtrl->index($r, $u));
        $this->router->get('/admin/stats', fn (Request $r, array $u) => $adminCtrl->stats($r, $u));
        $this->router->get('/admin/users', fn (Request $r, array $u) => $adminCtrl->listUsers($r, $u));
        $this->router->put('/admin/users/{id}', fn (Request $r, array $u, array $p) => $adminCtrl->updateUser($r, $u, $p));
        $this->router->delete('/admin/users/{id}', fn (Request $r, array $u, array $p) => $adminCtrl->deleteUser($r, $u, $p));

        $this->router->get('/files', fn (Request $r, array $u) => $fileCtrl->index($r, $u));
        $this->router->post('/files', fn (Request $r, array $u) => $fileCtrl->upload($r, $u));
        $this->router->get('/files/{id}', fn (Request $r, array $u, array $p) => $fileCtrl->show($r, $u, $p));
        $this->router->get('/files/{id}/versions', fn (Request $r, array $u, array $p) => $fileCtrl->versions($r, $u, $p));
        $this->router->get('/files/{id}/download', fn (Request $r, array $u, array $p) => $fileCtrl->download($r, $u, $p));
        $this->router->post('/files/{id}/trash', fn (Request $r, array $u, array $p) => $fileCtrl->trash($r, $u, $p));
        $this->router->post('/files/{id}/restore', fn (Request $r, array $u, array $p) => $fileCtrl->restore($r, $u, $p));
        $this->router->post('/files/{id}/purge', fn (Request $r, array $u, array $p) => $fileCtrl->purge($r, $u, $p));
    }

    public function run(Request $request): void
    {
        $origin = $this->config['cors_origin'] ?? '*';
        header('Access-Control-Allow-Origin: ' . $origin);
        header('Access-Control-Allow-Headers: Authorization, Content-Type, X-Requested-With');
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        header('Access-Control-Expose-Headers: X-Arsave-Logical-Name, X-Arsave-Mime, X-Arsave-Version, X-Arsave-Checksum, X-Arsave-Nonce, X-Arsave-Wrapped-Key, X-Arsave-Wrap-Nonce');

        if ($request->method === 'OPTIONS') {
            http_response_code(204);
            return;
        }

        $match = $this->router->match($request->method, $request->path);
        if ($match === null) {
            Response::error('Route introuvable.', 404);
            return;
        }

        try {
            $user = null;
            if ($match['auth']) {
                $user = $this->auth->authenticate($request->bearerToken());
            }

            $handler = $match['handler'];
            $params = $match['params'];
            $ref = new \ReflectionFunction(\Closure::fromCallable($handler));
            $argc = $ref->getNumberOfParameters();

            if ($argc >= 3) {
                $handler($request, $user ?? [], $params);
            } elseif ($argc === 2) {
                $handler($request, $user ?? []);
            } elseif ($argc === 1) {
                $handler($request);
            } else {
                $handler();
            }
        } catch (\InvalidArgumentException $e) {
            Response::error($e->getMessage(), 400);
        } catch (\RuntimeException $e) {
            $code = $e->getCode();
            $status = is_int($code) && $code >= 400 && $code < 600 ? $code : 400;
            Response::error($e->getMessage(), $status);
        } catch (\Throwable $e) {
            $message = ($this->config['app_env'] ?? 'local') === 'local'
                ? $e->getMessage()
                : 'Erreur serveur.';
            Response::error($message, 500);
        }
    }
}
