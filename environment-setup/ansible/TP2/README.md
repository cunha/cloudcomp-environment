# Starting the cluster configuration with ansible
Currently all the configuration, package installation is done via ansible, the playbook-tp2.yml contains the multiple roles that are used to achieve final cluster configuration. It will run:

1. Install Packages and do initial user creation (admins and students)
2. The monitoring-service role creates an instance of redis and starts the monitoring service as part of the TP3.
3. Installs docker, k3s and does general kubernetes configurations.
4. Creates all the kubernetes service users and setup their roles and permissions.
5. Permissions were updated to allow users to only create pvcs to a specific storage class and within that class to only create one pvc and disallow all others. (new)
5. Installs rancher and exposes it on port 30443, creates all users in rancher. (new)
6. Installs argocd and exposes it on port 31443 and creates all users in argocd.
7. Setup the firewall denying all requests from the outside world except for the SSH Port. (new)

After running the ansible playbook in the cluster (namely playbook-tp2.yml) all of the above will be performed. Keep an eye out for the logs that it throws as the administrator password for rancher and ansible will be printed out. If you missed that, you can also use rancher's command in the cluster vm fetch such password. It's random but it's deterministic so it shouldn't change through runs for the same host machine. The command below can be used to get the current bootstrap password:

```
kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{ .data.bootstrapPassword|base64decode}}{{ "\n" }}'
```

After the cluster is configured, an admin must login to rancher for the first time for the login process to be enabled. Such user must fetch the password using the command above in the cluster, go to the rancher dashboard login page in the port 30443 and go through the login process by using the username admin and password echoed by the command above.

The same password will be used as initial passwords for both rancher and ansible admin accounts.

# Starting cluster configuration from scratch

### Manual Kubernetes setup (only in case of error)

The Kubernetes playbook will try to init a new K8s cluster. If this part
gets error, the following steps can be done only in master:

1. Start a new cluster: `sudo kubeadm init  --pod-network-cidr=10.244.0.0/16`.
   Note: if this stage fails, check item `Error 1`.

2. Set permissions:

    ```bash
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown hadoop:hadoop $HOME/.kube/config
    ```

3. Start a flannel network: `sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml`

4. In each worker node, run the join command specified in the output, something like: `kubeadm join <IP>:6443 --token <TOKEN>`

#### Troubleshooting

* If you need to restart K8s configuration, run:

    ```{bash}
    sudo kubeadm reset
    rm -rf /root/.kube
    rm -rf /etc/cni/net.d
    iptables -F
    iptables -t nat -F
    systemctl reload docker containerd
    ```

* If you restart the VM and K3s is not back up, you can re-run the kubernetes playbook, just comment out the `kubeadm --init` task as that cannot be run a second time.

* You may need to untaint the master node to allow processes to run on
  it: `kubectl taint node --all node-role.kubernetes.io/master:NoSchedule-` and/or
  `kubectl taint node --all node-role.kubernetes.io/control-plane:NoSchedule-`


* **Error 1: kubeadm init shows kubelet isn't running or healthy**

   * Solution 1:
   > [*Deprecated*] Starting from Kubernetes 1.22 recommends to use systemd cgroup. Check solution 2.

    Depending on Docker/K8s versions, an error like "kubeadm init shows
    kubelet isn't running or healthy" could appear.  In order to solve this,
    first, find Docker cgroup (`docker info | grep Cgroup`).  If the result
    of the above command is something like this:

    ```{text}
      Cgroup Driver: cgroupfs
      Cgroup Version: 1
    ```

    Then, update kubelet args (KUBELET_KUBECONFIG_ARGS) in
    `/etc/systemd/system/kubelet.service.d/10-kubeadm.conf` and add a
    `--cgroup-driver` flag corresponsing to docker cgroup (in this case
    cgroupfs). After modification, the result will be something like that:

    ```{text}
    Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --cgroup-driver=cgroupfs"
    ```

    Finally, run `kubeadm reset` and then `kubeadm init`.

   * Solution 2:

   Starting from Kubernetes 1.22 recommends to use systemd cgroup as Docker driver.
   In order to solve this, first, find Docker cgroup (`docker info | grep Cgroup`).  If the result
    of the above command is something like this:

    ```{text}
      Cgroup Driver: systemd
      Cgroup Version: 2
    ```

   Then, create or update the file in `/etc/docker/daemon.json` with:
   ```json
   {
      "exec-opts": ["native.cgroupdriver=systemd"]
   }
   ```
   Finally, run:

   ```
   systemctl enable docker
   systemctl daemon-reload
   systemctl restart docker
   kubeadm reset
   kubeadm init
   ```

