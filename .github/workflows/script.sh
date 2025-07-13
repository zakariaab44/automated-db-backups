#! /bin/bash

sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker

sudo docker run -d --name mongodb  -p 27017:27017 -v /etc/mongo  -e MONGO_INITDB_ROOT_USERNAME=admin  -e MONGO_INITDB_ROOT_PASSWORD=secret   mongo:8.0 --bind_ip_all

curl -O https://fastdl.mongodb.org/tools/db/mongodb-database-tools-amazon2-x86_64-100.9.4.tgz
tar -zxvf mongodb-database-tools-amazon2-x86_64-100.9.4.tgz
sudo cp mongodb-database-tools-*/bin/* /usr/local/bin/







