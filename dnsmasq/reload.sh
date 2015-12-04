#!/bin/bash
# Derived from https://bitbucket.org/devries/docker-dnsmasq/src/4e72ac7cd880444a2004a08a650daf3b524cf44c/reload.sh?at=autoreload&fileviewer=file-view-default
ALT_HOSTS=${ALT_HOSTS-/data/docker-hosts}

set -e

echo "Starting dnsmasq server..."
echo ""
cat /etc/dnsmasq.conf
echo ""
echo "althosts entries: "
cat $ALT_HOSTS

/etc/init.d/dnsmasq start

while true; do
  inotifywait -e close_write,moved_to,create $ALT_HOSTS  && \
  /etc/init.d/dnsmasq restart
done
