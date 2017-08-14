FROM centos:latest
MAINTAINER Samir Caica <samir.caica@gmail.com>


RUN yum clean all

COPY ./jdk-8u144-linux-x64.tar.gz /opt/jdk-8u144-linux-x64.tar.gz

WORKDIR /opt

RUN tar xfvz jdk-8u144-linux-x64.tar.gz && \
	alternatives --install /usr/bin/java java /opt/jdk1.8.0_144/bin/java 2 && \
    alternatives --install /usr/bin/javac javac /opt/jdk1.8.0_144/bin/javac 2 && \
    alternatives --install /usr/bin/jar jar /opt/jdk1.8.0_144/bin/jar 2

ENV ZABBIX_VERSION 3.2.7

RUN groupadd -r zabbix && useradd -r -g zabbix zabbix

RUN yum -y install initscripts gcc gcc-c++ openssl-devel libyaml-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel curl-devel git man patch net-snmp-devel make epel-release glibc-devel automake libssh2-devel OpenIPMI-devel libxml2-devel postgresql-devel --nogpgcheck


WORKDIR /

COPY ./zabbix-$ZABBIX_VERSION.tar.gz /

RUN tar xvf zabbix-$ZABBIX_VERSION.tar.gz \
	&& cd zabbix-$ZABBIX_VERSION \
	&& ./configure \
	--sysconfdir=/etc/zabbix \
	--enable-server \
	--enable-java \
	--enable-agent \
	--with-net-snmp \
	--with-openipmi \
	--with-ssh2 \
	--with-libcurl \
	--with-libxml2 \
	--with-postgresql=/usr/bin/pg_config \
	&& make && make install \
	&& mkdir -p /var/run/zabbix \
	&& chown -R zabbix:zabbix /var/run/zabbix \
	&& cp -p misc/init.d/fedora/core5/zabbix_server /etc/rc.d/init.d/ \
	&& chmod +x /etc/rc.d/init.d/zabbix_server \
	&& cp -p misc/init.d/fedora/core5/zabbix_agentd /etc/rc.d/init.d/ \
	&& chmod +x /etc/rc.d/init.d/zabbix_agentd \
	&& chkconfig --add zabbix_server \
	&& chkconfig --add zabbix_agentd \
	&& chkconfig zabbix_server on \
	&& chkconfig zabbix_agentd on \
	&& mkdir -p /var/log/zabbix \
	&& touch /var/log/zabbix/zabbix_server.log \
	&& touch /var/log/zabbix/zabbix_agentd.log \
	&& chown zabbix:zabbix /var/log/zabbix -R


COPY ./conf/zabbix_server.conf /etc/zabbix/zabbix_server.conf
COPY ./conf/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf
	
ENV container docker

EXPOSE 10050 10051
CMD ["/sbin/init"]