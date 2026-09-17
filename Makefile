# ---------------------------------------------------------
# Misc.
# ---------------------------------------------------------

# Use bash for recipe execution.
SHELL := /bin/bash

# Set the default goal.
.DEFAULT_GOAL := redeploy-zarf-package

# Tell Docker Compose to use Bake for builds.
export COMPOSE_BAKE := true

# Set the Docker Compose profile to "all" if one is not provided.
DOCKER_COMPOSE_PROFILE ?= all

# Centralize the Compose command so every target uses the same profile.
COMPOSE := docker compose --profile $(DOCKER_COMPOSE_PROFILE)

# Ask Compose which services are active for the selected profile.
COMPONENTS = $(shell $(COMPOSE) config --services)

# Prefix used for generated SBOM file names.
SBOM_PREFIX ?= swordfish

# Django-specific configuration.
DJANGO_SERVICE ?= backend
DJANGO_SECRET_KEY ?= swordfish

# VEX metadata.
VEX_AUTHOR ?= Victor Fernandez III
VEX_ID_BASE ?= swordfish

# Security scanner configurations.
SEMGREP_CONFIG ?= auto
GRYPE_FAILURE_THRESHOLD ?= medium

# Zarf configuration.
ZARF_PACKAGE_NAME ?= swordfish
ZARF_PACKAGE_VERSION ?= 0.1.0
ZARF_PACKAGE_ARCH ?= amd64
ZARF_PACKAGE_FILE ?= zarf-package-$(ZARF_PACKAGE_NAME)-$(ZARF_PACKAGE_ARCH)-$(ZARF_PACKAGE_VERSION).tar.zst

# ---------------------------------------------------------
# Update uv.lock for each active Python component.
# ---------------------------------------------------------

.PHONY: lock
.SILENT: lock
lock:
	for COMPONENT in $(COMPONENTS); do \
		BUILD_CONTEXT=$$($(COMPOSE) config --format json | \
			jq -r --arg SERVICE "$$COMPONENT" '.services[$$SERVICE].build.context // empty'); \
		if [ -n "$$BUILD_CONTEXT" ] && [ -f "$$BUILD_CONTEXT/pyproject.toml" ]; then \
			echo "==> Locking $$COMPONENT ($$BUILD_CONTEXT)"; \
			(cd "$$BUILD_CONTEXT" && uv lock); \
		fi; \
	done

# ---------------------------------------------------------
# Reset Django migrations when the Django service is active.
# ---------------------------------------------------------

.PHONY: migrations
.SILENT: migrations
migrations:
	if echo " $(COMPONENTS) " | grep -q " $(DJANGO_SERVICE) "; then \
		BUILD_CONTEXT=$$($(COMPOSE) config --format json | \
			jq -r --arg SERVICE "$(DJANGO_SERVICE)" '.services[$$SERVICE].build.context // empty'); \
		if [ -n "$$BUILD_CONTEXT" ]; then \
			echo "==> Resetting migrations for $(DJANGO_SERVICE) ($$BUILD_CONTEXT)"; \
			find "$$BUILD_CONTEXT" \
				-mindepth 3 -maxdepth 3 \
				-path '*/migrations/*.py' \
				! -name '__init__.py' \
				-type f -delete; \
			find "$$BUILD_CONTEXT" \
				-mindepth 3 -maxdepth 3 \
				-path '*/migrations/__pycache__' \
				-type d -exec rm -rf {} +; \
			(cd "$$BUILD_CONTEXT" && SECRET_KEY="$(DJANGO_SECRET_KEY)" uv run python manage.py makemigrations); \
		fi; \
	fi

# ---------------------------------------------------------
# Check each active Python component for bugs.
# ---------------------------------------------------------

.PHONY: check
.SILENT: check
check:
	for COMPONENT in $(COMPONENTS); do \
		BUILD_CONTEXT=$$($(COMPOSE) config --format json | \
			jq -r --arg SERVICE "$$COMPONENT" '.services[$$SERVICE].build.context // empty'); \
		if [ -n "$$BUILD_CONTEXT" ] && [ -f "$$BUILD_CONTEXT/pyproject.toml" ]; then \
			echo "==> Checking $$COMPONENT ($$BUILD_CONTEXT)"; \
			ruff check --fix --exclude migrations "$$BUILD_CONTEXT"; \
		fi; \
	done

