COMPOSE := docker compose

.PHONY: help up down restart build logs ps seed shell mongo-shell reset-data

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

up: ## Build and start MongoDB + API (detached)
	@test -f .env || cp .env.example .env
	$(COMPOSE) up -d --build

down: ## Stop containers (data volume is kept)
	$(COMPOSE) down

restart: ## Restart the API container
	$(COMPOSE) restart api

build: ## Rebuild the API image
	$(COMPOSE) build api

logs: ## Tail API logs
	$(COMPOSE) logs -f api

ps: ## Show container status
	$(COMPOSE) ps

seed: ## Create/update the platform admin inside the API container
	$(COMPOSE) exec api bun run seed:admin

shell: ## Open a shell in the API container
	$(COMPOSE) exec api sh

mongo-shell: ## Open mongosh in the Mongo container
	$(COMPOSE) exec mongo mongosh -u $${MONGO_USER:-mithai} -p $${MONGO_PASSWORD:-mithai_secret} --authenticationDatabase admin

reset-data: ## Stop containers AND wipe the Mongo data volume
	$(COMPOSE) down --volumes
