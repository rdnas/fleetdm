# Runs on minikube-vm (see README). Terragrunt is run separately from the admin laptop.
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

PROFILE    ?= fleetdm
NAMESPACE  ?= fleet
RELEASE    ?= fleetdm
CHART      := charts/fleetdm
FLEET_HOST ?= fleet.fleetdm.internal
CPUS       ?= 2
MEMORY     ?= 6g
# Extra helm flags, e.g. VALUES="-f my-values.yaml --set fleet.replicas=1"
VALUES     ?=

CA_FILE        ?= fleet-ca.pem
TLS_SECRET     ?= fleet-tls-secret
ADMIN_EMAIL    ?=
ADMIN_PASSWORD ?=
ADMIN_NAME     ?= Fleet Admin
ORG_NAME       ?= fleetdm
PACKAGE_TYPE   ?= deb

KUBECTL := kubectl --context $(PROFILE)
HELM    := helm --kube-context $(PROFILE)

.PHONY: help check-tools cluster install uninstall verify ca fleet-setup agent-package lint cluster-delete

help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo
	@echo "Variables: PROFILE=$(PROFILE) NAMESPACE=$(NAMESPACE) RELEASE=$(RELEASE) FLEET_HOST=$(FLEET_HOST) CPUS=$(CPUS) MEMORY=$(MEMORY)"

check-tools: ## Check that the required CLIs are installed
	@missing=0; for t in docker minikube kubectl helm fleetctl jq; do \
	  if command -v $$t >/dev/null 2>&1; then printf '  %-9s %s\n' "$$t" "$$(command -v $$t)"; \
	  else echo "  $$t: MISSING"; missing=1; fi; \
	done; \
	docker info >/dev/null 2>&1 || { echo "  docker daemon not reachable (sudo usermod -aG docker $$USER, then log in again)"; missing=1; }; \
	exit $$missing

cluster: check-tools ## Start minikube (docker driver, ports 80/443 published) with the ingress addon
	minikube start -p $(PROFILE) --driver=docker --cpus=$(CPUS) --memory=$(MEMORY) \
	  --ports=80:80 --ports=443:443
	minikube -p $(PROFILE) addons enable ingress
	$(KUBECTL) -n ingress-nginx wait --for=condition=Ready pod \
	  -l app.kubernetes.io/component=controller --timeout=300s

install: ## helm upgrade --install the chart and wait until it is Ready
	$(HELM) upgrade --install $(RELEASE) $(CHART) -n $(NAMESPACE) --create-namespace \
	  --wait --timeout 10m --set 'ingress.hosts[0]=$(FLEET_HOST)' $(VALUES)

uninstall: ## Uninstall the release, delete leftover PVCs and the namespace
	-$(HELM) uninstall $(RELEASE) -n $(NAMESPACE) --wait
	$(KUBECTL) -n $(NAMESPACE) delete pvc -l app.kubernetes.io/instance=$(RELEASE) --ignore-not-found --wait
	$(KUBECTL) delete namespace $(NAMESPACE) --ignore-not-found --wait

verify: ## Run helm test and show pod status
	$(KUBECTL) -n $(NAMESPACE) get pods,svc,ingress,pvc
	$(HELM) test $(RELEASE) -n $(NAMESPACE) --logs
	$(KUBECTL) -n $(NAMESPACE) get pods -o wide

ca: ## Write the chart-generated CA certificate to fleet-ca.pem (CA_FILE)
	$(KUBECTL) -n $(NAMESPACE) get secret $(TLS_SECRET) -o jsonpath='{.data.ca\.crt}' | base64 -d > $(CA_FILE)
	@openssl x509 -in $(CA_FILE) -noout -subject -enddate 2>/dev/null || true
	@echo "Wrote $(CA_FILE)"

fleet-setup: ca ## Point fleetctl at Fleet and create the first admin (ADMIN_EMAIL, ADMIN_PASSWORD required)
	@test -n "$(ADMIN_EMAIL)" || { echo "ADMIN_EMAIL is required"; exit 1; }
	@test -n "$(ADMIN_PASSWORD)" || { echo "ADMIN_PASSWORD is required"; exit 1; }
	fleetctl config set --address https://$(FLEET_HOST) --rootca $(abspath $(CA_FILE))
	@fleetctl setup --email '$(ADMIN_EMAIL)' --password '$(ADMIN_PASSWORD)' \
	  --name '$(ADMIN_NAME)' --org-name '$(ORG_NAME)' \
	  || fleetctl login --email '$(ADMIN_EMAIL)' --password '$(ADMIN_PASSWORD)'

agent-package: ca ## Build a fleetd package (PACKAGE_TYPE=deb) enrolled against https://FLEET_HOST
	@secret="$$(fleetctl get enroll_secret --json | jq -r '.spec.secrets[0].secret')"; \
	test -n "$$secret" && test "$$secret" != null || { echo "no enroll secret; run 'make fleet-setup' first"; exit 1; }; \
	fleetctl package --type=$(PACKAGE_TYPE) --fleet-url=https://$(FLEET_HOST) \
	  --enroll-secret="$$secret" --fleet-certificate=$(abspath $(CA_FILE))
	@ls -1 fleet-osquery*.$(PACKAGE_TYPE)

lint: ## helm lint (default and CI values) and render the templates
	helm lint $(CHART) --strict
	helm lint $(CHART) --strict -f $(CHART)/ci/ci-values.yaml
	helm template $(RELEASE) $(CHART) -n $(NAMESPACE) --set 'ingress.hosts[0]=$(FLEET_HOST)' >/dev/null
	@echo "lint OK"

cluster-delete: ## Delete the minikube cluster
	minikube delete -p $(PROFILE)
