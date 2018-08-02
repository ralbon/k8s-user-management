#!/bin/bash
set -e

# Add user to k8s namespace using service account and create kubeconfig


#####################################################
#  Helper functions
#####################################################
show_help () {
	echo "This script will help you create new user on k8s cluster and privileges to resources on k8s cluster's namespace. If the namespace doesn't exist, the script will create it."
	echo "  "
	echo "	Usage: ./add-user.sh USER NAMESPACE ROLE"
	echo "  "
	echo "  ROLE options: admin, dev"
	echo "  "
	echo "  Example: ./add-user.sh jean.bonbeurre namespace-bidule admin"
}

check_kubectl_installed () {
	which kubectl > /dev/null && { echo kubectl; return; }
}

check_kubeconfig_exist_and_is_readable () {
	test -r $DIR_KUBECONFIG/.kube/config && { echo kubeconfig; return; }
}

create_user_role_heapster () {
  USER_ROLE_HEAPSTER=$(P_NAMESPACE=$1 envsubst < $DIR/user_role_heapster.yml.j2)

  cat <<EOF | kubectl apply -f -
  $USER_ROLE_HEAPSTER
EOF
}

create_user_role_binding_heapster () {
  USER_ROLE_BINDING_HEAPSTER=$(P_USER=$1 P_NAMESPACE=$2 envsubst < $DIR/user_role_binding_heapster.yml.j2)

  cat <<EOF | kubectl apply -f -
  $USER_ROLE_BINDING_HEAPSTER
EOF
}

create_user_role_dashboard () {
  USER_ROLE_DASHBOARD=$(P_NAMESPACE=$1 envsubst < $DIR/user_role_dashboard.yml.j2)

  cat <<EOF | kubectl apply -f -
  $USER_ROLE_DASHBOARD
EOF
}

create_user_role_binding_dashboard () {
  USER_ROLE_BINDING_DASHBOARD=$(P_USER=$1 P_NAMESPACE=$2 envsubst < $DIR/user_role_binding_dashboard.yml.j2)

  cat <<EOF | kubectl apply -f -
  $USER_ROLE_BINDING_DASHBOARD
EOF
}

create_user_role_monitoring () {
  USER_ROLE_MONITORING=$(cat $DIR/user_role_monitoring.yml.j2)

  cat <<EOF | kubectl apply -f -
  $USER_ROLE_MONITORING
EOF
}

create_user_role_binding_monitoring () {
  USER_ROLE_BINDING_MONITORING=$(P_USER=$1 P_NAMESPACE=$2 envsubst < $DIR/user_role_binding_monitoring.yml.j2)

  cat <<EOF | kubectl apply -f -
  $USER_ROLE_BINDING_MONITORING
EOF
}

create_dev_role_binding () {
  DEV_ROLE_BINDING=$(P_USER=$1 P_NAMESPACE=$2 envsubst < $DIR/dev_role_binding.yml.j2)

  cat <<EOF | kubectl apply -f -
  $DEV_ROLE_BINDING
EOF
}

create_admin_role_binding () {
  ADMIN_ROLE_BINDING=$(P_USER=$1 P_NAMESPACE=$2 envsubst < $DIR/admin_role_binding.yml.j2)

  cat <<EOF | kubectl apply -f -
  $ADMIN_ROLE_BINDING
EOF
}

generate_kube_config_file () {
    KUBE_CONFIG_FILE=$(P_USER=$1 P_NAMESPACE=$2 P_CLUSTER_NAME=$3 P_SERVER=$4 P_CERT_AUTH_DATA=$5 P_USER_TOKEN=$6 envsubst < $DIR/kube_config_file.yml.j2)

	cat <<EOF > $USER-$NAMESPACE-kubeconfig
    $KUBE_CONFIG_FILE
EOF
}

check_something_exist () {
    P_QUERY=$1
    EXPECTED=$2
    ACTUAL=$(kubectl get $P_QUERY --no-headers=true -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep  "^$EXPECTED$")

    if [[ $EXPECTED == $ACTUAL ]]
        then
        echo "exist"
        return
    fi
}

check_user_exist () {
    P_USER=$1
    P_NAMESPACE=$2
	echo $(check_something_exist "sa -n $P_NAMESPACE" $P_USER)
}

check_namespace_exist () {
    P_NAMESPACE=$1
	echo $(check_something_exist "ns" $P_NAMESPACE)
}


#####################################################
#  Main function : orchestrates the kubectl commands
#####################################################
main () {
    ## CHECK PREREQUISITES INSTALLED

    if [[ $(check_kubectl_installed) != "kubectl" ]]
        then
        echo "Kubectl must installed on your machine, please install it before run this script"
        exit 1
    fi

    if [[ $(check_kubeconfig_exist_and_is_readable) != "kubeconfig" ]]
        then
        echo "Kubeconfig file may not exist or being readable"
        exit 1
    fi

    ## CHECK OPTIONS ARE VALID

    if [[ $1 == "help" || $1 == "--help" || $1 == "-h" ]]
        then
        show_help
        exit 0
    fi

    if [[ $USER == ""  || $NAMESPACE == "" || $ROLE == "" ]]
        then
        show_help
        exit 1
    fi

    if [[ $3 != "admin" && $3 != "dev" ]]
        then
        echo "ROLE must be set to admin or dev"
        exit 1
    fi

    ## CREATE NAMESPACE

    if [[ $(check_namespace_exist $NAMESPACE) == "exist" ]]
        then
            echo "The namespace $NAMESPACE exists"
        else
            kubectl create ns $NAMESPACE
    fi

    ## CREATE USER ACCOUNT

    if [[ $(check_user_exist $USER $NAMESPACE) == "exist" ]]
        then
            echo "The user exists. This script will grant roles for this user"
        else
            kubectl create sa $USER -n $NAMESPACE
    fi

    case $3 in
        "dev")
            create_dev_role_binding $USER $NAMESPACE
            create_user_role_heapster $NAMESPACE
            create_user_role_binding_heapster $USER $NAMESPACE
            ;;
        "admin")
            create_admin_role_binding $USER $NAMESPACE
            create_user_role_dashboard $NAMESPACE
            create_user_role_binding_dashboard $USER $NAMESPACE
            create_user_role_monitoring
            create_user_role_binding_monitoring $USER $NAMESPACE
    esac


    SECRET=$(kubectl get sa $USER -n $NAMESPACE -o json | jq -r .secrets[].name)
    USER_TOKEN=$(kubectl get secret $SECRET -n $NAMESPACE -o json | jq -r '.data["token"]' | openssl base64 -d -A)
    CLUSTER_NAME=$(cat $DIR_KUBECONFIG/.kube/config | grep -C 2 server | grep name | awk -F ': ' '{print $2}')
    SERVER=$(cat $DIR_KUBECONFIG/.kube/config | grep server | awk -F ': ' '{print $2}')
    CERT_AUTH_DATA=$(cat $DIR_KUBECONFIG/.kube/config | grep certificate-authority-data | awk -F ': ' '{print $2}')

    echo "Generate kube config file for $USER"

    generate_kube_config_file $USER $NAMESPACE $CLUSTER_NAME $SERVER $CERT_AUTH_DATA $USER_TOKEN
}


#####################################################
#  Entrypoint
#####################################################
USER=$1
NAMESPACE=$2
ROLE=$3

DIR_KUBECONFIG="$HOME"
DIR=$(dirname $0)/src
main $USER $NAMESPACE $ROLE
