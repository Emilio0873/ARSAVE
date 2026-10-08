# ARSAVE

Application Android de sauvegarde, restauration et synchronisation sécurisées des fichiers.

Stack : **Flutter** → **API REST PHP** → **MySQL** + stockage de blobs chiffrés.

## Démarrage rapide

Voir [docs/SETUP.md](docs/SETUP.md).

## Structure

| Dossier | Contenu |
|---------|---------|
| `database/` | Schéma et seed MySQL |
| `backend/` | API REST PHP |
| `mobile/` | Application Flutter |
| `docs/` | Documentation technique |

## Sécurité

- Chiffrement AES-256-GCM **avant** transmission
- Clé maître dérivée du mot de passe (PBKDF2), jamais exposée à l’API
- Sessions Bearer hashées, requêtes préparées, ownership côté serveur
