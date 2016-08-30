#!/bin/bash
# Configure HTCondor and fire up supervisord
# Daemons for each role
MASTER_DAEMONS="COLLECTOR, NEGOTIATOR"
EXECUTOR_DAEMONS="STARTD"
SUBMITTER_DAEMONS="SCHEDD"

usage() {
  cat <<-EOF
	usage: $0 -m|-e master-address|-s master-address [-u url-to-config]
	
	Configure HTCondor role and start supervisord for this container. 
	
	OPTIONS:
	  -m                configure container as HTCondor master
	  -e master-address configure container as HTCondor executor for the given master
	  -s master-address configure container as HTCondor submitter for the given master
	  -u url-to-config  config file reference from http url.
	EOF
  exit 1
}

# Syntax checks
CONFIG_MODE=

# Get our options
ROLE_DAEMONS=
CONDOR_HOST=
PROVIDER_HOSTNAME=
CONFIG_URL=
while getopts ':me:s:u:' OPTION; do
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
    u)
      [ -n "$CONFIG_MODE" -o -z "$OPTARG" ] && usage
      CONFIG_MODE='http'
      CONFIG_URL="$OPTARG"
    ;;
    s)
      [ -n "$ROLE_DAEMONS" -o -z "$OPTARG" ] && usage
      ROLE_DAEMONS="$SUBMITTER_DAEMONS"
      CONDOR_HOST="$OPTARG"
    ;;
    *)
      usage
    ;;
  esac
done

if [ $CONFIG_MODE ]; then
  wget "$CONFIG_URL" /etc/condor/condor_config
fi

# Prepare HTCondor configuration
sed -i \
  -e 's/@CONDOR_HOST@/'"$CONDOR_HOST"'/' \
  -e 's/@ROLE_DAEMONS@/'"$ROLE_DAEMONS"'/' \
  /etc/condor/condor_config

exec /usr/local/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
