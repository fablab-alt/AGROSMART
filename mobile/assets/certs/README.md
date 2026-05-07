# Certificate Pinning pour AgroSmart

Ce dossier contient les certificats SSL utilisés pour le certificate pinning en production.

## Fichiers requis

- `api_cert.pem` - Certificat SSL du serveur API de production

## Comment générer le certificat

1. Télécharger le certificat du serveur:
```bash
openssl s_client -connect api.agrismart.ci:443 -showcerts < /dev/null 2>/dev/null | openssl x509 -outform PEM > api_cert.pem
```

2. Ou exporter depuis le certificat Let's Encrypt/autre CA utilisé.

## Notes de sécurité

- **Ne jamais commiter de clés privées** dans ce dossier
- Mettre à jour les certificats avant leur expiration
- En cas de rotation de certificat, publier une mise à jour de l'app avant l'expiration

## Rotation des certificats

Pour éviter les interruptions lors de la rotation:
1. Ajouter le nouveau certificat avant la rotation
2. Garder l'ancien certificat valide pendant une période de transition
3. Retirer l'ancien certificat après la migration complète
