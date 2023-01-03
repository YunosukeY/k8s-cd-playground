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

if [ "$command" == "create" ]; then
  create
elif [ "$command" == "run" ]; then
  create
elif [ "$command" == "delete" ]; then
  kind delete cluster
else
  usage
  exit 1
fi
