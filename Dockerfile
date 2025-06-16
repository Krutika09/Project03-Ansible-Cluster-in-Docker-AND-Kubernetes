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
