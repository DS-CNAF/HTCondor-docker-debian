#!/bin/bash

# Configure HTCondor and fire up supervisord
exec /usr/local/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
