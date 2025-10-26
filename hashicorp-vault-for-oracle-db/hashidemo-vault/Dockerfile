ARG arch=arm64
FROM oraclelinux:9
ARG vaultversion=1.20.4
ARG terraformversion=1.13.4
ARG goversion=1.25.3
ARG arch
ARG oraclearch=aarch64
SHELL ["/bin/bash","-c"]
RUN echo '' > /etc/dnf/vars/ociregion
RUN dnf install vim tcpdump man-db mc tmux unzip gcc make git oracle-epel-release-el9
RUN curl -o /tmp/vault.zip https://releases.hashicorp.com/vault/${vaultversion}/vault_${vaultversion}_linux_${arch}.zip
RUN unzip /tmp/vault.zip vault -d /usr/local/bin
RUN curl -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/${terraformversion}/terraform_${terraformversion}_linux_${arch}.zip
RUN unzip /tmp/terraform.zip terraform -d /usr/local/bin
RUN curl -o /tmp/go.tar.gz https://dl.google.com/go/go${goversion}.linux-${arch}.tar.gz
RUN rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tar.gz
# Install instantclient
RUN curl -o /tmp/ic-basic.rpm https://download.oracle.com/otn_software/linux/instantclient/1928000/oracle-instantclient19.28-basic-19.28.0.0.0-1.el9.${oraclearch}.rpm
RUN curl -o /tmp/ic-devel.rpm https://download.oracle.com/otn_software/linux/instantclient/1928000/oracle-instantclient19.28-devel-19.28.0.0.0-1.el9.${oraclearch}.rpm
RUN dnf install /tmp/ic-basic.rpm /tmp/ic-devel.rpm
# Set shell
RUN echo 'export PS1="[\u@\h \W (vault)]\\$ "' >> /root/.bashrc
RUN echo "export PATH=/usr/local/go/bin:\$PATH" >> /root/.bashrc
RUN echo "export VAULT_ADDR=http://127.0.0.1:8200" >> /root/.bashrc
RUN echo "export VAULT_TOKEN=root" >> /root/.bashrc
# Oracle plugin compilation
RUN mkdir /root/vault-plugins
RUN mkdir /root/pkgconfig
COPY oci8.pc /root/pkgconfig/
COPY build_oracle_plugin.sh /root/
RUN . /root/build_oracle_plugin.sh
# Run Vault server
COPY vault_server_config.hcl start_vault_server.sh /root/
RUN chmod u+x /root/start_vault_server.sh
EXPOSE 8200
CMD /root/start_vault_server.sh
#ENTRYPOINT ["/bin/bash"]
