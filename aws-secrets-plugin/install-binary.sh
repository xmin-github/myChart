#!/usr/bin/env bash

set -ueo pipefail
case "${HELM_BIN}" in
    helm)
        HELM_DIR="$(dirname $(command -v helm))"
        ;;
    *)
        HELM_DIR="$(dirname ${HELM_BIN})"
        ;;
esac
#if [[ `command -v kubectl-aws_secrets help` ]]; then
#  echo "kubectl-aws_secrets already exists"
#else
  echo "installing kubectl-aws_secrets"
  curl -sS -o kubectl-aws-secrets.tar.gz https://github.com/xmin-github/kubectl-aws-secrets/blob/master/bin/kubectl-aws-secrets.tar.gz
  file kubectl-aws-secrets.tar.gz
  sudo tar -xzvf kubectl-aws-secrets.tar.gz
  sudo cp kubectl-aws_secrets /usr/local/bin
#fi  file ubectl-aws-secrets.tar.gz
