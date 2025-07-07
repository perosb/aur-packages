#!/usr/bin/env bash
[[ "$RUNNER_DEBUG" == 1 ]] && set -x

set -euo pipefail

function group() {
  echo ::group::"$*"
}
function endgroup() {
  echo ::endgroup::
}

group Creating builder user
useradd --create-home --shell /bin/bash builder
passwd --delete builder
mkdir -p /etc/sudoers.d/
echo "builder  ALL=(root) NOPASSWD:ALL" >/etc/sudoers.d/builder
endgroup

group Initializing SSH directory
mkdir -pv /home/builder/.ssh
touch /home/builder/.ssh/known_hosts
chown -vR builder:builder /home/builder
chmod -vR 0600 /home/builder/.ssh/*
endgroup

exec runuser builder --command "$@"
