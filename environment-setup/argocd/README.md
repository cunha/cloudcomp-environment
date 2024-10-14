# ArgoCD

This documentation explains how to install, test, create new users and
setup permissions.

## Installing ArgoCD

These steps follow ArgoCD's [Getting Started][argocd-getting-started]
instructions.

1. Download and enable the CLI interface application:

    ```bash
    curl -sSL -o /usr/local/bin/argocd \
            https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    chmod +x /usr/local/bin/argocd
    ```

2. Installing ArgoCD:

    ```bash
    kubectl create namespace argocd
    kubectl apply -n argocd -f \
            https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    ```

3. Expose the ArgoCD service using a NodePort (no LoadBalancer because
   we do not get external IP addresses on the LoadBalancer service).
   The following will forward ports 31080 and 31443 to ArgoCD.

    ```bash
    kubectl patch svc argocd-server -n argocd -p '{
        "spec": {
            "type": "NodePort",
            "ports": [
                {"port": 80, "protocol": "TCP", "targetPort": 8080, "nodePort": 31080},
                {"port": 443, "protocol": "TCP", "targetPort": 8080, "nodePort": 31443}
            ]
        }
    }'
    ```

4. (Optional) Log in to ArgoCD and change the password for the admin.
   The first command prints out the *initial* secret generated during
   the deployment.  The new password set with `update-password` must
   then be set on Ansible before running the playbook to manage user
   accounts below.

    ```bash
    kubectl -n argocd get secret argocd-initial-admin-secret \
            -o jsonpath="{.data.password}" | base64 -d; echo
    argocd login localhost:31443 --username admin --password above --insecure
    argocd account update-password
    argocd login localhost:31443 --username admin --password newPass --insecure
    ```

[argocd-getting-started]: https://argo-cd.readthedocs.io/en/stable/getting_started/

## Test example

1. Submit the application (with a logged user):

    ```bash
    argocd app create guestbook \
            --repo https://github.com/argoproj/argocd-example-apps.git \
            --path guestbook \
            --dest-server https://kubernetes.default.svc \
            --dest-namespace default
    ```

2. Once the guestbook application is created, you can now view its
   status: `argocd app get guestbook`

3. The application status is initially in OutOfSync state since the
   application has yet to be deployed, and no Kubernetes resources have
   been created.  To sync (deploy) the application, run: `argocd app
   sync guestbook`

4. You should then be able to browse to the application by using SSH
   port forwarding towards it's ClusterIP.

## Setting up user accounts and projects

These tasks can be performed with the `playbook-users-argocd` through
Ansible.  These steps are documented in this [Medium
article][argocd-user-accounts].

1. Create accounts for all users on ArgoCD.  This is done by extending
   the ConfigMap `argocd-cm`.  We need to add entries of the form
   `accounts.{{username}}` inside the `data` property.  We do this in
   Ansible by generating a patch file.  You can verify that accounts
   have been created correctly using `argocd account list`.

2. Create projects for all users on ArgoCD and set user default
   passwords.

3. Give users permissions on their projects.  We do this by adding the
   following for each user on the `argocd-rbac-cm` ConfigMap:

    ```text
        data:
          policy.default: role:''
          policy.csv: |
            p, role:cunha, applications, *, cunha-project/*, allow
            p, role:cunha, projects, get, cunha-project, allow
            p, role:cunha, repositories, *, *, allow
            p, role:cunha, clusters, get, *, allow
            g, cunha, role:cunha
    ```

4. To test the ability of a user to set-up applications in ArgoCD, we
   need to log in and specify the user's project when creating the
   application:

    ```bash
    argocd login localhost:31443
    argocd app create guestbook \
            --repo https://github.com/argoproj/argocd-example-apps.git \
            --path guestbook \
            --dest-server https://kubernetes.default.svc \
            --dest-namespace cunha
            --project cunha-project
    ```

[argocd-user-accounts]: https://medium.com/geekculture/create-a-new-user-in-argocd-using-the-cli-and-configmap-8cbb27cf5904

## TroubleshootingBackup and Restore ArgoCD configurations

* To backup ArgoCD configurations (useful for later reference) use:

    ```bash
    scp -P 4422 export-config.sh localhost:
    ssh localhost -p 4422 /home/cunha/export-config.sh > argocd-backup.yaml
    ```

* To restore a previous configuration from a backup (inside the VM):

    ```bash
    docker run -i --network host -v ~/.kube:/home/argocd/.kube \
            --rm argoproj/argocd argocd admin import -n argocd - \
            < backup.yaml
    ```
