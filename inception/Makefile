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
	@sudo rm -rf /home/$(LOGIN)/data
	docker volume rm $$(docker volume ls -q) 2>/dev/null || true

re: fclean all

.PHONY: all down stop clean fclean re hosts volumes