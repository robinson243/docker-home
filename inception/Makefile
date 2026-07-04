COMPOSE_FILE = srcs/docker-compose.yml
LOGIN        = romukena

all: volumes
	docker compose -f $(COMPOSE_FILE) up --build -d

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
	rm -rf $HOME/data

re: fclean all

.PHONY: all down stop clean fclean re volumes