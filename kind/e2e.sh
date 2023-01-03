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
}

if [ "$command" == "create" ]; then
  create
  deploy
elif [ "$command" == "run" ]; then
  create
  deploy
elif [ "$command" == "delete" ]; then
  kind delete cluster
else
  usage
  exit 1
fi
