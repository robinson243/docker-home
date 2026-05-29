FROM debian:bullseye
RUN apt update && apt upgrade -y && apt install curl php php-mysql php-curl php-gd php-mbstring php-xml php-zip php-fpm mariadb-client -y
RUN mkdir /run/php/ && chmod +x /run/php/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp
RUN mkdir -p /var/www/html
RUN chown -R www-data:www-data /var/www/html
CMD ["/entrypoint.sh"]