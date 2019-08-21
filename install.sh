#!/bin/bash

# run as root

## constants

DEPLOY_OS=ubuntu
DOCKER_COMPOSE_VERSION=1.24.1
RUN_USER=splanner_usr

## vars

run_user=""
cron_job_deploy=""

## util

# is_insatlled <some-command>
is_installed() {
  command -v $1
}

# is_directory_exist <some-directory>
is_directory_exist() {
  [ -d "$1" ]
}

# is_user_exist <some-uesr>
is_user_exist() {
  getent passwd $1
}

# is_group_exist <some-group>
is_group_exist() {
  getent group $1
}

# add_system_user <some-user-name>
add_system_user() {
  useradd -r $1
}

# add_cron_deploy <some-user> <some-cron-job>
check_cron_for_user() {

}

# add_cron_deploy <some-user> <some-cron-job>
add_cron_for_user() {
  (crontab -l 2>/dev/null; echo "$2") | crontab -u $1 -
}

## install and upgrade tools

# assume either debian or ubuntu
install_docker() {
  apt-get -q -y dist-upgrade

  apt-get -q -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common

  curl -fsSL https://download.docker.com/linux/${DEPLOY_OS}/gpg | apt-key add -

  add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/${DEPLOY_OS} \
  $(lsb_release -cs) \
  stable"

  apt-get -q -y dist-upgrade

  apt-get -q -y install docker-ce docker-ce-cli containerd.io
}

# **dangerous**, not verified behavior
upgrade_docker() {
  echo "force upgrade docker-ce docker-ce-cli containerd.io, may break things"
  apt-get -q -y install docker-ce docker-ce-cli containerd.io
  # apt-get -q -y dist-upgrade
}

# install_docker_compose <some-version>
install_docker_compose() {
  curl -L "https://github.com/docker/compose/releases/download/${1:-DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
}

# upgrade_docker_compose <some-version>
upgrade_docker_compose() {
  install_docker_compose $1
}

install_docker_compose_bash_completion() {
  curl -L https://raw.githubusercontent.com/docker/compose/${DOCKER_COMPOSE_VERSION}/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
}

# check, if not installed, install
ensure_install_tools() {
  if !is_installed docker; then
    install_docker
  fi

  if !is_insatlled docker-compose; then
    install_docker_compose
    install_docker_compose_bash_completion
  fi
}

## splanner stuff

check_splanner_env() {
  if is_user_exist ${run_user:-RUN_USER}; then
    echo "User ${run_user:-RUN_USER} exists, please specify a different run user"
    exit -1
  fi

  if !is_group_exist docker; then
  fi
}

add_cron_deploy() {

}

install_splanner() {
  add_cron_deploy
  /splanner/deploy.sh -d
}