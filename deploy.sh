#!/bin/bash

has_update() {

}

pull() {

}

rebuild() {

}

restart() {

}

start() {

}

# first time only
deploy() {

}

cron_job() {
  if has_update; then
    pull
    rebuild
    restart
  fi
}