* **Error 2: Kubernetes Pods can't reach some external ip address**

    Patch the coredns configuration to prevent a low MTU by add flags `bufsize 1024` and `force_tcp`:

    ```bash
    kubectl patch configmap/coredns \
      -n kube-system \
      --type merge \
      -p '{"data": "Corefile": ".:53 {\n    log  \n    errors\n    health {\n       lameduck 5s\n    }\n
        \   ready\n    kubernetes cluster.local in-addr.arpa ip6.arpa {\n       pods insecure\n
        \      fallthrough in-addr.arpa ip6.arpa\n       ttl 30\n    }\n    prometheus
        :9153\n    forward . /etc/resolv.conf {\n       force_tcp\n       max_concurrent
        1000\n    }\n    cache 3\n    loop\n    reload\n    loadbalance\n    bufsize 1024\n}\n"}'
    ```

    Check the update using `kubectl get -n kube-system configmaps
    coredns -o jsonpath`.

    Another possible solution is due firewall. Check if lo and cni0 interfaces arent blocked.

    > The CNI plugin is responsible for inserting a network interface into the container network namespace
      and making any necessary changes on the host.

* **Error 3: Constant kube-system pod restard due to SandboxChanged under ubuntu Jammy**

   When installing a master node under Ubuntu jammy, the base kube-system pods (etcd, kube-apiserver, kube-proxy...) restarts every few minutes. The etcd pod restarts because of a SandboxChanged.

   ```
   Normal   SandboxChanged  57s                    kubelet  Pod sandbox changed, it will be killed and re-created.
   ```

   This error is referenced by [Issue #110177][issue#110177] and the solution is describe as follows:

   ```
   sudo mkdir -p /etc/containerd/
   containerd config default | sudo tee /etc/containerd/config.toml
   sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
   sudo service containerd restart
   sudo service kubelet restart
   ```

   [issue#110177]: https://github.com/kubernetes/kubernetes/issues/110177


* **Error 4: kubelet 1.26.0 restart due unknown service runtime.v1.RuntimeService**

   Kubeadm init has completed successfully but kubelet is not starting and gives error:

   ```
   "failed to run Kubelet: validate service connection: CRI v1 runtime API is not implemented for endpoint \"unix:///run/containerd/containerd.sock\": rpc error: code = Unimplemented desc = unknown service runtime.v1.RuntimeService"
   ```

   This is documented by [Issue #7799][issue#7799]. Starting to v1.26, Kubernetes if you use `containerd`, you will need to upgrade to `containerd` version 1.6.0 or downgrade your version to v1.25.5.


   [issue#7799]: https://github.com/containerd/containerd/issues/7799

* **Error 5: Docker can't resolve to pypi.org**
Some students have reported that Docker sometimes stop resolving to pypi.org, other domains might also be affected but this is the one that was reported. To resolve such issue, restarting the docker services should be ok.

## Adding students users (system, HDFS and Kubernetes)

1. Add each user's public key inside folder `ansible/pubkeys` in the
   following pattern: `username.pub`

2. Insert each username in a variable called `users` in file
   `ansible/group_vars/all.yml`, like:

    ```yaml
    users:
      - cunha
      - lucasmsp
      - xulambs
    ```

3. Run command: `ansible-playbook -i hosts.ini playbook-users.yml`

## Configuring the Redis server

1. After installing (using `install-packages`), update the
   `/etc/redis/redis.conf` file:

    - Replace `bind 127.0.0.1 ::1` to `bind 0.0.0.0`;
    - Set `protected-mode` to `no`.  Note that this is dangerous if the
      machine is reachable from the external world.
    - **Deprecated:** Find the line specifying the supervised directive. By default, this line
      is set to `no`. However, to manage Redis as a service, set the supervised
      directive to `systemd` (Ubuntu’s init system).

      > There is a bug in Ubuntu 22.04
      [Issue](https://github.com/redis/redis/issues/8443#issuecomment-1317119745),
      it's better to not change the supervised setting;

2. Restart Redis using `sudo /etc/init.d/redis-server restart` (or `sudo systemctl restart redis.service` when using `systemd`)
