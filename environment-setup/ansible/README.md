# Starting cluster configuration from scratch

## Creating hadoop user

1. Create a hadoop user with public/private keys

    ```bash
    sudo useradd --create-home hadoop  # password is disabled by default
    sudo usermod -aG sudo hadoop
    sed -i 's/%sudo ALL=(ALL:ALL) ALL/%sudo ALL=(ALL:ALL) NOPASSWD:ALL/' /etc/
    sudo su - hadoop
    ssh-keygen -b 2048 -N '' -t rsa -f /home/hadoop/.ssh/id_rsa -q
    cp .ssh/id_rsa.pub .ssh/authorized_keys
    chown -R hadoop.hadoop /home/hadoop
    ```

    If using the Vagrant VM, the provisioning script already created the
    user and its SSH pubkey.  In this case, just copy the file locally to
    allow Ansible to SSH.  Run this from the `../vagrant` directory where
    the Vagrantfile is located.

    ```bash
    vagrant ssh -c "sudo cat /home/hadoop/.ssh/id_rsa" cloud | tr -d "\r"
    ```

    The `tr -d "\r"` is needed because vagrant somehow outputs files with
    DOS linebreaks.

2. Add the public keys in all VMs, to enable SSH connections between
   them

3. Install general packages: `ansible-playbook -i hosts.ini
   install-packages.yml`

## Installing Hadoop and Spark

1. Install Hadoop (HDFS, YARN, MapReduce): `ansible-playbook -i
   hosts.ini playbook-hadoop.yml`

2. Format HDFS: `hdfs namenode -format`

3. Install Spark: `ansible-playbook -i hosts.ini playbook-spark.yml`

4. Start all processes by running `hadoop/sbin/start-all.sh`

5. If using Yarn as Spark scheduler:

    1. Create the archive: `jar cv0f spark-libs.jar -C $SPARK_HOME/jars/ .`

    2. Upload to HDFS: `hdfs dfs -put spark-libs.jar /user/spark/jars/`.

    3. For a large cluster, increase the replication count of the Spark
       archive so that you reduce the amount of times a NodeManager will
       do a remote copy. `hdfs dfs -setrep -w 1
       /user/spark/jars/spark-libs.jar` (Change the amount of replicas
       proportional to the number of total DataNodes)

    4. Set `spark.yarn.archive` in
       `/home/hadoop/spark/conf/spark-defaults.conf` to
       `/user/spark/jars/spark-libs.jar`

## Installing Docker and Kubernetes

1. Install Docker: `ansible-playbook -i hosts.ini playbook-docker.yml`

2. Install Kubernetes: `ansible-playbook -i hosts.ini playbook-kubernetes.yml`

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
    rm -rf /home/hadoop/.kube
    rm -rf /root/.kube
    rm -rf /etc/cni/net.d
    iptables -F
    iptables -t nat -F
    systemctl reload docker containerd
    ```

* If you restart the VM and K8s is not back up, you can re-run the kubernetes playbook, just comment out the `kubeadm --init` task as that cannot be run a second time.

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
