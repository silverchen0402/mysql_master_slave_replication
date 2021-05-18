# mysql_master_slave_replication

1. environment
  * master id=1, host port 3307
  * slave id=2, slave port 3308
  * binlog type replication
  * custom bridge network "mysql_net"

2. initial build
   run ./build.sh to setup replication

3. run
   docker-compose up
   docker-compose down
