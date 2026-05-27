FROM debian:bullseye

RUN apt update && apt upgrade -y
RUN apt install mariadb-server -y
RUN mkdir /run/mysqld/ && chmod 777 /run/mysqld/
CMD if [ "$(ls /var/lib/mysql | wc -l)" -eq 0 ]; then mysql_install_db; fi && mysqld