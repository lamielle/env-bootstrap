#!/bin/sh

# Compute env vars to use in a 'docker run' command
# to bootstrap a consul cluster using etcd.
#
# Based on two gists:
#
# https://gist.github.com/yaronr/aa5e9d1871f047568c84
# https://gist.github.com/philips/56fa3f5dae9060fbd100
#
# and progrium's start script from progrium/consul

bridge_ip="$(ip ro | awk '/^default/{print $3}')"
echo "bridge_ip =" $bridge_ip

machines=$(etcdctl --peers $bridge_ip:4001 ls /consul.io/bootstrap/machines 2>/dev/null)
private_ip=$COREOS_PRIVATE_IPV4

echo "machines =" $machines
echo "private_ip =" $private_ip

if [ -z "$machines" ];
then
  echo "First machine, setting consul bootstrap flag"
  flags="-bootstrap"
else
  echo "This cluster has already been bootstrapped"
  flags=$(etcdctl --peers $bridge_ip:4001 ls /consul.io/bootstrap/machines | while read line; do
          ip=$(etcdctl --peers $bridge_ip:4001 get ${line})
          echo -join ${ip}
        done)
fi

echo "Flags are:" $flags

etcdctl --peers $bridge_ip:4001 set /consul.io/bootstrap/machines/$HOSTNAME $private_ip >/dev/null

echo "Writing environment.consul..."
cat > /etc/env.d/environment.consul <<EOF
CONSUL_PORTS="-p $private_ip:8300:8300 \
              -p $private_ip:8301:8301 \
              -p $private_ip:8301:8301/udp \
              -p $private_ip:8302:8302 \
              -p $private_ip:8302:8302/udp \
              -p $private_ip:8400:8400 \
              -p $private_ip:8500:8500 \
              -p $bridge_ip:53:53/udp"
CONSUL_FLAGS="${flags}"
EOF
