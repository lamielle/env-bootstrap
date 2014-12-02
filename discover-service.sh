#!/bin/sh

# Query DNS on the Docker bridge for a service.
# The service must exist in the consul services namespace.
# It also must have a corresponding SRV record for the port.

bridge_ip="$(ip route | awk '/^default/{print $3}')"
service_name=$1
SERVICE_NAME=$(echo "${service_name}" | tr "[:lower:]" "[:upper:]")
service_host=$(dig ${service_name}.service.consul @${bridge_ip} +short | head -n 1)
service_port=$(dig ${service_name}.service.consul @${bridge_ip} -t SRV +short | head -n 1 | cut -d ' ' -f 3)

echo "bridge_ip =" $bridge_ip
echo "service_name =" $service_name
echo "SERVICE_NAME =" $SERVICE_NAME
echo "service_host =" $service_host
echo "service_port =" $service_port

if [ "$2" == "reverse" ]; then
  service_host=$(dig -x $service_host | sed -e 's/\(.*\)\.$/\1/')
  echo "service_host (after reverse) =" $service_host
fi

echo "Writing environment.${service_name}"
cat > /etc/env.d/environment.${service_name} <<EOF
${SERVICE_NAME}_HOST=${service_host}
${SERVICE_NAME}_PORT=${service_port}
EOF
