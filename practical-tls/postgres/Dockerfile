FROM postgres:18.6
COPY install.sh /usr/local/bin/
RUN su - -c "chmod 777 /usr/local/bin/*.sh && /usr/local/bin/install.sh"
