#!/bin/bash
# 1. bring up master and slave
# 2. get master binlog name and position
# 3. setup slave
# 4. done

repl_user="CREATE USER \'repl\'@\'%\' IDENTIFIED BY \'dev1234\';"
echo $repl_user
docker exec mysql_master sh -c "mysql -u root -pdev1234 -e '$repl_user'"