NAME			=	inception
COMPOSE_FILE	=	srcs/docker-compose.yml

all:
	@echo "Sistem ayağa kaldırılıyor..."
	@mkdir -p /home/iekmen/data/wordpress
	@mkdir -p /home/iekmen/data/mariadb
	docker compose -f $(COMPOSE_FILE) up -d --build

down:
	@echo "Sistem durduruluyor..."
	docker compose -f $(COMPOSE_FILE) down

clean:
	@echo "Konteynerler ve imajlar temizleniyor..."
	docker compose -f $(COMPOSE_FILE) down --rmi all -v

fclean: clean
	@echo "Tüm kalıcı veriler ve klasörler siliniyor..."
	@sudo rm -rf /home/iekmen/data/wordpress/*
	@sudo rm -rf /home/iekmen/data/mariadb/*
	@docker system prune -af --volumes

re: fclean all

.PHONY: all down clean fclean re