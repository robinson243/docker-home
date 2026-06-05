# Projet Inception — Guide Complet

Résumé de toute l'architecture et des étapes construites ensemble pour le projet Inception de l'École 42.

---

## Architecture Globale

```
Internet / Navigateur
        |
        | HTTPS :443
        |
   ┌────▼─────┐
   │  NGINX   │  ← TLSv1.2/1.3, certificat auto-signé
   └────┬─────┘
        │ FastCGI (port 9000)
        │
   ┌────▼──────────┐       ┌──────────────┐
   │   WordPress   │──────▶│   MariaDB    │
   │   (php-fpm)   │       │  (port 3306) │
   └───────────────┘       └──────────────┘
        │
   Volume partagé
   /var/www/html
   (monté aussi par NGINX)
```

Tous les containers communiquent via un réseau Docker bridge interne (`docker_network`).
Seul le port 443 est exposé vers l'hôte.

---

## Structure des fichiers

```
inception/
├── Makefile
├── .env                        ← variables d'environnement (dans .gitignore !)
└── srcs/
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   └── nginx.conf
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── entrypoint.sh
        │   └── www.conf
        └── mariadb/
            ├── Dockerfile
            └── entrypoint.sh
```

---

## MariaDB

### Dockerfile

```dockerfile
FROM debian:bullseye

RUN apt update && apt upgrade -y
RUN apt install mariadb-server -y
COPY entrypoint.sh /entrypoint.sh
RUN mkdir /run/mysqld/ && chown -R mysql:mysql /run/mysqld/
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]
```

### entrypoint.sh

Le script d'initialisation :
1. Démarre MariaDB en mode init (socket uniquement, pas de réseau)
2. Attend que le socket soit prêt
3. Crée la base de données, l'utilisateur WordPress et le mot de passe root
4. Arrête MariaDB
5. Redémarre MariaDB en mode normal (port 3306 exposé)

```bash
#!/bin/bash
set -e

mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

mysqld --user=mysql --bootstrap << EOF
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

exec mysqld --user=mysql
```

---

## WordPress (php-fpm)

### Dockerfile

```dockerfile
FROM debian:bullseye

RUN apt update && apt upgrade -y && apt install curl php7.4-fpm \
    php7.4-mysql php7.4-cli php7.4-curl php7.4-xml php7.4-mbstring -y
RUN mkdir /run/php/ && chmod +x /run/php/
COPY entrypoint.sh /entrypoint.sh
COPY www.conf /etc/php/7.4/fpm/pool.d/www.conf
RUN chmod +x /entrypoint.sh
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp
RUN mkdir -p /var/www/html
RUN chown -R www-data:www-data /var/www/html
ENTRYPOINT ["/entrypoint.sh"]
```

### www.conf (php-fpm)

Clé importante : php-fpm doit écouter sur `0.0.0.0:9000` pour être accessible depuis NGINX.

```ini
[www]
user = www-data
group = www-data
listen = 0.0.0.0:9000
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
```

### entrypoint.sh

```bash
#!/bin/bash
set -e

cd /var/www/html

if [ ! -f wp-config.php ]; then
    wp core download --allow-root
    wp config create \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${MYSQL_PASSWORD} \
        --dbhost=mariadb \
        --allow-root
    wp core install \
        --url=${WP_URL} \
        --title=${WP_TITLE} \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --allow-root
fi

exec php-fpm7.4 -F
```

---

## NGINX

### Dockerfile

```dockerfile
FROM debian:bullseye

RUN apt update && apt upgrade -y
RUN apt install nginx openssl -y && \
    mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=FR/ST=IDF/L=Paris/O=42/CN=localhost"
COPY nginx.conf /etc/nginx/nginx.conf
CMD ["nginx", "-g", "daemon off;"]
```

### nginx.conf

```nginx
events {}

http {
    include /etc/nginx/mime.types;

    server {
        listen 443 ssl;
        server_name login.42.fr;  # remplacer login par ton login 42

        ssl_certificate     /etc/nginx/ssl/inception.crt;
        ssl_certificate_key /etc/nginx/ssl/inception.key;
        ssl_protocols       TLSv1.2 TLSv1.3;

        root  /var/www/html;
        index index.php index.html;

        location / {
            try_files $uri $uri/ /index.php?$args;
        }

        location ~ \.php$ {
            fastcgi_pass            wordpress:9000;
            fastcgi_index           index.php;
            fastcgi_param           SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include                 fastcgi_params;
        }
    }
}
```

**Points clés :**
- `listen 443 ssl` — port HTTPS uniquement
- `ssl_protocols TLSv1.2 TLSv1.3` — imposé par le sujet
- `try_files` — URLs propres WordPress sans `.php` visible
- `fastcgi_pass wordpress:9000` — Docker résout `wordpress` via le réseau interne
- `include mime.types` — indispensable pour servir CSS/JS correctement

