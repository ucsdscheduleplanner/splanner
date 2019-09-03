#!/bin/bash
#
# installs docker and docker-compose if not already
# creates a system user as the owner of splanner process
# generates a https key-pair to be used by http server
# creates a crontab job for that user to periodically check new builds
#         this is achieved by running another script, deploy.sh
# starts the program

## constants

readonly CERT_EMAIL_EMPTY="EMAIL_NOT_SPECIFIED"
readonly SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

## defaults

readonly DEPLOY_OS='ubuntu'
readonly DOCKER_COMPOSE_VERSION='1.24.1'
readonly RUN_USER='splanner_usr'
readonly SPLANNER_HOME=/splanner/

# UTC 10:59 is Pacific 03:59
# per 5 days on 3:59 am pacific time
readonly CRON_TIME='59 10 */5 * *'

# NEED prefix with path
readonly CRON_CMD='deploy.sh -c'

## vars

deploy_os="${DEPLOY_OS}"
docker_compose_version="${DOCKER_COMPOSE_VERSION}"
run_user="${RUN_USER}"
splanner_home="${SPLANNER_HOME}"

cron_time="${CRON_TIME}"

cron_cmd="${CRON_CMD}"

cert_email="${CERT_EMAIL_EMPTY}"

## usage

readonly usage = "install the splanner continuous deployment workflow

install.sh [-h] [-i] [--time cron-time-date-field] [--email email] [--upgrade docker|docker-compose]

run-options:
    -h  show this help text
    -i  install
    --upgrade [docker|docker-compose] upgrade

options for install:
    --time  set when to check new updates, in crontab format (default \"${CRON_TIME}\")
    --email REQUIRED, set the email address used by generating https cert files

example:
    /splanner/install.sh -i --email person@example.com

Run with root privilege"

display_usage() {
  echo "$usage"
}

## util

# check_permission <some-permission> <some-file>
check_permission() {
  [[ $(stat -c "%a" "$2") == "$1" ]]
}

# is_insatlled <some-command>
is_installed() {
  command -v "$1"
}

# is_file_exist <some-file>
is_file_exist() {
  [[ -f "$1" ]]
}

# is_directory_exist <some-directory>
is_directory_exist() {
  [[ -d "$1" ]]
}

# is_user_exist <some-uesr>
is_user_exist() {
  getent passwd "$1"
}

# is_group_exist <some-group>
is_group_exist() {
  getent group "$1"
}

# add_system_user <some-user-name>
add_system_user() {
  useradd -r "$1"
}

# add_cron_job <some-cron-cmd-keyword>
# return 1 if not found
# return 0 if at least 1 line found
# grep: "Normally the exit status is 0 if a line is selected, 1 if no lines were selected, and 2 if an error occurred.
# However, if the -q or --quiet or --silent is used and a line is selected, the exit status is 0 even if an error occurred."
check_cron_job() {
  grep --with-filename -r /var/spool/cron/crontabs/* "$1"
}

# add_cron_deploy <some-user> <some-cron-job>
add_cron_for_user() {
  (crontab -l 2>/dev/null; echo "$2") | crontab -u "$1" -
}

# is_email_valid <some-email-address>
is_email_valid() {
  [[ "$1" =~ '^([A-Za-z]+[A-Za-z0-9]*((\.|\-|\_)?[A-Za-z]+[A-Za-z0-9]*){1,})@(([A-Za-z]+[A-Za-z0-9]*)+((\.|\-|\_)?([A-Za-z]+[A-Za-z0-9]*)+){1,})+\.([A-Za-z]{2,})+' ]]
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

  curl -fsSL https://download.docker.com/linux/${deploy_os}/gpg | apt-key add -

  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/${deploy_os} \
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
# default to be ${DOCKER_COMPOSE_VERSION}
install_docker_compose() {
  curl -L "https://github.com/docker/compose/releases/download/${1:-DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
}

# upgrade_docker_compose <some-version>
upgrade_docker_compose() {
  install_docker_compose $1
}

# install_docker_compose_bash_completion <some-version>
# default to be ${DOCKER_COMPOSE_VERSION}
install_docker_compose_bash_completion() {
  curl -L https://raw.githubusercontent.com/docker/compose/${1:-DOCKER_COMPOSE_VERSION}/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
}

# check, if not installed, install
ensure_install_tools() {
  if !is_installed docker; then
    install_docker || exit $?
  fi

  if !is_insatlled docker-compose; then
    install_docker_compose || exit $?
    install_docker_compose_bash_completion || exit $?
  fi
}

## splanner stuff

# check essential files and their permissions
check_splanner_files() {

}

ensure_splanner_env() {
  if is_user_exist ${run_user:-RUN_USER}; then
    echo "User ${run_user:-RUN_USER} exists, please specify a different run user"
    echo "continue?"
    read????
  else
    add_system_user "${run_user}"
  fi

  if !is_group_exist docker; then

  fi
}

get_cron_deploy_cmd() {
  printf "%s %s%s\n" "${cron_time}" "${splanner_home}" "${cron_cmd}"
}

install_splanner_files() {
  add_cron_deploy
  mkdir -pv "${splanner_home}"
}

install_splanner_cron() {
  add_cron_for_user "$run_user" "$(get_cron_deploy_cmd)"
}

run_certbot() {

}

install_splanner() {
  if !ensure_splanner_env; then
    echo "Failed to ensure install environment"
    exit $?
  fi

  if !install_splanner_files; then
    echo "Failed to install files to ${splanner_home}"
    exit $?
  fi
  if !install_splanner_cron; then
    echo "Failed to install cron tab job ${get_cron_deploy_cmd}"
    exit $?
  fi

  if !run_certbot; then
    echo "Failed to generate ssl pair files"
    exit $?
  fi

  # start the service
  exec /splanner/deploy.sh -d
}

main() {
  if [[ $# -eq 0 ]]; then
   display_usage
   exit 0
  fi

  mode_install=''
  mode_reinstall=''

  while test $# -gt 0; do
    case "$1" in 
      -h | --help) 
        display_usage
        exit 0
        ;;
      -i | --install)
        mode_install='true'
        ;;
      -r | --reinstall)
        mode_reinstall='true'
        ;;
      -c | --cert)
        ssl_email="$2"
        if ! is_email_valid "$ssl_email" ;then
          echo "Invalid Email "${ssl_email}", plese check again"
          exit 1
        fi
        ;;
      *)
        printf "illegal option: -%s\n" "$1" >&2
        echo
        display_usage
        exit 1
        ;;
    esac
    shift
  done
}

main "$@"