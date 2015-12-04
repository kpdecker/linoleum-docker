#!/bin/bash

set -e

pushd ${BASH_SOURCE%/*}/..

COMMAND=$1
HOST=$2

RUNNING=`docker-machine ls --filter=state=Running -q --filter=name=$NAME`

function start() {
  if [[ "$RUNNING" != "$HOST" ]]; then
    docker-machine start $HOST
  fi

  eval "$(docker-machine env $HOST)"

  docker-compose up -d

  ROUTER_IP=`docker-machine inspect --format='{{ .Driver.Driver.IPAddress }}' $HOST`
  sudo mkdir -p /etc/resolver
  echo "nameserver $ROUTER_IP" | sudo tee /etc/resolver/app

  ROUTER_CMD=`./node_modules/.bin/docker-hosts-watch route add`
  sudo bash -c "${ROUTER_CMD}"
}

function stop() {
  eval "$(docker-machine env $HOST)"

  sudo rm /etc/resolver/app || true

  ROUTER_CMD=`./node_modules/.bin/docker-hosts-watch route delete`
  sudo bash -c "${ROUTER_CMD}"

  docker-machine stop $HOST
}

case "$COMMAND" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  *)
    echo "Usage $0 {start|stop} machine-name"
    exit 1
esac