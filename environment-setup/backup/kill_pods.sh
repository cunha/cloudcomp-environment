kubectl get pods --all-namespaces | grep -E 'ImagePullBackOff|ErrImagePull|Evicted|Error|Completed|ContainerStatusUnknown' | awk '{print $2 " --namespace=" $1}' | xargs kubectl delete pod
