# ARSAVE — Configuration locale

## Prérequis

- PHP 8.1+ avec extensions `pdo_mysql`, `json`, `mbstring`, `fileinfo`
- MySQL 8+ (ou MariaDB 10.5+)
- Flutter 3.16+ / Android SDK
- Serveur web pointant vers `backend/public` (Apache, Nginx, ou `php -S`)

## Base de données

```bash
mysql -u root -p < database/schema.sql
mysql -u root -p < database/seed.sql
```

Puis régénérez le hash admin :

```bash
php backend/scripts/generate_seed_hash.php Admin@12345
```

Mettez à jour `seed.sql` ou exécutez la requête UPDATE affichée.

## Backend

1. Copier `backend/config/config.example.php` vers `backend/config/config.php`
2. Ajuster DSN MySQL, `storage_path`, CORS si besoin
3. Créer le dossier de stockage :

```bash
mkdir -p backend/storage/encrypted
```

4. Lancer l’API (développement) :

```bash
cd backend/public
php -S 0.0.0.0:8080 router.php
```

Base URL API : `http://<IP-LAN>:8080`

Sur émulateur Android, utiliser `http://10.0.2.2:8080`.
Sur appareil physique, utiliser l’IP locale du PC (ex. `http://192.168.1.10:8080`).

## Mobile Flutter

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

## Sécurité (rappel)

- Les fichiers sont chiffrés **côté appareil** avant upload
- La clé maître est dérivée du mot de passe (PBKDF2) ; le serveur ne la stocke pas
- Les tokens Bearer sont hashés (SHA-256) en base
- Aucune connexion Flutter → MySQL

## Schéma (aperçu)

Voir `database/schema.sql` : `users`, `devices`, `sessions`, `files`, `file_versions`, `operations`, `password_resets`.
