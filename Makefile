.PHONY: help up down restart logs status clean backup

help:
	@echo "Monitoring App - Available Commands:"
	@echo ""
	@echo "  make up         - Start all services"
	@echo "  make down       - Stop all services"
	@echo "  make restart    - Restart all services"
	@echo "  make logs       - Show logs from all services"
	@echo "  make status     - Show status of all containers"
	@echo "  make clean      - Remove all containers and volumes (WARNING: deletes data!)"
	@echo "  make backup     - Backup Prometheus and Grafana data"
	@echo ""

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs -f

status:
	docker compose ps

clean:
	@echo "WARNING: This will delete all data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
	fi

backup:
	@mkdir -p ./backups
	@echo "Backing up Prometheus data..."
	docker run --rm -v monitoring-app_prometheus_data:/data -v $$(pwd)/backups:/backup alpine tar czf /backup/prometheus-$$(date +%Y%m%d-%H%M%S).tar.gz /data
	@echo "Backing up Grafana data..."
	docker run --rm -v monitoring-app_grafana_data:/data -v $$(pwd)/backups:/backup alpine tar czf /backup/grafana-$$(date +%Y%m%d-%H%M%S).tar.gz /data
	@echo "Backup complete! Files saved in ./backups/"
