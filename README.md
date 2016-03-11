# Docker container per HTCondor 

Dockerizzazione di HTCondor dei tre nodi: Master, Submit ed Executor.
L'immagine di base utilizzata è Debian Wheezy e si fa riferimento alla versione 8.4.4 di condor (https://research.cs.wisc.edu/htcondor/debian/).

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

Il nodo Submit è l'unico ad esporre ssh:

```bash 
docker run -d --name=condorsubmit -P ds/condorsubmit
```

Lanciare un numero di nodi executor a piacere:

```bash 
docker run -d --name=condorexecute -P ds/condorexecute
```

**N.B.:** attualmente è necessario 'connettere' il master manualmente, ovvero entrare nei container e modificare il file `/etc/hosts` e `/etc/condor/condor_config` alla voce `CONDOR_HOST` dei Submit e Execute.

### LOGS
```bash
docker logs <nome_container>
```


## TBD

* Connessione tra i container ancora manuale, va ancora inserito manualmente il riferimento al nodo master
* Gestione della rete su container deployati in host diversi
* Gestione della sicurezza
* Deploy della chiave ssh (solo per il nodo Submit) assegnata ad un utente non-root
* Sistemare i log