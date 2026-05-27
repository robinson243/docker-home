FROM debian:bullseye

RUN apt update && apt upgrade -y
RUN apt install nginx -y
CMD ["nginx", "-g", "daemon off;"]