## Create KinD cluster 1
create-kind-cluster-1:
	kind create cluster --name cluster-1 --config kind/kind-cluster-1-config.yaml
.PHONY: create-kind-cluster-1

## Create KinD cluster 2
create-kind-cluster-2:
	kind create cluster --name cluster-2 --config kind/kind-cluster-2-config.yaml
.PHONY: create-kind-cluster-2

## Create KinD clusters
create-kind-clusters: create-kind-cluster-1 create-kind-cluster-2
.PHONY: create-kind-clusters

## Install ArgoCD on kind-cluster-1
install-argo-cd-on-kind-cluster-1:
	kubectl config use-context kind-cluster-1
	kubectl create namespace argocd
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl rollout status deployment/argocd-server -n argocd
	kubectl patch svc argocd-server -n argocd --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":30000}]'
	INITIAL_ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
	echo -n "Visit http://localhost:30000 to access the ArgoCD user interface with username 'admin' and password ${INITIAL_ADMIN_PASSWORD}"
.PHONY: install-argo-cd-on-kind-cluster-1

## Register a cluster to deploy apps to
register-kind-cluster-2-on-argo-cd:
	argocd login localhost:30000
	argocd cluster add kind-cluster-2
.PHONY: register-kind-cluster-2-on-argo-cd

## Create ArgoCD application
create-argo-cd-app:
	kubectl apply -f application.yaml -n argocd
.PHONY: create-argo-cd-app

### HELP
### Based on https://gist.github.com/prwhite/8168133#gistcomment-2278355.
help:
	@echo ''
	@echo 'Usage:'
	@echo '  make <target>'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-\_0-9]+:|^# .*/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  %-35s %s\n", helpCommand, helpMessage; \
		} else { \
			printf "\n"; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)
.PHONY: help