FROM rockylinux:8-minimal

LABEL org.opencontainers.image.authors="info@galeracluster.com"

ARG MYSQL_VERSION=8.0.30-26.11
ARG OS_VERSION=el8
ARG GOSU_VERSION=1.16

ADD *.repo /etc/yum.repos.d

RUN rpm --import http://releases.galeracluster.com/GPG-KEY-galeracluster.com; \
  microdnf -y install epel-release; \
  microdnf -y install galera-4 mysql-wsrep-server-${MYSQL_VERSION}.${OS_VERSION}

# Cleanup & create
RUN rpm -e --nodeps mysql-wsrep-client mysql-wsrep-client-plugins; \
  microdnf clean all; \
  rm -rf /var/cache/dnf /var/cache/yum /usr/lib/.build-id; \
  rm -rf /var/cache/dnf /var/cache/yum /var/lib/mysql; \
  mkdir -p /var/lib/mysql /var/log/mysql; \
  chown mysql:mysql /var/lib/mysql /var/log/mysql

# add gosu for easy step-down from root
RUN gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64.asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && rm -fr /root/.gnupg/ \
    && chmod +x /usr/local/bin/gosu


# Config files
RUN mkdir /codership-initdb.d
ADD codership-entrypoint.sh /
ADD codership.cnf /etc/my.cnf.d/
RUN echo '!includedir /etc/my.cnf.d/' >> /etc/my.cnf;

USER mysql
VOLUME [/var/lib/mysql /var/log/mysql]
ENTRYPOINT ["/galera-entrypoint.sh"]
EXPOSE 3306/tcp 33060/tcp 4567/tcp 4568/tcp
CMD ["mysqld"]
