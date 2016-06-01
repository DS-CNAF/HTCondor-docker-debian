# Dockerizing HTCondor submit node
# Based on debian:wheezy, installs HTCondor following the instructions from:
# https://research.cs.wisc.edu/htcondor/debian/

FROM 	debian:wheezy
MAINTAINER Riccardo Bucchi <riccardo.bucchi26@gmail.com>
ENV TINI_VERSION v0.9.0

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /sbin/tini
RUN	set -ex \
	&& apt-get update && apt-get install -y wget procps \
	&& chmod +x /sbin/tini \
	&& echo "deb http://research.cs.wisc.edu/htcondor/debian/stable/ wheezy contrib" >> /etc/apt/sources.list \
	&& wget -qO - http://research.cs.wisc.edu/htcondor/debian/HTCondor-Release.gpg.key | apt-key add - \
        && export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install condor -y --force-yes \
 	&& apt-get install -y python-pip && pip install supervisor supervisor-stdout \
	&& apt-get -y remove wget python-pip \
        && apt-get clean all 

COPY 	supervisord.conf /etc/supervisor/conf.d/supervisord.conf
# Condor configs: either copy a local file or change DAEMONLIST and SESSION_KEYRING
# #COPY   condor_config /etc/condor/condor_config
RUN     sed -i '/#ALLOW_WRITE/a ALLOW_WRITE = * \nALLOW_READ = *' /etc/condor/condor_config && \
	sed -i 's/COLLECTOR, //g' /etc/condor/condor_config && \
	sed -i 's/NEGOTIATOR, //g' /etc/condor/condor_config && \
	sed -i 's/STARTD,//g' /etc/condor/condor_config && \
	echo "DISCARD_SESSION_KEYRING_ON_STARTUP=False" >> /etc/condor/condor_config
COPY    run.sh /usr/local/sbin/run.sh
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/sbin/run.sh"]
