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
  wget https://github.com/xmin-github/kubectl-aws-secrets/raw/master/bin/kubectl-aws-secrets.tar.gz
  file kubectl-aws-secrets.tar.gz
  sudo tar -xzvf kubectl-aws-secrets.tar.gz
  sudo cp kubectl-aws_secrets /usr/local/bin
#fi