---

## docker-compose.yml

```yaml
services:
  nginx:
    build: ./requirements/nginx
    container_name: nginx
    ports:
      - "443:443"         # seul port exposé vers l'hôte
    volumes:
      - www-data:/var/www/html
    networks:
      - docker_network
    depends_on:
      - wordpress

  wordpress:
    build: ./requirements/wordpress
    container_name: wordpress
    expose:
      - "9000"            # interne uniquement
    env_file:
      - ../.env
    volumes:
      - www-data:/var/www/html
    networks:
      - docker_network
    depends_on:
      - mariadb

  mariadb:
    build: ./requirements/mariadb
    container_name: mariadb
    expose:
      - "3306"            # interne uniquement
    env_file:
      - ../.env
    volumes:
      - mariadb_database:/var/lib/mysql
    networks:
      - docker_network

volumes:
  mariadb_database:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/mknroro/data/mariadb
  www-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/mknroro/data/wordpress

networks:
  docker_network:
    driver: bridge
```

**Différence `expose` vs `ports` :**
| Directive | Accessible depuis | Usage |
|-----------|-------------------|-------|
| `expose`  | Containers du même réseau uniquement | WordPress, MariaDB |
| `ports`   | Machine hôte + containers | NGINX uniquement |

---

## Makefile

```makefile
COMPOSE_FILE = srcs/docker-compose.yml
LOGIN        = romukena

all: hosts volumes
	docker compose -f $(COMPOSE_FILE) up --build -d

hosts:
	@grep -q "$(LOGIN).42.fr" /etc/hosts || \
		echo "127.0.0.1 $(LOGIN).42.fr" | sudo tee -a /etc/hosts

volumes:
	@mkdir -p $(HOME)/data/wordpress
	@mkdir -p $(HOME)/data/mariadb

down:
	docker compose -f $(COMPOSE_FILE) down

stop:
	docker compose -f $(COMPOSE_FILE) stop

clean: down
	docker system prune -f

fclean: clean
	@sudo rm -rf $(HOME)/data
	docker volume rm $$(docker volume ls -q) 2>/dev/null || true

re: fclean all

.PHONY: all down stop clean fclean re hosts volumes
```

**Règles importantes :**
- `$(HOME)` — variable automatique qui pointe vers le vrai home de l'utilisateur système
- `grep -q` dans `hosts` — évite les doublons dans `/etc/hosts`
- `make re` — repart de zéro (fclean + all)

---

## Variables d'environnement (.env)

```env
# MariaDB
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=wppassword
MYSQL_ROOT_PASSWORD=rootpassword

# WordPress
WP_URL=https://romukena.42.fr
WP_TITLE=romukena_site
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=adminpassword
WP_ADMIN_EMAIL=admin@romukena.42.fr
```

> ⚠️ Ce fichier doit être dans `.gitignore` — ne jamais committer des mots de passe.

---

## Résolution DNS locale

`romukena.42.fr` n'existe pas sur Internet — c'est un domaine local.

**Sur Linux (VM) :**
```bash
echo "127.0.0.1 romukena.42.fr" | sudo tee -a /etc/hosts
```

**Sur Windows (si le navigateur tourne sur Windows) :**

Via PowerShell en administrateur :
```powershell
Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "127.0.0.1 romukena.42.fr"
```

Ou via Notepad en administrateur → ouvrir `C:\Windows\System32\drivers\etc\hosts`.

---

## Checklist soutenance

- [ ] Pas de `latest` dans les Dockerfiles — utiliser `debian:bullseye`
- [ ] Aucun mot de passe en dur dans les Dockerfiles — tout passe par `.env`
- [ ] Le `.env` est dans le `.gitignore`
- [ ] `make re` repart proprement de zéro
- [ ] Les volumes persistent après `docker compose down` / `up`
- [ ] Seul le port 443 est exposé vers l'extérieur
- [ ] `docker network ls` montre le réseau custom bridge
- [ ] TLSv1.2 ou TLSv1.3 uniquement (pas TLSv1.0 / TLSv1.1)
- [ ] php-fpm tourne dans le container wordpress (pas dans nginx)
- [ ] NGINX est le seul point d'entrée

---

## Commandes de debug utiles

```bash
# Vérifier que les containers tournent
docker ps

# Voir les logs d'un container
docker logs nginx
docker logs wordpress
docker logs mariadb

# Entrer dans un container
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash

# Vérifier les ports ouverts dans un container
docker exec wordpress cat /proc/net/tcp6

# Tester NGINX depuis l'hôte
curl -k https://romukena.42.fr

# Vérifier les volumes montés
docker exec nginx ls -la /var/www/html
docker exec wordpress ls -la /var/www/html

# Vérifier la connexion MariaDB depuis WordPress
docker exec wordpress wp db check --allow-root
```
