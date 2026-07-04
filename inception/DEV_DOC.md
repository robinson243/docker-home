# DEV_DOC

## Description

Cette documentation explique comment reconstruire, lancer et maintenir le projet Inception en tant que développeur. Elle couvre les prérequis, les fichiers de configuration, les secrets, la persistance des données et les commandes utiles pour gérer la stack Docker Compose.

## Prérequis

Le projet doit être préparé dans une machine virtuelle Debian compatible avec le sujet Inception.

Prévoir au minimum :

- Docker installé ;
- Docker Compose disponible via `docker compose` ;
- un nom de domaine local de type `<login>.42.fr` pointant vers la machine ;
- un `Makefile` fonctionnel ;
- les fichiers de configuration locaux non versionnés.

## Mise en place depuis zéro

### 1. Cloner le dépôt

```bash
git clone <url-du-repo>
cd inception
```

### 2. Créer les fichiers locaux requis

Créer les secrets :

```bash
mkdir -p secrets
printf 'monMotDePasseRoot123' > secrets/db_root_password.txt
printf 'monMotDePasseUser123' > secrets/db_password.txt
printf 'wp_admin_password' > secrets/credentials.txt
```

Créer le fichier `.env` à la racine du dépôt :

```env
DB_NAME=wordpress
DB_USER=wpuser
WP_URL=<login>.42.fr
WP_TITLE=<login>_site
WP_ADMIN=<login>
WP_ADMIN_EMAIL=<login>@student.42.fr
```

### 3. Vérifier l'arborescence

Le dépôt doit contenir au minimum :

```text
.
├── Makefile
├── secrets/
└── srcs/
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        ├── nginx/
        └── wordpress/
```

## Build et lancement

### Avec le Makefile

Depuis la racine :

```bash
make
```

### Avec Docker Compose

Depuis `srcs/` :

```bash
docker compose up --build -d
```

Pour forcer une reconstruction propre :

```bash
docker compose up --build --force-recreate -d
```

## Gestion des conteneurs

Depuis `srcs/` :

### Voir l'état des services

```bash
docker compose ps
```

### Voir les logs

```bash
docker compose logs
docker compose logs -f
docker compose logs mariadb
docker compose logs wordpress
docker compose logs nginx
```

### Entrer dans un conteneur

```bash
docker exec -it wordpress bash
docker exec -it mariadb bash
docker exec -it nginx bash
```

### Arrêter les services

```bash
docker compose down
```

### Arrêter et supprimer aussi les volumes

```bash
docker compose down -v
```

### Redémarrer après modification

```bash
docker compose up --build -d
```

## Gestion des volumes et des données

Le projet utilise deux volumes nommés :

- `www-data` pour les fichiers WordPress ;
- `mariadb_database` pour les données MariaDB.

Ces volumes permettent de conserver les données même si les conteneurs sont recréés.

### Où les données sont stockées dans les conteneurs

- WordPress : `/var/www/html`
- MariaDB : `/var/lib/mysql`

### Comment vérifier les volumes

```bash
docker volume ls
```

Pour inspecter un volume :

```bash
docker volume inspect <nom_du_volume>
```

## Persistance des données

La persistance repose sur les volumes Docker déclarés dans `docker-compose.yml`.

Conséquences pratiques :

- `docker compose down` arrête et supprime les conteneurs, mais conserve les volumes ;
- `docker compose down -v` supprime aussi les volumes ;
- tant que les volumes existent, la base et les fichiers WordPress sont conservés.

## Emplacement des configurations importantes

- `srcs/docker-compose.yml` : orchestration des services, volumes, réseau, secrets.
- `srcs/requirements/nginx/nginx.conf` : configuration NGINX et FastCGI.
- `srcs/requirements/nginx/Dockerfile` : image NGINX et certificat TLS.
- `srcs/requirements/wordpress/Dockerfile` : image WordPress/PHP-FPM/WP-CLI.
- `srcs/requirements/wordpress/entrypoint.sh` : installation et initialisation WordPress.
- `srcs/requirements/wordpress/www.conf` : configuration PHP-FPM.
- `srcs/requirements/mariadb/Dockerfile` : image MariaDB.
- `srcs/requirements/mariadb/entrypoint.sh` : initialisation de la base et des utilisateurs.
- `secrets/` : fichiers de mots de passe.
- `.env` : variables non sensibles.

## Commandes utiles pour le développement

### Repartir complètement de zéro

```bash
cd srcs
docker compose down -v
cd ..
make
```

### Vérifier les images construites

```bash
docker images
```

### Vérifier les réseaux Docker

```bash
docker network ls
docker network inspect srcs_docker_network
```

### Tester WordPress dans le conteneur

```bash
docker exec -it wordpress bash
wp --allow-root core version --path=/var/www/html
```

### Tester MariaDB dans le conteneur

```bash
docker exec -it mariadb bash
mysql -u root -p
```

## Bonnes pratiques

- Ne pas versionner `.env` ni le dossier `secrets/`.
- Ajouter ces fichiers dans `.gitignore`.
- Ne jamais mettre de mots de passe en dur dans les Dockerfiles ou dans `docker-compose.yml`.
- Utiliser `docker compose logs` avant de modifier les scripts au hasard.
- Vérifier la persistance après redémarrage avant une évaluation.
