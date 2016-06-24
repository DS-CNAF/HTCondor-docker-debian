#!/bin/bash

# Configure HTCondor and fire up supervisord
# Daemons for each role
set -x
env 

MASTER_DAEMONS="COLLECTOR, NEGOTIATOR"
EXECUTOR_DAEMONS="STARTD"
SUBMITTER_DAEMONS="SCHEDD"

usage() {
  cat <<-EOF
	usage: $0 -m|-e master-address|-s master-address
	
	Configure HTCondor role and start supervisord for this container
	
	OPTIONS:
	  -m                configure container as HTCondor master
	  -e master-address configure container as HTCondor executor for the given master
	  -s master-address configure container as HTCondor submitter for the given master
	  
	EOF
  exit 1
}

# Get our options
ROLE_DAEMONS=
CONDOR_HOST=
while getopts ':me:s:t:p:' OPTION; do
  case $OPTION in
    m)
      [ -n "$ROLE_DAEMONS" ] && usage
      ROLE_DAEMONS="$MASTER_DAEMONS"
      CONDOR_HOST='$(FULL_HOSTNAME)'
    ;;
    e)
      [ -n "$ROLE_DAEMONS" -o -z "$OPTARG" ] && usage
      ROLE_DAEMONS="$EXECUTOR_DAEMONS"
      CONDOR_HOST="$OPTARG"
    ;;
    s)
      [ -n "$ROLE_DAEMONS" -o -z "$OPTARG" ] && usage
      ROLE_DAEMONS="$SUBMITTER_DAEMONS"
      CONDOR_HOST="$OPTARG"
    ;;
    t)
      [ -z "$OPTARG" ] && usage
      export ONECLIENT_AUTHORIZATION_TOKEN=$OPTARG
    ;;
    p)
      [ -z "$OPTARG" ] && usage
      export PROVIDER_HOSTNAME=$OPTARG
    ;;
    *)
      usage
    ;;
  esac
done

# Prepare HTCondor configuration
sed -i \
  -e 's/@CONDOR_HOST@/'"$CONDOR_HOST"'/' \
  -e 's/@ROLE_DAEMONS@/'"$ROLE_DAEMONS"'/' \
  /etc/condor/condor_config

exec /usr/local/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
