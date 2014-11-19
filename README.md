env-bootstrap
================

Dockerfile + shell scripts to generate systemd/fleet environment files.

When running systemd units via Fleet on CoreOS, it is often necessary to compute certain values when launching a Docker container.  Rather than embedding this logic into the unit itself, we use the 'enviornment file' pattern to compute these values inside a Docker container.  The values are written to an environment file under `/etc/env.d`.  Thus, the main unit can simply load this envionrment file and avoid embedding complicated scripting inside it.

The currently supported environment variable computations are:
-`bootstrap`: use an etcd cluster to bootstrap another distributed service, such as Consul or RethinkDB.
-`discover`: discover a paricular service via Consul
