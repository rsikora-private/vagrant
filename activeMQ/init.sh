#!/bin/bash

apt-get update > /dev/null
apt-get -y install make

#install java
sudo apt-get install default-jre
#install Active MQ

mkdir /opt/activeMQ
cd /opt/activeMQ
wget http://ftp.piotrkosoft.net/pub/mirrors/ftp.apache.org//activemq/5.13.3/apache-activemq-5.13.3-bin.tar.gz
tar zxvf apache-activemq-5.13.3-bin.tar.gz
cd apache-activemq-5.13.3/bin
sudo ./activemq console
