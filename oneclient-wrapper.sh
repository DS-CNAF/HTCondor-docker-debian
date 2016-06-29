#!/bin/bash
if [ -n ${ONECLIENT_AUTHORIZATION_TOKEN} -a -n ${PROVIDER_HOSTNAME} ]
  then
     mkdir $ONEDATA_MOUNTPOINT 
     /usr/bin/oneclient -d --no-check-certificate --authentication token $ONEDATA_MOUNTPOINT
  else
     echo "oneclient variables not set."
fi
