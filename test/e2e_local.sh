#!/usr/bin/env bash

## Run e2e tests on local machine
## Requirement:
## - kind 0.11.0
## - kustomize

set -Eeuxo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

export KIND_CLUSTER="kind"

CLUSTER_NAME=${CLUSTER_NAME:-kind}

echo "Creating Kind cluster"
make kind-start

# shellcheck source=test/setup_test.sh
source "${DIR}"/setup_test.sh

# Deploy Mattermost Operator
make deploy

kubectl patch statefulset mysql-operator -n mysql-operator --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--mysql-versions-to-image=5.7.26=percona:5.7.26"}]'

echo "Running operators e2e..."
go test ./test/e2e --timeout 45m -v

echo "Running external DB and File Store e2e..."
go test ./test/e2e-external --timeout 15m -v
