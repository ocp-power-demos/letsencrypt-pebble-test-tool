#Arches can be: amd64 s390x arm64 ppc64le
ARCH ?= ppc64le
APP ?= pebble

# If absent, registry defaults
REGISTRY ?= quay.io/repository/powercloud/pebble-tool

verify-environment:
	+@echo "REGISTRY: ${REGISTRY}"
	+@echo "ARCH: ${ARCH}"
.PHONY: verify-environment

build: verify-environment
	+@echo "Building Image - 'user'"
	+@podman build --platform linux/${ARCH} -t ${REGISTRY}:pebble-${ARCH} -f linux.ubi9.Dockerfile
	+@echo "Done Image - 'user'"
.PHONY: build

# pushes the individual image
push: verify-environment
	+@podman push ${REGISTRY}:pebble-${ARCH}
.PHONY: push

pull-deps:
	+@podman pull --platform linux/amd64 ${REGISTRY}:${APP}-amd64
	+@podman pull --platform linux/s390x ${REGISTRY}:${APP}-s390x
	+@podman pull --platform linux/arm64 ${REGISTRY}:${APP}-arm64
	+@podman pull --platform linux/ppc64le ${REGISTRY}:${APP}-ppc64le
.PHONY: pull-deps

# Applies to all (except catalogue-db) - generate-and-push-manifest-list.
push-ml: verify-environment pull-deps
	+@echo "Remove existing manifest listed - ${APP}"
	+@podman manifest rm ${REGISTRY}:pebble|| true
	+@echo "Create new ML - ${APP}"
	+@podman manifest create ${REGISTRY}:pebble \
		${REGISTRY}:${APP}-amd64 \
		${REGISTRY}:${APP}-s390x \
		${ARM_REGISTRY}:${APP}-arm64 \
		${REGISTRY}:${APP}-ppc64le
	+@echo "Pushing image - ${APP}"
	+@podman manifest push ${REGISTRY}:pebble ${REGISTRY}:pebble
.PHONY: push-ml
