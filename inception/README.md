*This project has been created as part of the 42 curriculum by romukena.*

# Inception

## Description

Inception est un projet de 42 centré sur l’administration système et la conteneurisation. Son objectif est de construire une petite infrastructure web avec Docker Compose, en séparant les services NGINX, WordPress avec PHP-FPM et MariaDB dans des conteneurs distincts, tout en respectant des contraintes de sécurité, de persistance et d’isolation.

Ce projet permet de comprendre comment plusieurs services communiquent au sein d’un réseau Docker, comment les données persistent grâce aux volumes, et comment décrire une infrastructure sous forme de configuration reproductible. L’architecture mise en place repose sur NGINX pour gérer le HTTPS, WordPress pour l’application web, et MariaDB pour le stockage des données.

## Présentation du projet

Docker est utilisé dans ce projet pour empaqueter chaque service dans un environnement isolé avec son propre système de fichiers, ses dépendances et son processus de démarrage. Cette approche rend l’infrastructure reproductible, plus simple à déboguer et plus proche des pratiques modernes de déploiement utilisées en DevOps.

Le projet utilise trois images personnalisées construites à partir de Debian Bullseye :

- NGINX, configuré comme unique point d’entrée public et limité à TLS 1.2 et TLS 1.3.
- WordPress avec PHP-FPM, utilisé pour exécuter l’application PHP sans embarquer NGINX dans le même conteneur.
- MariaDB, utilisé comme service de base de données pour le site WordPress.

Les principaux choix de conception ont été les suivants :

- un service par conteneur, afin de respecter la séparation des responsabilités ;
- un réseau Docker dédié, pour permettre la communication interne entre services sans exposer de ports inutiles ;
- deux volumes Docker persistants, un pour les fichiers WordPress et un pour les données MariaDB ;
- l’usage de secrets Docker stockés dans des fichiers texte hors du dépôt Git, plutôt que de mettre les mots de passe en dur dans les Dockerfiles ou le fichier Compose ;
- un accès uniquement en HTTPS via NGINX avec un certificat auto-signé.

## Choix techniques

| Sujet | Choix dans le projet | Pourquoi |
|---|---|---|
| Système de base | Debian Bullseye | Imposé par le sujet et stable pour une installation via paquets |
| Serveur web | NGINX | Reverse proxy léger avec support TLS |
| Exécution PHP | PHP-FPM dans le conteneur WordPress | Séparation claire entre serveur web et application PHP |
| Base de données | MariaDB | Service relationnel demandé pour WordPress |
| Orchestration | Docker Compose | Permet de définir et lancer l’infrastructure multi-conteneurs |
| Secrets | Fichiers montés comme secrets Docker | Évite de stocker les mots de passe directement dans la configuration |
| Persistance | Volumes Docker nommés | Conserve les données WordPress et MariaDB après recréation des conteneurs |

## Comparaisons demandées

### Machines virtuelles vs Docker

Une machine virtuelle émule un système d’exploitation complet avec son propre noyau et sa propre abstraction matérielle, alors qu’un conteneur Docker partage le noyau de l’hôte et isole les processus au niveau du système d’exploitation. Les machines virtuelles sont plus lourdes mais offrent une isolation plus forte, tandis que Docker est plus léger, démarre plus vite et convient mieux à une architecture composée de services séparés.

Dans Inception, Docker est le bon choix parce que le projet porte sur le déploiement et l’orchestration de services, pas sur la gestion de systèmes invités complets. La machine virtuelle reste néanmoins utile comme environnement imposé par 42, tandis que Docker est utilisé à l’intérieur de cette VM pour exécuter l’infrastructure.

### Secrets vs Variables d’environnement

Les variables d’environnement sont pratiques pour les paramètres non sensibles comme le nom de la base, le nom d’utilisateur, le domaine ou le titre du site. Les secrets sont mieux adaptés aux données sensibles comme les mots de passe, car ils évitent de placer des informations confidentielles directement dans le fichier Compose ou dans l’environnement shell.

Dans ce projet, les valeurs non sensibles sont stockées dans `.env`, tandis que les mots de passe sont lus depuis des fichiers comme `db_password.txt` et `db_root_password.txt`. Cette séparation rend la configuration plus propre et réduit le risque de fuite d’identifiants dans l’historique Git ou dans les logs.

### Réseau Docker vs Réseau hôte

Un réseau bridge Docker personnalisé donne à chaque conteneur un contexte réseau isolé et permet aux services de communiquer par nom de service. Le mode host supprime cette isolation et fait partager directement la pile réseau de la machine hôte au conteneur.

Un réseau Docker dédié est préférable ici parce qu’il limite l’exposition, garde l’architecture propre et respecte les contraintes du sujet. NGINX peut joindre WordPress, et WordPress peut joindre MariaDB, sans exposer directement les services internes à la machine hôte.

