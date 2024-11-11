#!/bin/bash
set -eu
is_file_exists(){

    local file="$1"

    # [ (test) could have been used here
    # Is the name given a regular file?        
    if  [[ -f $file ]]     # quotes not required with [[ (but are with [ )
    then
        return 0
    else
        return 1
    fi
}
STUDENT=$1
CURRENT_MACHINE_IP=$2
CLUSTER_NAME=$3
if is_file_exists "/home/$STUDENT/.kube/config"
then
    exit 0
fi
echo "Setting up user: $STUDENT"

set -o errexit

token=$(kubectl -n "${STUDENT}" get secret/"${STUDENT}" -o jsonpath="{.data.token}" | base64 --decode)
certs=$(kubectl -n "${STUDENT}" get secret/"${STUDENT}" -o jsonpath="{.data.ca\.crt}")

mkdir -p "/home/$STUDENT/.kube/"

echo """
apiVersion: v1
kind: Config

clusters:
- cluster:
    certificate-authority-data: $certs
    server: https://$CURRENT_MACHINE_IP:6443
  name: $CLUSTER_NAME

contexts:
- context:
    cluster: $CLUSTER_NAME
    user: $STUDENT
    namespace: $STUDENT
  name: $STUDENT@$CLUSTER_NAME

current-context: $STUDENT@$CLUSTER_NAME

users:
- name: $STUDENT
  user:
     token: $token
""" > "/home/$STUDENT/.kube/config"

cp "/home/$STUDENT/.kube/config" "/home/$STUDENT/kube_config_cluster.yml"
sudo chown "$STUDENT:$STUDENT" -R "/home/$STUDENT/.kube"
sudo chown "$STUDENT:$STUDENT" -R "/home/$STUDENT/kube_config_cluster.yml"