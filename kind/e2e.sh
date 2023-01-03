#!/usr/bin/env bash

set -eu

usage() {
  cat <<USAGE
  Usage:
  - e2e.sh create
  - e2e.sh run
  - e2e.sh delete
USAGE
}

if [ "$#" != 1 ]; then
  usage
  exit 1
fi

command="$1"
repo_dir="$(git rev-parse --show-toplevel)"

create () {
  kind create cluster --config "${repo_dir}/kind/cluster.yaml"
}

deploy () {
  helmfile apply -f "${repo_dir}/k8s/charts/argo-cd/helmfile.yaml"
  kubectl create secret generic -n argocd private-repo-creds \
    --from-literal=type=git \
    --from-literal=url=https://github.com/YunosukeY \
    --from-literal=username=YunosukeY \
    --from-file=password="${repo_dir}/github-pat"
  kubectl label secret -n argocd private-repo-creds argocd.argoproj.io/secret-type=repo-creds
  kubectl wait -n argocd \
    deploy/argo-cd-argocd-applicationset-controller \
    deploy/argo-cd-argocd-redis \
    deploy/argo-cd-argocd-repo-server \
    deploy/argo-cd-argocd-server \
    --for condition=available --timeout=300s
  kubectl wait -n argocd po/argo-cd-argocd-application-controller-0 --for condition=ready --timeout=300s

  kubectl create namespace app
  kubectl create secret generic -n app awssm-secret --from-env-file="${repo_dir}/access-key.env"

  kubectl apply -f "${repo_dir}/k8s/cd/app-of-apps.yaml"
}

open_dashboard () {
  kubectl apply -f "${repo_dir}/k8s/app/node-port.yaml"

  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d | pbcopy
  echo passowrd copied

  open http://localhost:8080
}

run () {
  sleep 30 # wait sync
  kubectl wait -n ingress deploy/ingress-nginx-controller --for condition=available --timeout=300s
  kubectl wait -n kube-system deploy/external-secrets-cert-controller deploy/external-secrets-webhook --for condition=available --timeout=300s
  kubectl wait -n app deploy/app-deployment --for condition=available --timeout=300s
  sleep 3 # hack

  curl localhost/api/v1/public/todos
}

if [ "$command" == "create" ]; then
  create
  deploy
  open_dashboard
elif [ "$command" == "run" ]; then
  create
  deploy
  run
elif [ "$command" == "delete" ]; then
  kind delete cluster
else
  usage
  exit 1
fi
