# HTCondor Docker containers 

HTCondor dockerized in three nodes: Master, Submitter and Executor.
Ubuntu Trusty LTS is the base image used and condor version refer to the [last stable version](https://research.cs.wisc.edu/htcondor/ubuntu/).

Supervisord is used in order to control different processes spawn.
Many different features are implemented as described below, such as [calico](https://www.projectcalico.org/), [marathon](https://mesosphere.github.io/marathon/), [onedata](https://onedata.org/) support.

## Architecture

![Architettura HTCondor](architecture.png)

## Feature
* [simple Run](#nodes-run)
* [Calico Support](#calico-support)
* [Onedata Support](#onedata-support)
* [Marathon Support](#marathon-support)
* [Healthchecks](#Healthchecks)
* [SSH access](#ssh-access)
* [condor_config](#condor_config)
* [Logs](#LOGS)

### Nodes run
Master node:

```bash 
$ docker run -d --name=condormaster dscnaf/htcondor-debian -m
$ docker exec -it condormaster ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
32: eth0@if33: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe11:2/64 scope link
       valid_lft forever preferred_lft forever
```

Submitter node:

```bash 
$ docker run -d --name=condorsubmit dscnaf/htcondor-debian -s <MASTER_IP>
```

Then launch an arbitrary number of executors:

```bash 
$ docker run -d --name=condorexecute dscnaf/htcondor-debian -e <MASTER_IP>
```
### Calico support

Containers are agnostic on network layer. As follows, a test will be shown in which containers hosted on different hosts (calico01 - calico0(x)) can communicate via [calico](https://www.projectcalico.org/) network driver.
```bash
core@calico-01 ~ $ calicoctl pool add 192.168.0.0/16
core@calico-01 ~ $ calicoctl pool show
+----------------+---------+
|   IPv4 CIDR    | Options |
+----------------+---------+
| 192.168.0.0/16 |         |
+----------------+---------+
+-----------+---------+
| IPv6 CIDR | Options |
+-----------+---------+
+-----------+---------+
core@calico-01 ~ $ docker network create --driver calico --ipam-driver calico calinet1
core@calico-01 ~ $ calicoctl profile calinet1 rule show
Inbound rules:
   1 allow from tag calinet1
Outbound rules:

core@calico-01 ~ $ docker exec -it condormaster ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN qlen 1
    link/ipip 0.0.0.0 brd 0.0.0.0
15: cali0@if16: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP qlen 1000
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff
    inet 192.168.142.0/32 scope global cali0
       valid_lft forever preferred_lft forever
    inet6 fe80::ecee:eeff:feee:eeee/64 scope link
       valid_lft forever preferred_lft forever
core@calico-0(x) ~ $ docker run -d --net=calinet1 --name=condorsubmit dscnaf/htcondor-debian -s 192.168.142.0
core@calico-0(x) ~ $ docker run -d --net=calinet1 --name=condorexecute dscnaf/htcondor-debian -e 192.168.142.0
core@calico-0(x) ~ $ docker exec -it condorexecute ping 192.168.142.0
PING 192.168.142.0 (192.168.142.0): 48 data bytes
56 bytes from 192.168.142.0: icmp_seq=0 ttl=62 time=0.048 ms
56 bytes from 192.168.142.0: icmp_seq=1 ttl=62 time=0.376 ms
^C--- 192.168.142.0 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max/stddev = 0.048/0.212/0.376/0.164 ms
```

### Onedata support

Inside containers there is [oneclient](https://onedata.org/) tool for external data access. Users can so use during job run File System mount inside their sandbox.
Requirements:
* oneprovider access
* external connectivity (--nat-outgoing is required when using Calico)
* privileged containers (executors must be --privileged)

```bash
$ docker run -d --name=condor<TYPE> --privileged dscnaf/htcondor-debian -e <MASTER_IP>
## on submitter
john@submitter:~$ cat touch.sh 
#!/bin/bash
set -ex
export ONECLIENT_AUTHORIZATION_TOKEN=xxxxxxxxxxxxxxxxxxxx
export PROVIDER_HOSTNAME=<ENDPOINT>
mkdir oneclient
oneclient --no_check_certificate --authentication token oneclient
cd oneclient/John\'s\ space
touch imhere.txt
cd ../..
fusermount -u oneclient 
```

#### Known issue

* `unmount` op is due to user still. Be careful with hanging mountpoint in executor hosts.

### Marathon support

Inside `examples/marathon` folder different `.json` file as example are stored for launching containers in mesos/marathon clusters. Examples contains different optional features. Please refer to [usage](#usage) or specific sections. For other requirements, please refer to official [marathon docs](https://mesosphere.github.io/marathon/docs/)

`.json` files can injected via GUI (from newer marathon versions) or via API as follows:

```bash
curl -XPOST -H "Content-Type: application/json" http://<MARATHON_IP>/v2/apps -d @<FILE.json>
```

### Healthchecks

Healthchecks are implemented using HTCondor [API python](https://research.cs.wisc.edu/htcondor/manual/v8.1/6_7Python_Bindings.html). They simple check presence of used processes in container specific role. Nevertheless, due to known bugs in Mesos Marathon platform, this feature is no totally working yet if using Calico drivers. These bugs are resolved in Mesos >= 1.0.0-rc3 and Marathon >= 1.2.0-RC8.

Healthchecks examples are too in `examples/marathon` folder.

#### Known issue

* Healthchecks still primitive

### SSH access

Containers are launched with `sshd` daemon disabled as default. Nevertheless could be activated if needed (e.g.: access to hosting submitter host) via two methods:

1. via **password**:

   use `-u` (user) and `-p` (password) parameters. It will inject a user without root privileges
```
docker run  -d --name=sub --net=htcondor dscnaf/htcondor-debian -s 192.168.0.152 -u john -p j0hn
```

2. via **certificate**

   using `-k` (public Key) parameter, ssh service will be activated and public key stored in `/root/.ssh/authorized_keys`. Public key must be reachable via net.  File system exchange is not possible.
```
docker run  -d --name=sub --net=htcondor dscnaf/htcondor-debian -s 192.168.0.152 -k <url_to_public_key>
```

These two methods are not mutually exclusive

#### SSH access to calico network provided container

1. Adding calico rule

```
[root@mesos-host ~]# calicoctl profile htcondor rule show
Inbound rules:
   1 allow from tag htcondor
   2 allow tcp to ports 5000
Outbound rules:
   1 allow
[root@mesos-host ~]# calicoctl profile htcondor rule add inbound allow tcp to ports 22
[root@mesos-host ~]# calicoctl profile htcondor rule show
Inbound rules:
   1 allow from tag htcondor
   2 allow tcp to ports 5000
   3 allow tcp to ports 22
Outbound rules:
   1 allow
```

2. Routing rule adding on hosting submitter host

```
[root@mesos-host ~]# iptables -A PREROUTING -t nat -i <HOST_INTERFACE> -p tcp --dport <PORT> -j DNAT  --to <CONTAINER_IP>:22
[root@mesos-host ~]# iptables -t nat -A OUTPUT -p tcp -o lo --dport <PORT> -j DNAT --to-destination <CONTAINER_IP>:22
```

e.g.:

```
[root@mesos-host ~]# iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 2222 -j DNAT  --to 192.168.0.26:22
[root@mesos-host ~]# iptables -t nat -A OUTPUT -p tcp -o lo --dport 2222 -j DNAT --to-destination 192.168.0.26:22
```

3. External access

```
john@workstation:~$ ssh -p 2222 john@131.154.96.147
Password:
Welcome to Ubuntu 14.04.5 LTS (GNU/Linux 3.10.0-327.28.3.el7.x86_64 x86_64)

 * Documentation:  https://help.ubuntu.com/

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.


The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

Last login: Wed Sep 14 14:14:28 2016 from workstation
john@3211f3fc6b40:~$
```

Where 192.168.0.26 is submitter IP (via calico) and 131.154.96.147 is the hosting node (mesos-host).
=======

*Note:* this solution is reported as calico [docs](https://github.com/projectcalico/calico-containers/blob/master/docs/ExposePortsToInternet.md). 

### condor_config

`-c` (configuration file) parameter, permit to inject a different configuration file in container instances. Configuration file must be reachable via net.  File system exchange is not possible.
```
docker run  -d --name=sub --net=htcondor dscnaf/htcondor-debian -s 192.168.0.152 -c <url_to_condor_config>
```

#### Known issue

* `DAEMON_LIST = MASTER, @ROLE_DAEMONS@` and `CONDOR_HOST = @CONDOR_HOST@` parameters should be present even in a different `condor_config` template. Different template is in full user charge. 

### Logs

```bash
docker logs <container_name>
```
### Functional HTCondor test

```bash
core@calico-01 ~ $ docker exec -it condorsubmit bash
root@854b194757b8:/# useradd -m -s /bin/bash john
root@854b194757b8:/# su - john
john@854b194757b8:~$ cat > sleep.sh << EOF
#!/bin/bash
/bin/sleep 20
EOF
john@854b194757b8:~$ cat > sleep.sub << EOF
executable              = sleep.sh
log                     = sleep.log
output                  = outfile.txt
error                   = errors.txt
should_transfer_files   = Yes
when_to_transfer_output = ON_EXIT
queue
EOF
john@854b194757b8:~$ chmod u+x sleep.sh
john@854b194757b8:~$ condor_status
Name               OpSys      Arch   State     Activity LoadAv Mem   ActvtyTime

073b4a02ee6a       LINUX      X86_64 Unclaimed Idle      0.000  997  0+02:19:33
854b194757b8       LINUX      X86_64 Unclaimed Idle      0.010  997  0+00:00:04
                     Total Owner Claimed Unclaimed Matched Preempting Backfill

        X86_64/LINUX     2     0       0         2       0          0        0

               Total     2     0       0         2       0          0        0
john@854b194757b8:~$ condor_submit sleep.sub
Submitting job(s).
1 job(s) submitted to cluster 12.
john@854b194757b8:~$ condor_status
Name               OpSys      Arch   State     Activity LoadAv Mem   ActvtyTime

073b4a02ee6a       LINUX      X86_64 Unclaimed Idle      0.000  997  0+02:19:33
854b194757b8       LINUX      X86_64 Claimed   Busy      0.010  997  0+00:00:04
                     Total Owner Claimed Unclaimed Matched Preempting Backfill

        X86_64/LINUX     2     0       1         1       0          0        0

               Total     2     0       1         1       0          0        0
john@854b194757b8:~$ condor_q
-- Schedd: 854b194757b8 : <192.168.142.1:56580?...
 ID      OWNER            SUBMITTED     RUN_TIME ST PRI SIZE CMD
  12.0   john            5/30 15:26   0+00:00:15 R  0   0.0  sleep.sh

1 jobs; 0 completed, 0 removed, 0 idle, 1 running, 0 held, 0 suspended
```

## Usage

```
	usage: $0 -m|-e master-address|-s master-address [-c url-to-config] [-k url-to-public-key] [-u inject user -p password]
	
	Configure HTCondor role and start supervisord for this container. 
	
	OPTIONS:
	  -m                	configure container as HTCondor master
	  -e master-address 	configure container as HTCondor executor for the given master
	  -s master-address 	configure container as HTCondor submitter for the given master
	  -c url-to-config  	config file reference from http url.
	  -k url-to-public-key	url to public key for ssh access to root
	  -u inject user	inject a user without root privileges for submitting jobs accessing via ssh. -p password required
	  -p password		user password (see -u attribute).
```
