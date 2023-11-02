#!/usr/bin/env bash

if [[ "$(docker images -q libsql:kysely-nextauth-test 2> /dev/null)" == "" ]]; then
    echo "Building libsql docker image, this might take a while..." 
    docker build https://github.com/tursodatabase/libsql.git#main -t libsql:kysely-nextauth-test 
fi

docker run -d -t \
    --rm \
    --name libsql \
    -p 8080:8080 \
    libsql:kysely-nextauth-test

docker run -d \
  --name mysql \
  --rm \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=kysely_test \
  -p 3308:3306 \
  -v "$(pwd)"/tests/scripts/mysql-init.sql:/data/application/init.sql \
  mysql/mysql-server \
  --init-file /data/application/init.sql

docker run -d \
  --name postgres \
  --rm \
  -e POSTGRES_DB=kysely_test \
  -e POSTGRES_USER=kysely \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  -p 5434:5432 \
  postgres

  
echo "waiting 15 seconds for databases to start..."
echo "15 seconds may not be enough for mysql to start - consider increasing if necessary...(try 300)"
sleep 15

# Always stop container, but exit with 1 when tests are failing
if npx jest tests; then
  docker stop mysql && docker stop postgres && docker stop libsql; 
else
  docker stop mysql && docker stop postgres && docker stop libsql && exit 1
fi 

