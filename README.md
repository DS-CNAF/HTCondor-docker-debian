# Docker container per HTCondor 

Dockerizzazione di HTCondor dei tre nodi: Master, Submit ed Executor.
L'immagine di base utilizzata è Debian Wheezy e si fa riferimento alla versione stable di condor (https://research.cs.wisc.edu/htcondor/debian/).

Per controllare e gestire i diversi processi lanciati nei singoli container, si utilizza supervisord.

## Architettura di riferimento

![Architettura HTCondor](architecture.png)

## Come utilizzare i Dockerfile

### Build dell'immagine 

Per ogni nodo (e directory) fare il build dell'immagine docker.

```bash
docker build --tag ds/condormaster condormaster/
docker build --tag ds/condorexecute condorexecute/
docker build --tag ds/condorsubmit condorsubmit/
```

### Run dei nodi
Nodo Master:

```bash 
docker run -d --name=condormaster ds/condormaster
```

```bash 
docker run -d -e MASTER=<MASTER_IP> --name=condorsubmit ds/condorsubmit
```

Lanciare un numero di nodi executor a piacere:

```bash 
docker run -d -e MASTER=<MASTER_IP> --name=condorexecute ds/condorexecute
```

### LOGS
```bash
docker logs <nome_container>
```
## TBD

* Gestione della sicurezza
* Sistemare i log
