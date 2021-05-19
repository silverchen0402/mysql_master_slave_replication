#!/bin/bash
# 1. bring up master and slave
# 2. get master binlog name and position
# 3. setup slave
# 4. done
docker-compose down

rm -rf master/datadir/*
rm -rf slave/datadir/*
rm -rf master/log/*
rm -rf slave/log/*
chmod 777 master/log
chmod 777 slave/log

docker-compose up -d

until docker exec mysql_master sh -c 'mysql -u root -pdev1234 -P 3307 -e ";"'
do
    echo "Waiting for mysql_master database connection..."
    sleep 5
done

echo ">>> bring up master and slave done"
repl_user='CREATE USER "repl"@"%" IDENTIFIED WITH "mysql_native_password" BY "dev1234";GRANT REPLICATION SLAVE ON *.* TO "repl"@"%";FLUSH PRIVILEGES;'
#echo $repl_user
docker exec mysql_master sh -c "mysql -u root -pdev1234 -P 3306 -e '$repl_user'"
echo ">>> create repl user done"



MASTER_STATUS=`docker exec mysql_master sh -c 'mysql -u root -pdev1234 -P 3306 -e "SHOW MASTER STATUS"'`
echo ">>> master status: $MASTER_STATUS"

CURRENT_LOG=`echo $MASTER_STATUS | awk '{print $6}'`
CURRENT_POS=`echo $MASTER_STATUS | awk '{print $7}'`

echo ">>> master file and position: ${CURRENT_LOG}:${CURRENT_POS}"

master_IP=`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mysql_master`
echo ">>> master IP: ${master_IP}"

until docker-compose exec mysql_slave sh -c 'mysql -u root -pdev1234 -P 3308 -e ";"'
do
    echo "Waiting for mysql_slave database connection..."
    sleep 5
done

slave_stmt="CHANGE REPLICATION SOURCE TO SOURCE_HOST='${master_IP}',SOURCE_USER='repl',SOURCE_PASSWORD='dev1234',SOURCE_LOG_FILE='${CURRENT_LOG}',SOURCE_LOG_POS=${CURRENT_POS}; START SLAVE;"
echo "$slave_stmt"
docker exec mysql_slave sh -c "mysql -u root -pdev1234 -P 3306 -e \"$slave_stmt\""
echo ">>> wait replication to settle"
sleep 5
SLAVE_STATUS=`docker exec mysql_slave sh -c "mysql -u root -pdev1234  -P 3306 -e 'SHOW SLAVE STATUS \G'"`

fn0=`/bin/mktemp`
echo $SLAVE_STATUS $fn0
echo $SLAVE_STATUS>$fn0

