FROM debian:jessie
MAINTAINER "Jaigouk Kim" <ping@jaigouk.kim>

RUN echo "update and install mongo" \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 \
    && echo 'deb http://downloads-distro.mongodb.org/repo/debian-sysvinit dist 10gen' > \
         /etc/apt/sources.list.d/mongodb.list \
    && apt-get update \
    && apt-get install -y adduser mongodb-org \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose ports.
#   - 27017: process
#   - 28017: http
EXPOSE 27017
EXPOSE 28017

ENTRYPOINT ["mongod"]
CMD ["-f", "/data/db/mongodb.conf"]
