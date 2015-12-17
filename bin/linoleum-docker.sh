#!/bin/bash

set -e

# Resolve the path to our node module content
pushd `dirname $0` > /dev/null
SCRIPTPATH=$(pwd -P)/$(readlink $(basename $0))
popd > /dev/null

pushd `dirname $SCRIPTPATH`/.. > /dev/null

COMMAND=$1
HOST=$2

RUNNING=`docker-machine ls --filter=state=Running -q --filter=name=$NAME`

function start() {
  if [[ "$RUNNING" != "$HOST" ]]; then
    docker-machine start $HOST
    sleep 5
  fi

  eval "$(docker-machine env $HOST)"

  docker-compose up -d

  echo "Running sudo"

  ROUTER_IP=`docker-machine inspect --format='{{ .Driver.Driver.IPAddress }}' $HOST`
  sudo mkdir -p /etc/resolver
  echo "nameserver $ROUTER_IP" | sudo tee /etc/resolver/internal

  ROUTER_CMD=`./node_modules/.bin/docker-hosts-watch route add`
  sudo bash -c "${ROUTER_CMD}"
}

function stop() {
  sudo rm /etc/resolver/internal || true

  if [[ "$RUNNING" != "$HOST" ]]; then
    return
  fi

  eval "$(docker-machine env $HOST)"

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
