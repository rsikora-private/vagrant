#!/usr/bin/env bash
sudo
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo sed -i '/bindIp: 127.0.0.1/,/bindIp\:\ 127\.0\.0\.1/s/^/#/' /etc/mongod.conf
service mongod restart
echo "Mongodb it's running. Use it by localhost:27017."
