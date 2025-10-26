
https://developer.hashicorp.com/vault/install
https://developer.hashicorp.com/terraform/install

```
docker image pull hashicorp/vault
docker image pull container-registry.oracle.com/database/free:latest-lite
docker image pull oraclelinux:9
docker image pull mysql:8.4-oraclelinux9
```

```
docker run -p 8200:8200 --interactive --tty --mount src=/Users/ilmarkerm/live-demos,target=/live-demos,type=bind --name hashidemo-vault oraclelinux:9

docker run --name hashidemo-oracle -p 1521:1521 -e ORACLE_PWD=Oracle123 --tty --mount src=/Users/ilmarkerm/live-demos,target=/live-demos,type=bind container-registry.oracle.com/database/free:latest

docker run -it --name hashidemo-sshd -e USER_NAME=oracle -e LOG_STDOUT=true lscr.io/linuxserver/openssh-server:latest

#docker run --interactive --tty --mount src=/Users/ilmarkerm/live-demos,target=/live-demos,type=bind --name hashidemo-linux oraclelinux:9


docker start --interactive hashidemo-vault


docker logs v1vault
```
