FROM progrium/busybox:latest
MAINTAINER Alan LaMielle <alan.lamielle@gmail.com>

VOLUME ["/etc/env.d"]
CMD ["/bin/consul-bootstrap.sh"]

ADD consul-bootstrap.sh /bin/
