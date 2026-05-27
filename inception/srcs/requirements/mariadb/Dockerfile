FROM debian:bullseye
RUN apt update && apt upgrade -y
RUN apt install mariadb-server -y
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
RUN mkdir /run/mysqld/ && chmod 777 /run/mysqld/
# CMD [ "executable" ]