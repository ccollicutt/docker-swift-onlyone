#!/bin/bash

#
# Make the rings if they don't exist already
#

if [ ! -e /etc/swift/account.builder ]; then

	cd /etc/swift

	# 2^& = 128 we are assuming just one drive
	# 1 replica only

	swift-ring-builder object.builder create 7 1 1
	swift-ring-builder object.builder add r1z1-127.0.0.1:6010/sdb1 1
	swift-ring-builder object.builder rebalance
	swift-ring-builder container.builder create 7 1 1
	swift-ring-builder container.builder add r1z1-127.0.0.1:6011/sdb1 1
	swift-ring-builder container.builder rebalance
	swift-ring-builder account.builder create 7 1 1
	swift-ring-builder account.builder add r1z1-127.0.0.1:6012/sdb1 1
	swift-ring-builder account.builder rebalance

fi

#
# Start rsyslog
#

. /etc/default/rsyslog

rsyslogd

#
# Start memcached
# 

memcached -u memcache -d

#
# Start swift
#

# this comes from a volume, so need to chown it
chown -R swift:swift /srv

swift-init main start
swift-init start rest

#
# Tail the log file for "docker log $CONTAINER_ID"
#

echo "Starting to tail /var/log/syslog...(hit ctrl-c if you are starting the container in a bash shell)"

tail -n 0 -f /var/log/syslog
