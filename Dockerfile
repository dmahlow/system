# build instructions: http://docs.docker.io/en/latest/commandline/command/build/
# tl;dr:
#   sudo docker build [-t tag] .
#
# to run the container on port 3003:
#   sudo docker run -p 3003:3003 [image id|tag]
#
# to run production environment:
#   sudo docker run -e NODE_ENV=production -p 3003:3003 [image id|tag]
#
# for persistent db storage:
#   sudo docker run -p 3003:3003 -v /path/on/host:/data/db [image id|tag]
#
# notes:
#   - mongodb preallocation and journal are disabled to ensure fast first boot

FROM ubuntu:precise

MAINTAINER Daniel Mahlow "dmahlow@gmail.com"

RUN echo 'deb mirror://mirrors.ubuntu.com/mirrors.txt precise main universe multiverse' > /etc/apt/sources.list
RUN echo 'deb http://ppa.launchpad.net/chris-lea/node.js/ubuntu precise main'           > /etc/apt/sources.list.d/nodejs.list
RUN echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen'       > /etc/apt/sources.list.d/10gen.list

# mongodb repository key
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv C7917B12

# nodejs repository key
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10

# hack for initctl not being available in ubuntu
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -s /bin/true /sbin/initctl

RUN apt-get update
RUN apt-get install -y nodejs mongodb-10gen

# create mongodb directory
RUN mkdir -p /data/db

# install depdencenies
RUN apt-get install -y imagemagick python-dev make g++

WORKDIR /root/systemapp
ADD . /root/systemapp
RUN npm update

EXPOSE 3003
CMD ["bash", "-c", "mongod --noprealloc --nojournal & node index.js"]
