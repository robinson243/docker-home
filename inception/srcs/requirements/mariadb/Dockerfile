FROM debian:bullseye
RUN apt update && apt upgrade -y
RUN apt install mariadb-server -y
COPY entrypoint.sh /entrypoint.sh
RUN mkdir /run/mysqld/ && chown -R mysql:mysql /run/mysqld
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
# CMD [ "executable" ]