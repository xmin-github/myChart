#!/bin/bash

HELM_BIN="${HELM_BIN:-helm}"
set -ueo pipefail

DEBUG=false
FORCE_UPDATE=""
AWS_KEY_NAME=""
K8S_SECRET_NAME=""
SECRET_SOURCE=""
SECRET_CONFIG_FILE=""
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
Import an AWS Secrets Manager Secret or AWS SSM Parameter into kubernetes
Usage:
  $ ${HELM_BIN} aws-secrets import -a <AWS_KEY_NAME> -s <aws-secrets or aws-ssm> -k <K8S_SECRET> [-u]
  $ ${HELM_BIN} aws-secrets import -f <SECRET_CONFIG_FILE> [-u]

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
            AWS_KEY_NAME="$2"
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
    -u) #force k8s secret update if secret exists 
        FORCE_UPDATE="-u" 
        shift
        ;; 
    -f)
        if [[ -z "${2-}" ]]
        then
          import_usage
            echo "Error: secret config file path is needed"
            exit 1
        else
          SECRET_CONFIG_FILE="$2"
        fi
        shift 2
        ;;
    -s)
        if [[ -z "${2-}" ]]
        then
          import_usage
            echo "Error: secret source is needed"
            exit 1
        else
          SECRET_SOURCE="$2"
        fi
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
    local k8ssecret=$3
    if [[ -z "k8ssecret" ]]
    then
      k8ssecret=$1
    fi
    
    if [[ ! -z "$4" ]]
    then
      kubectl-aws_secrets import -a "$1" -s "$2" -k "$k8ssecret" -u
    else
      kubectl-aws_secrets import -a "$1" -s "$2" -k "$k8ssecret"
    fi
    
}

import_batch() {
    if is_help "$1"
    then
      import_usage
      return
    fi
    
    if [[ ! -z "$2" ]]
    then
      kubectl-aws_secrets import -f "$1" -u
    else
      kubectl-aws_secrets import -f "$1"
    fi
    
}

validateOptions() {
  if [[ ! -z "${AWS_KEY_NAME:-}" ]] && [[ ! -z "${SECRET_CONFIG_FILE:-}" ]]
  then
    echo "-a and -f cannot be used at the same time"
    exit 1
  elif [[ ! -z "${AWS_KEY_NAME:-}" ]] && [[ -z "${SECRET_SOURCE:-}" ]]
  then
    echo " -s is required while -a used"
    exit 1
  elif [[  -z "${AWS_KEY_NAME:-}" ]] && [[ -z "${SECRET_CONFIG_FILE:-}" ]]
  then
    echo "-a or -f is required"
    import_usage
    exit 1
  else
    echo ""
  fi
}



validateOptions

case "${COMMAND_NAME:-help}" in
    get)
        if [[ -z "$AWS_KEY_NAME" ]]
        then
            get_usage
            echo "Error: AWS Secret Name is required"
            exit 1
        fi
        echo "$AWS_KEY_NAME"
        get "$AWS_KEY_NAME"
        ;;
    import)
        if [[ ! -z "${AWS_KEY_NAME:-}" ]]
        then
            import "$AWS_KEY_NAME" "$SECRET_SOURCE" "$K8S_SECRET_NAME" "$FORCE_UPDATE"
        elif  [[ ! -z "${SECRET_CONFIG_FILE:-}" ]]
        then
            import_batch "$SECRET_CONFIG_FILE" "$FORCE_UPDATE"
        else
            import_usage
        fi
        
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