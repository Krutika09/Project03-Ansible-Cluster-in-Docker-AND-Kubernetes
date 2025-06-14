# Ansible Cluster Setup Using Docker & Kubernetes

## 📌 Objective
To manually set up an **Ansible Master-Node architecture** using a **custom-built Red Hat-based image**, without using pre-built Ansible images. This project demonstrates cluster setup in both Docker containers and Kubernetes pods.

---

## 🧱 System Configuration Stack

| Component        | Technology             |
|------------------|-------------------------|
| OS Base          | AlmaLinux 8 / Rocky Linux (RHEL-compatible) |
| Automation Tool  | Ansible                 |
| Container Runtime| Docker                  |
| Orchestration    | Kubernetes              |
| Communication    | SSH between Master and Nodes |


## 🐳 Part A: Create Ansible Cluster in Docker Containers

### 🔹 Step 1: Create a Custom Dockerfile with Ansible

```Dockerfile
# Dockerfile
# ansible configurations using redhat
FROM redhat/ubi9

ENV container=docker \
    ANSIBLE_FORCE_COLOR=true \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN dnf update -y && \
    dnf install -y python3 python3-pip openssh-server openssh-clients sudo vim passwd && \
    pip3 install --upgrade pip && \
    pip3 install ansible && \
    echo "root:root" | chpasswd && \
    mkdir -p /var/run/sshd /run/sshd && \
    ssh-keygen -A && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
````

### 🔹 Step 2: Build the Docker Image

```bash
docker build -t rhel-ansible .
```

### 🔹 Step 3: Create Docker Network

```bash
docker network create ansible-net
```

### 🔹 Step 4: Run Ansible Master and Nodes

```bash
# Master Node
docker run -dit --name ansible-master --network ansible-net rhel-ansible

# Worker Nodes
docker run -dit --name ansible-node1 --network ansible-net rhel-ansible
docker run -dit --name ansible-node2 --network ansible-net rhel-ansible
```

---

### 🔹 Step 5: Configure SSH Access from Master to Nodes

```bash
docker exec -it ansible-master bash

# Inside ansible-master:
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
dnf install -y sshpass

# Copy SSH keys to worker nodes
sshpass -p root ssh-copy-id root@ansible-node1
sshpass -p root ssh-copy-id root@ansible-node2
```

---

### 🔹 Step 6: Create Ansible Inventory File

```bash
mkdir -p /etc/ansible
vim /etc/ansible/hosts
```

Paste this in the `hosts` file:

```ini
[all]
node1 ansible_host=<ip-of-node1> ansible_user=root ansible_password=root
node2 ansible_host=<ip-of-node2> ansible_user=root ansible_password=root
```

Set environment variable to skip host key checking:

```bash
export ANSIBLE_HOST_KEY_CHECKING=False
```

---

### 🔹 Step 7: Test Connection

```bash
ansible all -m ping
```

---

## ☸️ Part B: Create Ansible Cluster in Kubernetes Pods

### 🔹 Step 1: Push Docker Image to DockerHub

```bash
docker tag rhel-ansible <your-dockerhub-username>/rhel-ansible:v1
docker push <your-dockerhub-username>/rhel-ansible:v1
```

---

### 🔹 Step 2: Kubernetes YAML for Master Pod

```yaml
# ansible-master.yaml
apiVersion: v1
kind: Pod
metadata:
  name: ansible-master
  labels:
    role: master
spec:
  containers:
  - name: master
    image: <your-dockerhub-username>/rhel-ansible:v1
    ports:
    - containerPort: 22
```

---

### 🔹 Step 3: Kubernetes YAML for Node Deployment

```yaml
# ansible-node-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ansible-node
spec:
  replicas: 2
  selector:
    matchLabels:
      role: node
  template:
    metadata:
      labels:
        role: node
    spec:
      containers:
      - name: node
        image: <your-dockerhub-username>/rhel-ansible:v1
        ports:
        - containerPort: 22
```

---

### 🔹 Step 4: Apply Kubernetes YAMLs

```bash
kubectl apply -f ansible-master.yaml
kubectl apply -f ansible-node-deploy.yaml
```

---

### 🔹 Step 5: Get Pod IPs

```bash
kubectl get pods -o wide
```

---

### 🔹 Step 6: SSH Config from Master to Node Pods

```bash
kubectl exec -it ansible-master -- bash

# Inside master pod:
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
dnf install -y sshpass

sshpass -p root ssh-copy-id root@<node1-pod-ip>
sshpass -p root ssh-copy-id root@<node2-pod-ip>

# Optional (avoid prompt for fingerprint)
ssh-keyscan -H <node1-pod-ip> >> ~/.ssh/known_hosts
ssh-keyscan -H <node2-pod-ip> >> ~/.ssh/known_hosts
```

---

### 🔹 Step 7: Create Inventory & Ping Test

```bash
mkdir -p /etc/ansible
vim /etc/ansible/hosts
```

Paste this in the `hosts` file:

```ini
[all]
node1 ansible_host=<ip-of-node1> ansible_user=root ansible_password=root
node2 ansible_host=<ip-of-node2> ansible_user=root ansible_password=root
```

Test connectivity:

```bash
ansible all -m ping
```

---

## 🔧 Optional: Sample Playbook to Install HTTPD

```yaml
# install_httpd.yaml
- name: Install Apache Web Server
  hosts: node
  become: true
  tasks:
    - name: Install httpd
      yum:
        name: httpd
        state: present
    - name: Start httpd
      service:
        name: httpd
        state: started
        enabled: true
```

Run the playbook:

```bash
ansible-playbook install_httpd.yaml
```

Check Apache version:

```bash
ansible node2 -m shell -a "httpd -v"
```

---

## ✅ Final Outcome

* Ansible Master is able to connect and control Nodes inside **Docker** and **Kubernetes**.
* You’ve built everything **manually** using Red Hat-based **custom images**.
* This setup mimics a **real-world automation infrastructure**.
