FROM docker.io/centos
MAINTAINER root squash (nathan@rootsquash.com)

COPY ./usr/bin/container-entrypoint /usr/bin/

RUN rm -f /etc/localtime && \
    ln -s /usr/share/zoneinfo/US/Central /etc/localtime && \
    yum clean all && \
    yum -y update && \
    yum -y install openssh-server openssl && \
    rm -rf /var/cache/yum && \
    mkdir -p /home/sftp_users/ftpuser && \
    groupadd sftp_users -g 1001 && \
    useradd ftpuser -r -u 1001 -g 1001 -s /bin/bash -d /home/sftp_users/ftpuser -c "FTP User" && \
    usermod -p $(echo <<password>> | openssl passwd -1 -stdin) ftpuser && \
    chown -R ftpuser.sftp_users /home/sftp_users/ftpuser && \
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -t rsa -N '' && \
    ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -t ecdsa -N '' && \
    ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -t ed25519 -N '' && \
    rm -f /var/run/nologin && \
    echo "Authorized uses only.  All activity may be monitored and reported." > /etc/issue && \
    sed -e 's/#Banner none/Banner \/etc\/issue/' -i /etc/ssh/sshd_config && \
    sed -e 's/Subsystem/#Subsystem/' -i /etc/ssh/sshd_config && \
    echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config && \
    echo "Match User ftpuser" >> /etc/ssh/sshd_config && \
    echo " ChrootDirectory /home/sftp_users/ftpuser" >> /etc/ssh/sshd_config && \
    echo " AllowTCPForwarding no" >> /etc/ssh/sshd_config && \
    echo " X11Forwarding no" >> /etc/ssh/sshd_config && \
    echo " ForceCommand internal-sftp" >> /etc/ssh/sshd_config && \
    yum -y remove openssl make

EXPOSE 22

ENTRYPOINT ["container-entrypoint"] 
CMD ["/sbin/sshd","-D","-e"]
