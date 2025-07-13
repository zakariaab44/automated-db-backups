#! /bin/bash

echo "[mongodb-org-8.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/8.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-8.0.asc" > /etc/yum.repos.d/mongodb-org-8.0.repo

sudo yum install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod

curl -O https://fastdl.mongodb.org/tools/db/mongodb-database-tools-amazon2-x86_64-100.9.4.tgz
tar -zxvf mongodb-database-tools-amazon2-x86_64-100.9.4.tgz
sudo cp mongodb-database-tools-*/bin/* /usr/local/bin/

