# Dockerizing HTCondor submit node
# Based on debian:wheezy, installs HTCondor following the instructions from:
# https://research.cs.wisc.edu/htcondor/debian/
# Condor version 8.4.4-355883-deb7

FROM 	debian:wheezy
MAINTAINER Riccardo Bucchi <riccardo.bucchi26@gmail.com>
RUN	apt-get update && apt-get install -y wget procps && \
	echo "deb http://research.cs.wisc.edu/htcondor/debian/stable/ wheezy contrib" >> /etc/apt/sources.list && \ 
	wget -qO - http://research.cs.wisc.edu/htcondor/debian/HTCondor-Release.gpg.key | apt-key add - && \
        export DEBIAN_FRONTEND=noninteractive && \ 
	apt-get update && \
	apt-get install condor=8.4.4-355883-deb7 -y --force-yes	
RUN 	apt-get install -y openssh-server supervisor && \
 	apt-get install -y python-pip && pip install supervisor-stdout 
RUN 	mkdir -p /var/log/ssh/ && mkdir /var/run/sshd && chmod 0755 /var/run/sshd
COPY    key.pub /root/.ssh/authorized_keys
COPY 	supervisord.conf /etc/supervisor/conf.d/supervisord.conf
# Condor configs: either copy a local file or change DAEMONLIST and SESSION_KEYRING
# #COPY   condor_config /etc/condor/condor_config
RUN     sed -i '/#ALLOW_WRITE/a ALLOW_WRITE = * \nALLOW_READ = *' /etc/condor/condor_config && \
	sed -i 's/COLLECTOR, //g' /etc/condor/condor_config && \
	sed -i 's/NEGOTIATOR, //g' /etc/condor/condor_config && \
	sed -i 's/STARTD,//g' /etc/condor/condor_config && \
	echo "DISCARD_SESSION_KEYRING_ON_STARTUP=False" >> /etc/condor/condor_config
EXPOSE 	22
RUN    mkdir /home/condor && chown condor. /home/condor
ENTRYPOINT 	["/usr/bin/supervisord"]
