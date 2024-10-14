#!/bin/bash
set -eu

sudo -u hadoop chmod 644 /home/hadoop/.kube/config
sudo -u hadoop docker run --network host \
        -v /home/hadoop/.kube:/home/argocd/.kube \
        --rm argoproj/argocd argocd admin export -n argocd
sudo -u hadoop chmod 600 /home/hadoop/.kube/config