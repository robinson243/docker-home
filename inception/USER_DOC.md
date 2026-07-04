# USER_DOC

## Description

Cette documentation explique comment utiliser l'infrastructure Inception en tant qu'utilisateur final ou administrateur. Le projet fournit un site WordPress accessible en HTTPS, servi par NGINX, avec une base de données MariaDB et une administration WordPress.

## Services fournis par la stack

La stack contient trois services principaux :

- **NGINX** : point d'entrée public du site, gère HTTPS/TLS et transmet les requêtes PHP à WordPress.
- **WordPress + PHP-FPM** : application web et panneau d'administration du site.
- **MariaDB** : base de données utilisée par WordPress.

En pratique :

- l'utilisateur accède au site via HTTPS ;
- l'administrateur gère le contenu via l'interface `wp-admin` ;
- la base MariaDB n'est pas destinée à être utilisée directement par un utilisateur final.

## Démarrer le projet

Depuis la racine du dépôt :

```bash
make
```

Si nécessaire, le projet peut aussi être lancé manuellement :

```bash
cd srcs
docker compose up --build -d
```

## Arrêter le projet

Pour arrêter les conteneurs sans supprimer les volumes :

```bash
cd srcs
docker compose down
```

Pour repartir de zéro en supprimant aussi les volumes persistants :

```bash
cd srcs
docker compose down -v
```

Attention : `down -v` efface les données persistantes de WordPress et MariaDB.

## Accéder au site

Le site est accessible avec le domaine configuré dans le projet :

```text
https://<votre-login>.42.fr
```

Exemple :

```text
https://romukena.42.fr
```

Si le nom de domaine ne résout pas encore, vérifier que l'entrée correspondante a bien été ajoutée dans `/etc/hosts`.

## Accéder au panneau d'administration

L'interface d'administration WordPress est disponible à l'adresse :

```text
https://<votre-login>.42.fr/wp-admin
```

Pour s'y connecter :

- **Identifiant administrateur** : valeur de `WP_ADMIN` dans le fichier `.env`
- **Mot de passe administrateur** : contenu de `secrets/credentials.txt`

## Localiser et gérer les identifiants

Les identifiants sont séparés en deux catégories.

### Variables non sensibles

Le fichier `.env` contient les paramètres de configuration non sensibles, par exemple :

- nom de la base (`DB_NAME`) ;
- utilisateur de la base (`DB_USER`) ;
- URL du site (`WP_URL`) ;
- login admin WordPress (`WP_ADMIN`) ;
- email admin WordPress (`WP_ADMIN_EMAIL`).

### Secrets sensibles

Les mots de passe sont stockés dans le dossier `secrets/` :

- `secrets/db_root_password.txt` : mot de passe root MariaDB ;
- `secrets/db_password.txt` : mot de passe de l'utilisateur WordPress côté base ;
- `secrets/credentials.txt` : mot de passe administrateur WordPress.

Chaque fichier doit contenir uniquement la valeur brute du secret.

## Vérifier que les services fonctionnent

### Vérification rapide

Depuis `srcs/` :

```bash
docker compose ps
```

Les trois services `nginx`, `wordpress` et `mariadb` doivent apparaître comme démarrés.

### Consulter les logs

```bash
cd srcs
docker compose logs
```

Pour suivre les logs en direct :

```bash
cd srcs
docker compose logs -f
```

### Vérifications fonctionnelles

- Ouvrir `https://<votre-login>.42.fr` dans un navigateur.
- Vérifier que la page WordPress s'affiche.
- Ouvrir `https://<votre-login>.42.fr/wp-admin`.
- Vérifier que la connexion admin fonctionne.
- Publier un article ou un commentaire de test pour confirmer que WordPress et MariaDB communiquent correctement.

## Dépannage simple

- Si le site ne répond pas, vérifier `docker compose ps` puis `docker compose logs`.
- Si le domaine ne fonctionne pas, vérifier `/etc/hosts`.
- Si l'administration WordPress refuse la connexion, vérifier `WP_ADMIN` dans `.env` et `secrets/credentials.txt`.
- Si le projet redémarre mais a perdu ses données, vérifier si un `docker compose down -v` a été exécuté.
