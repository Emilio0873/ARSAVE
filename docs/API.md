# Documentation API ARSAVE

Base URL : `http://<host>:8080`

Authentification : header `Authorization: Bearer <token>` (sauf register/login/forgot/reset).

## Auth

### POST `/auth/register`
```json
{ "email": "user@example.com", "password": "secret123", "name": "Alice" }
```

### POST `/auth/login`
```json
{
  "email": "user@example.com",
  "password": "secret123",
  "device_uid": "android-uuid",
  "device_name": "Pixel 7"
}
```
Réponse : `token`, `expires_at`, `user`, `kdf_salt_b64`.

### POST `/auth/logout`
### GET `/me`
### PUT `/me` — `{ "name": "Nouveau nom" }`
### POST `/auth/forgot-password` — `{ "email": "..." }`
### POST `/auth/reset-password` — `{ "token": "...", "password": "..." }`

## Devices

### POST `/devices`
```json
{ "device_uid": "...", "device_name": "..." }
```

## Files

### GET `/files?status=active|trashed`

### POST `/files` (multipart)
Champs :
- `blob` : fichier chiffré
- `logical_name`, `mime`
- `checksum_sha256` (SHA-256 du ciphertext)
- `nonce_b64`, `wrapped_key_b64`, `wrap_nonce_b64`
- `file_id` (optionnel, pour nouvelle version)
- `device_uid`, `device_name` (optionnels)

### GET `/files/{id}`
### GET `/files/{id}/versions`
### GET `/files/{id}/download?version=N`
Headers de réponse crypto : `X-Arsave-Nonce`, `X-Arsave-Wrapped-Key`, `X-Arsave-Wrap-Nonce`, `X-Arsave-Checksum`, etc.

### POST `/files/{id}/trash`
### POST `/files/{id}/restore`
### POST `/files/{id}/purge`

## Operations

### GET `/operations?limit=50`

## Admin

### GET `/admin/stats` (rôle `admin` uniquement — pas d’accès au contenu déchiffré)
