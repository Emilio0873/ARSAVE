# Chiffrement ARSAVE (MVP)

## Modèle

1. À l’inscription, le serveur génère un `kdf_salt` aléatoire (32 octets) stocké en MySQL.
2. À la connexion, l’app reçoit `kdf_salt_b64` et dérive une **clé maître** via PBKDF2-HMAC-SHA256 (120 000 itérations, 256 bits) à partir du mot de passe.
3. Pour chaque fichier :
   - une **clé fichier** aléatoire 256 bits est générée ;
   - le contenu est chiffré en **AES-256-GCM** avec cette clé ;
   - la clé fichier est elle-même chiffrée (wrapped) avec la clé maître (AES-GCM) ;
   - seuls le ciphertext, les nonces et la clé wrappée sont envoyés au serveur.
4. Le checksum SHA-256 porte sur le **ciphertext** (intégrité du blob stocké).

## Ce que le serveur ne voit jamais

- Le fichier en clair
- Le mot de passe (sauf transit login, hashé immédiatement)
- La clé maître
- La clé fichier en clair

## Changement de mot de passe

Un reset de mot de passe régénère `kdf_salt`. Les clés wrappées existantes deviennent inutilisables tant qu’une re-chiffrement n’est pas prévue (hors MVP).
