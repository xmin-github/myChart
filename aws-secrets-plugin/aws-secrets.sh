#!/bin/bash

HELM_BIN="${HELM_BIN:-helm}"
set -ueo pipefail

DEBUG=false
FORCE_UPDATE=""
AWS_SECRET_NAME=""
K8S_SECRET_NAME=""
COMMAND_NAME=""

PARAMS=""

usage() {
    cat <<EOF
Available Commands:
  get    	get an AWS Secrets Manager secret
  import    	import an AWS Secrets Manager secret into kubernetes
  
EOF
}

get_usage() {
    cat <<EOF
Get secret from AWS Secrets Manager

Usage:
  $ ${HELM_BIN} aws-secrets get -a <AWS Secrets Name>
  
EOF
}

import_usage() {
    cat <<EOF
Import an AWS Secrets Manager secret into kubernetes
Usage:
  $ ${HELM_BIN} aws-secrets import -a <AWS_SECRET>  -k <K8S_SECRET> [-f]

EOF
}


while (( "$#" )); do
  case "$1" in
    get|import|-h|--help|help)
        COMMAND_NAME="$1"
        shift
        ;;
    -a) 
        if [[ -z "${2-}" ]]
        then
          get_usage
            echo "Error: AWS Secret Name is required"
            exit 1
        else
            AWS_SECRET_NAME="$2"
        fi
        shift 2
        ;;
    -k)
        if [[ -z "${2-}" ]]
        then
          import_usage
            echo "Error: K8S Secret Name is not provided"
            exit 1
        else
          K8S_SECRET_NAME="$2"
        fi
        shift 2
        ;;
    -f) #force k8s secret update if secret exists 
        FORCE_UPDATE="-f" 
        shift
        ;; 
  
    -*|--*=) # unsupported flags
        echo "Error: Unsupported flag $1" >&2
        exit 1
        ;;
    *)
      PARAMS="$PARAMS $1"
      echo "param $1"
      shift
      ;;
  esac
done

is_help() {
    case "$1" in
	-h|--help|help)
	    return 0
	    ;;
	*)
	    return 1
	    ;;
    esac
}


get() {
    if is_help "$1"
    then
      get_usage
      return
    fi
    kubectl-aws_secrets get -a "$1"
}

import() {
    if is_help "$1"
    then
      import_usage
      return
    fi
    local awssecret=$1
    local k8ssecret=$2
    if [[ -z "k8ssecret" ]]
    then
      k8ssecret=$1
    fi
    
    if [[ ! -z "$3" ]]
    then
      kubectl-aws_secrets import -a "$1" -k "$2" -f
    else
      kubectl-aws_secrets import -a "$1" -k "$2"
    fi
    
}

case "${COMMAND_NAME:-help}" in
    get)
        if [[ -z "$AWS_SECRET_NAME" ]]
        then
            get_usage
            echo "Error: AWS Secret Name is required"
            exit 1
        fi
        echo "$AWS_SECRET_NAME"
        get "$AWS_SECRET_NAME"
        ;;
    import)
        if [[ -z "$AWS_SECRET_NAME" ]]
        then
            import_usage
            echo "Error: AWS Secret Name is required."
            exit 1
        fi
        import "$AWS_SECRET_NAME" "$K8S_SECRET_NAME" "$FORCE_UPDATE"
        ;;
    --help|-h|help)
        usage
        ;;
    *)
        usage
        exit 1
        ;;
esac
exit ${helm_exit_code:-0}