#!/bin/bash
set -e

COMMANDS="help logtail show stop fg kill quit wait foreground logreopen reload shell status"
START="start restart"

if [ -z "$HEALTH_CHECK_TIMEOUT" ]; then
  HEALTH_CHECK_TIMEOUT=1
fi

if [ -z "$HEALTH_CHECK_INTERVAL" ]; then
  HEALTH_CHECK_INTERVAL=1
fi

mkdir -p /data/filestorage /data/blobstorage

if [[ $START == *"$1"* ]]; then
  _stop() {
    bin/zeoserver stop
    kill -TERM $child 2>/dev/null
  }

  trap _stop SIGTERM SIGINT
  bin/zeoserver start
  bin/zeoserver logtail &

  child=$!

  pid=`bin/zeoserver status | sed 's/[^0-9]*//g'`
  if [ ! -z "$pid" ]; then
    echo "Application running on pid=$pid"
    sleep "$HEALTH_CHECK_TIMEOUT"
    while kill -0 "$pid" 2> /dev/null; do
      sleep "$HEALTH_CHECK_INTERVAL"
    done
  else
    echo "Application didn't start normally. Shutting down!"
    _stop
  fi
else
  if [[ $COMMANDS == *"$1"* ]]; then
    exec bin/instance "$@"
  fi
  exec "$@"
fi
