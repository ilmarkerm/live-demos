ARG arch=arm64
FROM container-registry.oracle.com/database/free:23.9.0.0-${arch}
ARG vaultversion=1.20.4
ARG arch
SHELL ["/bin/bash","-c"]
RUN su -c "echo '' > /etc/dnf/vars/ociregion"
RUN su -c "dnf install vim tcpdump man-db mc tmux unzip oracle-epel-release-el8"
RUN su -c "dnf install rlwrap"
RUN echo 'export PS1="[\u@\h \W (database)]\\$ "' >> .bashrc
RUN echo 'export VAULT_ADDR=http://localhost:8200' >> .bashrc
RUN echo 'alias sqlsys="rlwrap /opt/oracle/product/23ai/dbhomeFree/bin/sqlplus / as sysdba"' >> .bashrc
RUN echo 'alias sqlplus="rlwrap /opt/oracle/product/23ai/dbhomeFree/bin/sqlplus"' >> .bashrc
RUN mkdir vault
RUN touch vault/.roleid
RUN touch vault/.secretid
RUN curl -o /tmp/vault.zip https://releases.hashicorp.com/vault/${vaultversion}/vault_${vaultversion}_linux_${arch}.zip
RUN su -c "unzip /tmp/vault.zip vault -d /usr/local/bin"
