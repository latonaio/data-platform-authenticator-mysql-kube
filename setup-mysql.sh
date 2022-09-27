#!/bin/bash
DB_USER_NAME="root" # DBのユーザー名を指定
DB_USER_PASSWORD="root" # DBのパスワードを指定
POD_NAME="data-platform-authenticator-mysql-kube" # Podの名前を指定
DATABASE_NAME="DataPlatformAuthenticatorMySQLKube" # データベース名を指定
SQL_FILE="data-platform-authenticator-sql-business-user-data.sql" # sqlファイルの名前を指定
MYSQL_POD=$(kubectl get pod | grep ${POD_NAME} | awk '{print $1}')

kubectl exec -it ${MYSQL_POD} -- bash -c "mysql -u${DB_USER_NAME} -p${DB_USER_PASSWORD} -e \"CREATE DATABASE IF NOT EXISTS ${DATABASE_NAME} default character set utf8 ;\""

kubectl exec -it ${MYSQL_POD} -- bash -c "mysql -u${DB_USER_NAME} -p${DB_USER_PASSWORD} -D ${DATABASE_NAME} < /src/${SQL_FILE}"