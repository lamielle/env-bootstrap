FROM progrium/busybox:latest
MAINTAINER Alan LaMielle <alan.lamielle@gmail.com>

RUN opkg-install curl bind-tools

VOLUME ["/etc/env.d"]
CMD ["/bin/consul-bootstrap.sh"]

ADD consul-bootstrap.sh /bin/
ADD rethinkdb-bootstrap.sh /bin/
ADD discover-service.sh /bin/
