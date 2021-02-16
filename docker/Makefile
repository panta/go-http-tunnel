mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(dir $(mkfile_path))

GIT_COMMIT       := $$(git rev-parse HEAD)
GIT_COMMIT_SHORT := $$(git rev-parse --short HEAD)
#GIT_TAG          := $$(git describe --exact-match)

DOCKER_REPOSITORY ?= panta/go-http-tunnel
DOCKER_TAG        ?= latest

OK_COLOR=\033[32;01m
NO_COLOR=\033[0m

DOCKER ?= docker

.PHONY: all
all: docker-build docker-push

.PHONY: docker
docker: docker-build docker-push

.PHONY: docker-build
docker-build:
	@echo "$(OK_COLOR)==>$(NO_COLOR) Building $(DOCKER_REPOSITORY):$(DOCKER_TAG)"
# 	@docker build --no-cache --rm -t $(REPOSITORY):$(TAG) ..
	@docker build --rm -t $(DOCKER_REPOSITORY):$(DOCKER_TAG) -f ${current_dir}/Dockerfile ..

.PHONY: docker-push
docker-push:
	@echo "$(OK_COLOR)==>$(NO_COLOR) Pushing $(DOCKER_REPOSITORY):$(DOCKER_TAG)"
	@docker push $(DOCKER_REPOSITORY):$(DOCKER_TAG)
