# Docker container per HTCondor 

Dockerizzazione di HTCondor dei tre nodi: Master, Submit ed Executor.
L'immagine di base utilizzata è Debian Wheezy e si fa riferimento alla versione stable di condor (https://research.cs.wisc.edu/htcondor/debian/).

Per controllare e gestire i diversi processi lanciati nei singoli container, si utilizza supervisord.

## Architettura di riferimento

![Architettura HTCondor](architecture.png)

## Come utilizzare i Dockerfile

### Build dell'immagine 

Se si vuole compilare da codice: per ogni nodo (e directory) fare il build dell'immagine docker.

```bash
docker build --tag dscnaf/htcondor-docker-debian-master condormaster/
docker build --tag dscnaf/htcondor-docker-debian-execute condorexecute/
docker build --tag dscnaf/htcondor-docker-debian-submit condorsubmit/
```

### Run dei nodi
Nodo Master:

```bash 
docker run -d --name=condormaster dscnaf/htcondor-docker-debian-master
```

```bash 
docker run -d -e MASTER=<MASTER_IP> --name=condorsubmit dscnaf/htcondor-docker-debian-submit
```

Lanciare un numero di nodi executor a piacere:

```bash 
docker run -d -e MASTER=<MASTER_IP> --name=condorexecute dscnaf/htcondor-docker-debian-execute
```

### LOGS
```bash
docker logs <nome_container>
```

### Test su nodi calico

I container sono chiaramente agnostici rispetto il layer di rete. In seguito c'è un esempio di test di comunicazione tra container su host diversi (calico01 - calico0(x)) tramite driver di rete [calico](https://www.projectcalico.org/)
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
   1 allow
core@calico-01 ~ $ docker run -d --net=calinet1 --name=condormaster dscnaf/htcondor-docker-debian-master
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
core@calico-0(x) ~ $ docker run -d -e MASTER=192.168.142.0 --net=calinet1 --name=condorsubmit dscnaf/htcondor-docker-debian-submit
core@calico-0(x) ~ $ docker run -d -e MASTER=192.168.142.0 --net=calinet1 --name=condorexecute dscnaf/htcondor-docker-debian-execute
core@calico-0(x) ~ $ docker exec -it condorexecute ping 192.168.142.0
PING 192.168.142.0 (192.168.142.0): 48 data bytes
56 bytes from 192.168.142.0: icmp_seq=0 ttl=62 time=0.048 ms
56 bytes from 192.168.142.0: icmp_seq=1 ttl=62 time=0.376 ms
^C--- 192.168.142.0 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max/stddev = 0.048/0.212/0.376/0.164 ms
```

## TBD

* Gestione della sicurezza
* Sistemare i log
