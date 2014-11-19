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

bridge_ip="$(ip route | awk '/^default/{print $3}')"
private_ip=$COREOS_PRIVATE_IPV4
echo "bridge_ip =" $bridge_ip
echo "private_ip =" $private_ip

# Atomically determine if we're the first to bootstrap
curl -L --fail http://$bridge_ip:4001/v2/keys/consul.io/bootstrap/bootstrapped?prevExist=false -XPUT -d value=$private_ip
if [ $? != 0 ]; then
  # Another node won the race, assume joining with the rest.
  echo "Not first machine, joining others..."
  export first="$(etcdctl --peers $bridge_ip:4001 get --consistent /consul.io/bootstrap/bootstrapped)"
  echo "first =" $first

  others=$(etcdctl --peers $bridge_ip:4001 ls /consul.io/bootstrap/machines | while read line; do
          ip=$(etcdctl --peers $bridge_ip:4001 get --consistent ${line})
          if [ "${ip}" != "${first}" ]; then
            echo -n "-retry-join ${ip} "
          fi
        done)

  flags="-retry-join $first $others"
  bootstrap=""
else
  # We're the first to bootstrap.
  echo "First machine, setting consul bootstrap flag..."
  flags=""
  bootstrap="-bootstrap"
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
CONSUL_BOOTSTRAP="${bootstrap}"
CONSUL_JOIN="${flags}"
EOF
