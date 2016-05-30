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
## TBD

* Gestione della sicurezza
* Sistemare i log