### Volumes Docker vs Bind Mounts

Les volumes Docker sont gérés par Docker et sont bien adaptés aux données persistantes comme les fichiers d’une base de données ou le contenu WordPress. Les bind mounts montent un chemin précis de l’hôte dans le conteneur, ce qui est pratique en développement mais plus couplé à l’arborescence locale.

Ce projet utilise des volumes nommés parce qu’ils sont plus simples à gérer, plus portables et mieux adaptés à des données de service persistantes. Les bind mounts exposeraient davantage de détails propres à la machine hôte et sont moins propres dans un projet destiné à démontrer la portabilité d’une infrastructure.

## Arborescence du dépôt

```text
.
├── Makefile
├── README.md
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   └── entrypoint.sh
        ├── nginx/
        │   ├── Dockerfile
        │   └── nginx.conf
        └── wordpress/
            ├── Dockerfile
            ├── entrypoint.sh
            └── www.conf
```

## Instructions

### Prérequis

Le projet est conçu pour être exécuté dans une machine virtuelle Debian avec Docker et Docker Compose installés. Avant de lancer l’infrastructure, il faut vérifier que les fichiers de secrets et le fichier `.env` existent localement.

### Configuration

Les fichiers suivants doivent être créés localement et ne doivent pas être commit dans le dépôt :

- `secrets/db_root_password.txt`
- `secrets/db_password.txt`
- `secrets/credentials.txt`
- `.env`

Le fichier `.env` doit contenir les variables non sensibles, par exemple :

```env
DB_NAME=wordpress
DB_USER=wpuser
WP_URL=romukena.42.fr
WP_TITLE=romukena_site
WP_ADMIN=romukena
WP_ADMIN_EMAIL=romukena@student.42.fr
```

Les fichiers de secrets doivent contenir uniquement la valeur brute du mot de passe, une valeur par fichier.

### Compilation et lancement

Depuis la racine du dépôt :

```bash
make
```

Si le Makefile n’encapsule pas déjà les commandes Docker Compose, l’infrastructure peut aussi être lancée manuellement avec :

```bash
cd srcs
docker compose up --build
```

### Arrêt et nettoyage

Pour arrêter l’infrastructure :

```bash
cd srcs
docker compose down
```

Pour supprimer les conteneurs, réseaux et volumes afin de repartir proprement :

```bash
cd srcs
docker compose down -v
```

### Accès

Une fois l’infrastructure lancée, le site est accessible en HTTPS via le domaine configuré. L’interface d’administration WordPress est généralement disponible à l’adresse suivante :

```text
https://<votre-domaine>/wp-admin
```

## Notes pour l’évaluation

Les fichiers suivants ne doivent pas être push dans le dépôt :

- `secrets/credentials.txt`
- `secrets/db_password.txt`
- `secrets/db_root_password.txt`
- `.env`

Un `.gitignore` doit être utilisé pour empêcher les secrets et la configuration locale d’entrer dans le versionnement Git.

## Resources

### Ressources utilisées

- Ressource vidéo principale utilisée pendant le projet : [playlist YouTube](https://www.youtube.com/watch?v=EfIed-cFms4&list=PLpLG--nxBMd-wO_MAWh3gzqCcFh4qNMvP)
- Documentation Docker : [https://docs.docker.com/](https://docs.docker.com/)
- Documentation Docker Compose : [https://docs.docker.com/compose/](https://docs.docker.com/compose/)
- Documentation NGINX : [https://nginx.org/en/docs/](https://nginx.org/en/docs/)
- Documentation MariaDB : [https://mariadb.com/docs/](https://mariadb.com/docs/)
- Documentation WordPress : [https://wordpress.org/documentation/](https://wordpress.org/documentation/)
- Documentation PHP-FPM : [https://www.php.net/manual/en/install.fpm.php](https://www.php.net/manual/en/install.fpm.php)

### Utilisation de l’IA

L’IA a été utilisée comme assistant d’apprentissage et de débogage pendant le projet. Elle a principalement servi à :

- clarifier les concepts liés à Docker, Docker Compose, les volumes, les réseaux et les secrets ;
- comprendre le rôle de chaque service dans l’architecture ;
- relire des fichiers de configuration comme `docker-compose.yml`, `nginx.conf`, les Dockerfiles et les scripts d’entrée ;
- identifier des causes probables de problèmes au démarrage ou à la connexion entre services ;
- aider à structurer la documentation et à expliquer certains choix techniques.

L’IA n’a pas été utilisée comme substitut aux tests. L’infrastructure finale a été validée en construisant, lançant et déboguant directement les conteneurs dans l’environnement de développement.
