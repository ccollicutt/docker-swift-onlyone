#Docker OpenStack Swift onlyone

This is a docker file that creates an OpenStack swift image which has only one replica and only one device. Why would this be useful? I think that Docker and OpenStack Swift go together like peas and carrots. Distributed files systems are a pain, so why not just use OpenStack Swift? Scaling is not as much of an issue with object storage. Many Docker containers, even on separate hosts, can use one OpenStack Swift container to persist files.

But then why only one replica one and one device? I think that "onlyone" is a good starting point. It will make it easy for developers to get used to using object storage instead of a file system, and when they need the eventual consistency and multiple replicas provided by a larger OpenStack Swift cluster they can work on implementing that. I don't see one replica as an issue in small systems or for a proof-of-concept because it can just be backed up.

## Requirements

I have only tested this using the Docking and the btrfs file system. OpenStack Swift requires a file system that has xattr capability. There are several file systems that provide this, but I don't believe that aufs is one of them. So I am using btrfs. Docker 1.0 has added support for the xfs file system, which is typically what OpenStack Swift is deployed on, so that is also an option.

## startmain.sh

Like many docker containers, there is a script that starts services. The most idiomatic way to use docker is one container one service, but in the case of this particular Dockerfile we will be starting several services in the container, such as rsyslog, memcached, and all the required OpenStack Swift daemons. So in this case we're using Docker more as a role-based system. All of the required Swift services are running in this one container.

## Todo

* Perhaps runit or supervisor to manage the various services