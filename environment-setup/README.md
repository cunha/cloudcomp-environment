# 2021 Cloud Computing course

This repository contains scripts and intructions to create and mananger
a cluster with Python, Jupyter, Hadoop (HDFS, Yarn and MapReduce),
Docker, Kubernetes, ArgoCD and Redis.

The documentations contains the following topics:

- [Starting cluster configuration from scratch](./ansible/README.md)
- [Setup an ArgoCD environmet](./argocd/README.md)


## 🚀 Running Ansible

Ansible is the main tool used to configure the cluster. You can run it in two ways: from a **Docker container** (recommended to avoid local installations) or by using a **Python virtual environment** on your machine.

### 🐳 Option 1: Execution via Docker Container (Recommended)

This option is the most desirable as it allows anyone to run the Ansible playbooks without needing to install Ansible locally, depending only on **Docker**.

For use the image defined in this repository's `Dockerfile`, follow these steps:

**1. Build the Image:**

You can build the custom Docker image, which includes a specific Ansible version (`12.0.0`) and other dependencies like `curl`, `git`, and `openssh-client`:

```bash
docker build --network=host -t ansible-tp2-ufmg environment-setup/ansible/TP2/image/.
```

**2. Run the Playbooks:**

After building the image, you can run the playbooks by mounting the local working directory as a volume (-v $(pwd):/mnt) inside the container:

- **Connection Check:** To test if Ansible can connect to the hosts:
```bash
docker run -ti --rm --net=host -v $(pwd):/mnt -w=/mnt ansible-tp2-ufmg ansible all -i environment-setup/ansible/hosts.ini -m ping
```

- **Main Playbook Execution:** To run the configuration playbook:
```bash
docker run -ti --rm --net=host -v $(pwd):/mnt -w=/mnt ansible-tp2-ufmg ansible-playbook -i environment-setup/ansible/hosts.ini environment-setup/ansible/TP2/playbook-tp2.yml
```
💡 Tip: If you are using VS Code, these execution commands are mapped as tasks in the tasks.json file for quick access.

### Option 2: Installation in a Python Virtual Environment (venv)

If you prefer to install Ansible locally, the best practice is to use a Python virtual environment (venv) to isolate project dependencies from your operating system.

**1. Create and Activate the Virtual Environment:**

From the project's root directory, create and activate the virtual environment (you can replace venv with your preferred name):
```bash
python3 -m venv venv
source venv/bin/activate
```

**2.Install Ansible:**

Install the required Ansible version. The project currently uses version `12.0.0`:
```bash
pip install 'ansible==12.0.0'
```

**3. Run the Playbooks:**

With the environment activated, you can run Ansible directly:

- **Connection Check:** 
```bash
ansible all -i hosts.ini -m ping
```

- **Main Playbook Execution:** 
```bash
ansible-playbook playbook-tp2.yml -i hosts.ini
```

**4. Deactivate the Environment:**

When finished, deactivate the virtual environment:
```bash
deactivate
```