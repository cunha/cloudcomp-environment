#!/bin/bash
set -eu

STUDENT=$1
echo "Setting up user: $STUDENT"

# We added a token generation entry to the k8s-users.yml to address the
# change in K8s 1.24, which no longer adds secrets to serviceaccounts by
# default:
# https://itnext.io/big-change-in-k8s-1-24-about-serviceaccounts-and-their-secrets-4b909a4af4e0

token=$(kubectl -n "${STUDENT}" describe secret "${STUDENT}" | grep token: | awk '{print $2;}')
certs=$(kubectl -n "${STUDENT}" get secret "${STUDENT}" -o "jsonpath={.data.ca\.crt}")

ip=$(ip addr show dev eth0 | grep -oEe 'inet [0-9.]+' | cut -d" " -f2)

mkdir -p "/home/$STUDENT/.kube/"

echo """
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $certs
    server: https://$ip:6443
  name: kubernetes

contexts:
- context:
    cluster: kubernetes
    namespace: $STUDENT
    user: $STUDENT
  name: $STUDENT

current-context: $STUDENT
kind: Config
preferences: {}

users:
- name: $STUDENT
  user:
     token: $token
     client-key-data: $certs
""" > "/home/$STUDENT/.kube/config"

sudo chown "$STUDENT:$STUDENT" -R "/home/$STUDENT/.kube"
