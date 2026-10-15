FROM oraclelinux:9
RUN dnf upgrade
COPY install.sh start.sh /root/
RUN chmod u+x /root/*.sh && /root/install.sh

ENTRYPOINT ["/root/start.sh"]
