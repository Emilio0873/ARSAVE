# Déploiement ARSAVE sur Railway

## Services

1. **MySQL** (plugin Railway)
2. **API** (Dockerfile à la racine) + volume sur `/data/encrypted`
3. Page téléchargement : `https://<domaine>/download/`

## Variables API

Référencer le service MySQL :

- `MYSQLHOST=${{MySQL.MYSQLHOST}}` (adapter le nom du service)
- `MYSQLPORT=${{MySQL.MYSQLPORT}}`
- `MYSQLUSER=${{MySQL.MYSQLUSER}}`
- `MYSQLPASSWORD=${{MySQL.MYSQLPASSWORD}}`
- `MYSQLDATABASE=${{MySQL.MYSQLDATABASE}}`
- `STORAGE_PATH=/data/encrypted`
- `APP_ENV=production`
- `CORS_ORIGIN=*`

## Volume

Monter un volume Railway sur `/data/encrypted` pour conserver les blobs chiffrés.

## APK

Après obtention de l’URL publique de l’API :

```bash
cd mobile
flutter build apk --release --dart-define=API_BASE_URL=https://VOTRE-DOMAINE
```

Copier `build/app/outputs/flutter-apk/app-release.apk` vers `backend/public/download/arsave.apk`, commit, redeploy.