# ---------------------------------------------------------
# Format each active Python component for consistency.
# ---------------------------------------------------------

.PHONY: format
.SILENT: format
format:
	for COMPONENT in $(COMPONENTS); do \
		BUILD_CONTEXT=$$($(COMPOSE) config --format json | \
			jq -r --arg SERVICE "$$COMPONENT" '.services[$$SERVICE].build.context // empty'); \
		if [ -n "$$BUILD_CONTEXT" ] && [ -f "$$BUILD_CONTEXT/pyproject.toml" ]; then \
			echo "==> Formatting $$COMPONENT ($$BUILD_CONTEXT)"; \
			ruff format --exclude migrations "$$BUILD_CONTEXT"; \
		fi; \
	done

# ---------------------------------------------------------
# Check each active component's source code for vulnerabilities.
# ---------------------------------------------------------

.PHONY: sast
.SILENT: sast
sast:
	for COMPONENT in $(COMPONENTS); do \
		BUILD_CONTEXT=$$($(COMPOSE) config --format json | \
			jq -r --arg SERVICE "$$COMPONENT" '.services[$$SERVICE].build.context // empty'); \
		if [ -n "$$BUILD_CONTEXT" ] && [ -d "$$BUILD_CONTEXT" ]; then \
			echo "==> Running SAST on $$COMPONENT ($$BUILD_CONTEXT)"; \
			semgrep scan --config $(SEMGREP_CONFIG) "$$BUILD_CONTEXT"; \
		fi; \
	done

# ---------------------------------------------------------
# Build the active container images.
# ---------------------------------------------------------

.PHONY: build-containers
.SILENT: build-containers
build-containers: lock migrations check format
	$(COMPOSE) build

# ---------------------------------------------------------
# Generate VEX statements for each active component.
# ---------------------------------------------------------

.PHONY: vex
.SILENT: vex

define VEX_FILTER
{
  "@context": "https://openvex.dev/ns/v0.2.0",
  "@id": $$VEX_ID,
  "author": $$VEX_AUTHOR,
  "timestamp": $$VEX_TIMESTAMP,
  "version": 1,
  "statements": [
    .advisories[] | {
      "vulnerability": {
        "name": .vulnerability
      },
      "products": [
        .products[] | {
          "@id": .
        }
      ],
      "status": .status,
      "justification": .justification,
      "impact_statement": .impact_statement
    }
  ]
}
endef

export VEX_FILTER

vex:
	for COMPONENT in $(COMPONENTS); do \
		BUILD_CONTEXT=$$($(COMPOSE) config --format json | \
			jq -r --arg SERVICE "$$COMPONENT" '.services[$$SERVICE].build.context // empty'); \
		if [ -z "$$BUILD_CONTEXT" ]; then \
			continue; \
		fi; \
		VEX_YAML_PATH="$$BUILD_CONTEXT/vex.yaml"; \
		VEX_JSON_PATH="$$BUILD_CONTEXT/vex.json"; \
		if [ -f "$$VEX_YAML_PATH" ]; then \
			echo "==> Generating VEX for $$COMPONENT"; \
			VEX_ID="$(VEX_ID_BASE)-$$COMPONENT-$$(date +%s)"; \
			VEX_TIMESTAMP="$$(date -u +%Y-%m-%dT%H:%M:%SZ)"; \
			if yq --version 2>&1 | grep -qi 'mikefarah'; then \
				yq -o=json '.' "$$VEX_YAML_PATH"; \
			else \
				yq '.' "$$VEX_YAML_PATH"; \
			fi | jq \
				--arg VEX_ID "$$VEX_ID" \
				--arg VEX_AUTHOR "$(VEX_AUTHOR)" \
				--arg VEX_TIMESTAMP "$$VEX_TIMESTAMP" \
				"$$VEX_FILTER" \
				> "$$VEX_JSON_PATH"; \
		else \
			echo "==> No VEX file for $$COMPONENT; skipping"; \
		fi; \
	done

