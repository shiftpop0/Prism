@echo off
"C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" -h 127.0.0.1 -P 13306 -u root -prootroot -e "DROP DATABASE IF EXISTS wxzdb; CREATE DATABASE wxzdb DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
"C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" --default-character-set=utf8mb4 --binary-mode=1 -h 127.0.0.1 -P 13306 -u root -prootroot wxzdb < "C:\program1\shiftpop0\Prism\prism-app\.tmp\db-migration2\wxzdb_from_3306.clean.sql"
