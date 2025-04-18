# Extract the project name from pyproject.toml
PROJECT_NAME := $(shell grep '^name =' pyproject.toml | head -1 | cut -d '"' -f2)

include .env
DATA_SOURCE_PATH ?= data

help:  ## Show help
	@grep -E '^[.a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

clean: ## Clean autogenerated files
	rm -rf dist
	find . -type f -name "*.DS_Store" -ls -delete
	find . | grep -E "(__pycache__|\.pyc|\.pyo)" | xargs rm -rf
	find . | grep -E ".pytest_cache" | xargs rm -rf
	find . | grep -E ".ipynb_checkpoints" | xargs rm -rf
	rm -f .coverage

clean-logs: ## Clean logs
	rm -rf logs/**

format: ## Run pre-commit hooks
	pre-commit run -a

sync: ## Merge changes from main branch to your current branch
	git pull
	git pull origin main

test: ## Run not slow tests
	pytest -k "not slow"

test-full: ## Run all tests
	pytest

train: ## Train the model
	python src/train.py

# ----------- DOCKER COMMANDS -----------

docker-build: ## Build the Docker image
	docker build -t $(PROJECT_NAME) .

docker-run: ## Run the container in the background
	docker run --gpus all -dit \
		-v $(PWD):/app \
		-v $(DATA_SOURCE_PATH):/app/data \
		--shm-size=8g \
		--network=host \
		--ipc=host \
		--name $(PROJECT_NAME)-container \
		--env-file .env \
		$(PROJECT_NAME) bash 

docker-run-it: ## Run the container with mounted volumes in interactive mode
	docker run --gpus all -it --rm \
		-v $(PWD):/app \
		-v $(DATA_SOURCE_PATH):/app/data \
		--network=host \
		--shm-size=8g \
		--ipc=host \
		$(PROJECT_NAME) bash

docker-stop: ## Stop the running container
	docker stop $(PROJECT_NAME)-container

docker-restart: ## Restart the stopped container
	docker restart $(PROJECT_NAME)-container

docker-remove: ## Remove the container after stopping
	docker rm $(PROJECT_NAME)-container

docker-exec: ## Open a Bash shell inside the running container
	docker exec -it $(PROJECT_NAME)-container zsh

docker-logs: ## Show logs from the running container
	docker logs $(PROJECT_NAME)-container

docker-clean: ## Remove the container and image completely
	docker stop $(PROJECT_NAME)-container || true
	docker rm $(PROJECT_NAME)-container || true
	docker rmi $(PROJECT_NAME) || true