# ---------------------------------------------------------
# Generate SBOMs for each active component's container image.
# ---------------------------------------------------------

.PHONY: sbom
.SILENT: sbom
sbom: build-containers
	for COMPONENT in $(COMPONENTS); do \
		IMAGE_REF=$$($(COMPOSE) config --format json | \
			jq -r --arg SERVICE "$$COMPONENT" '.services[$$SERVICE].image // empty'); \
		SBOM_PATH="$(SBOM_PREFIX)-$$COMPONENT-sbom.json"; \
		if [ -z "$$IMAGE_REF" ]; then \
			echo "ERROR: Compose service $$COMPONENT does not define an image." >&2; \
			exit 1; \
		fi; \
		echo "==> Generating SBOM for $$COMPONENT ($$IMAGE_REF)"; \
		syft "$$IMAGE_REF" -o cyclonedx-json="$$SBOM_PATH"; \
	done

# ---------------------------------------------------------
# Scan each active container image's dependencies for CVEs.
# ---------------------------------------------------------

.PHONY: dependency-scan
.SILENT: dependency-scan
dependency-scan: sbom vex
	grype db update
	for COMPONENT in $(COMPONENTS); do \
		BUILD_CONTEXT=$$($(COMPOSE) config --format json | \
			jq -r --arg SERVICE "$$COMPONENT" '.services[$$SERVICE].build.context // empty'); \
		SBOM_PATH="$(SBOM_PREFIX)-$$COMPONENT-sbom.json"; \
		VEX_JSON_PATH="$$BUILD_CONTEXT/vex.json"; \
		echo "==> Scanning dependencies for $$COMPONENT"; \
		if [ -n "$$BUILD_CONTEXT" ] && [ -f "$$VEX_JSON_PATH" ]; then \
			grype sbom:"$$SBOM_PATH" \
				--vex "$$VEX_JSON_PATH" \
				--fail-on $(GRYPE_FAILURE_THRESHOLD); \
		else \
			grype sbom:"$$SBOM_PATH" \
				--fail-on $(GRYPE_FAILURE_THRESHOLD); \
		fi; \
	done

# ---------------------------------------------------------
# Start the active containers.
# ---------------------------------------------------------

.PHONY: start-containers
.SILENT: start-containers
start-containers: dependency-scan
	$(COMPOSE) up -d

# ---------------------------------------------------------
# Stop the containers.
# ---------------------------------------------------------

.PHONY: stop-containers
.SILENT: stop-containers
stop-containers:
	$(COMPOSE) down

# ---------------------------------------------------------
# Check the status of the active containers.
# ---------------------------------------------------------

.PHONY: status
.SILENT: status
status:
	$(COMPOSE) ps --format "table {{.Name}}\t{{.Ports}}\t{{.Status}}"

# ---------------------------------------------------------
# Deploy the Zarf package.
# ---------------------------------------------------------

.PHONY: deploy
.SILENT: deploy
deploy: dependency-scan
	uds zarf package create --confirm && \
	uds zarf package deploy $(ZARF_PACKAGE_FILE) --confirm

# ---------------------------------------------------------
# Remove the Zarf package.
# ---------------------------------------------------------

.PHONY: remove-zarf-package
.SILENT: remove-zarf-package
remove-zarf-package:
	uds zarf package remove $(ZARF_PACKAGE_NAME) --confirm || true && \
	uds zarf tools kubectl delete namespace $(ZARF_PACKAGE_NAME) --ignore-not-found
	# kubectl patch packages.uds.dev $(ZARF_PACKAGE_NAME) -n $(ZARF_PACKAGE_NAME) --type=merge -p '{"metadata":{"finalizers":[]}}'

# ---------------------------------------------------------
# Redeploy the Zarf package.
# ---------------------------------------------------------

.PHONY: redeploy-zarf-package
.SILENT: redeploy-zarf-package
redeploy-zarf-package: remove-zarf-package deploy

# ---------------------------------------------------------
# Update the UDS package.
# ---------------------------------------------------------

.PHONY: update-uds-package
.SILENT: update-uds-package
update-uds-package:
	uds zarf tools kubectl apply -f uds-package.yaml
