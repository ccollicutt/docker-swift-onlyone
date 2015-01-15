#Docker OpenStack Swift onlyone

This is a docker file that creates an OpenStack swift image which has only one replica and only one device. Why would this be useful? I think that Docker and OpenStack Swift go together like peas and carrots. Distributed files systems are a pain, so why not just use OpenStack Swift? Scaling is not as much of an issue with object storage. Many Docker containers, even on separate hosts, can use one OpenStack Swift container to persist files.

But then why only one replica one and one device? I think that "onlyone" is a good starting point. It will make it easy for developers to get used to using object storage instead of a file system, and when they need the eventual consistency and multiple replicas provided by a larger OpenStack Swift cluster they can work on implementing that. I don't see one replica as an issue in small systems or for a proof-of-concept because it can just be backed up.

## Requirements

I have only tested this using the Docking and the btrfs file system. OpenStack Swift requires a file system that has xattr capability. There are several file systems that provide this, but I don't believe that aufs is one of them. So I am using btrfs. Docker 1.0 has added support for the xfs file system, which is typically what OpenStack Swift is deployed on, so that is also an option.

## startmain.sh

This Dockerfile uses supervisord to manage the processes. The most idiomatic way to use docker is one container one service, but in this particular Dockerfile we will be starting several services in the container, such as rsyslog, memcached, and all the required OpenStack Swift daemons (of which there are quite a few). So in this case we're using Docker more as a role-based system, and the roles are both a swift proxy and swift storage, ie. a swift "onlyone."" All of the required Swift services are running in this one container.

## Usage

I suggest using the data container methodology.

So first we create a data only container for /srv.

```bash
vagrant@host1:~$ docker run -v /srv --name SWIFT_DATA busybox
```

Now that we have a data container, we can use the "--volumes-from" option when creating the "onlyone" container. Note that in this case I've called the image built from this docker file "curtis/swift-onlyone".

```bash
vagrant@host1:~$ ID=$(docker run -d -p 12345:8080 --volumes-from SWIFT_DATA -t curtis/swift-onlyone)
```

With that container running we can now check the logs.

```bash
vagrant@host1:~$ docker logs $ID
Device d0r1z1-127.0.0.1:6010R127.0.0.1:6010/sdb1_"" with 1.0 weight got id 0
Reassigned 128 (100.00%) partitions. Balance is now 0.00.
Device d0r1z1-127.0.0.1:6011R127.0.0.1:6011/sdb1_"" with 1.0 weight got id 0
Reassigned 128 (100.00%) partitions. Balance is now 0.00.
Device d0r1z1-127.0.0.1:6012R127.0.0.1:6012/sdb1_"" with 1.0 weight got id 0
Reassigned 128 (100.00%) partitions. Balance is now 0.00.
WARNING: Unable to modify file descriptor limit.  Running as non-root?
Starting proxy-server...(/etc/swift/proxy-server.conf)
Starting container-server...(/etc/swift/container-server.conf)
Starting account-server...(/etc/swift/account-server.conf)
Starting object-server...(/etc/swift/object-server.conf)
WARNING: Unable to modify file descriptor limit.  Running as non-root?
Starting container-updater...(/etc/swift/container-server.conf)
Starting account-auditor...(/etc/swift/account-server.conf)
Starting object-replicator...(/etc/swift/object-server.conf)
Starting container-replicator...(/etc/swift/container-server.conf)
Starting object-auditor...(/etc/swift/object-server.conf)
Unable to locate config for object-expirer
Starting container-auditor...(/etc/swift/container-server.conf)
Starting account-replicator...(/etc/swift/account-server.conf)
Starting account-reaper...(/etc/swift/account-server.conf)
Starting container-sync...(/etc/swift/container-server.conf)
Starting object-updater...(/etc/swift/object-server.conf)
Starting to tail /var/log/syslog...(hit ctrl-c if you are starting the container in a bash shell)
```

At this point OpenStack Swift is running.

```bash
vagrant@host1:~$ docker ps
CONTAINER ID        IMAGE                         COMMAND                CREATED             STATUS              PORTS                     NAMES
4941f8cd8b48        curtis/swift-onlyone:latest   /bin/sh -c /usr/loca   58 seconds ago      Up 57 seconds       0.0.0.0:12345->8080/tcp   hopeful_brattain
```

We can now use the swift python client to access Swift using the Docker forwarded port, in this example port 12345.

```bash
vagrant@host1:~$ swift -A http://127.0.0.1:12345/auth/v1.0 -U test:tester -K testing stat
       Account: AUTH_test
    Containers: 0
       Objects: 0
         Bytes: 0
  Content-Type: text/plain; charset=utf-8
   X-Timestamp: 1402463864.77057
    X-Trans-Id: tx4e7861ebab8244c09dad9-005397e678
X-Put-Timestamp: 1402463864.77057
```

Try uploading a file:

```bash
vagrant@host1:~$ swift -A http://127.0.0.1:12345/auth/v1.0 -U test:tester -K testing upload swift swift.txt
swift.txt
```

That's it!

## Todo

* SELINUX doesn't support btrfs?
* It seems supervisord running as root in the container, a better way to do this?
* bash command to start rsyslog is still running...
* Add all the files in /etc/swift with one ADD command?
* supervisor pid file is getting setup in /etc/
