#!/usr/bin/bash

set -eo pipefail

# Configuration
DATADIR=${DATADIR:-'/data'}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-"nopassword"}
MY_CNF="/app/my.cnf"

# Initialize database if it doesn't exist
initialize_db() {
    echo "Initializing database..."
    mysqld --defaults-file=$MY_CNF --initialize-insecure --datadir=$DATADIR
    echo "Database initialized."
}

# Start MySQL and set root password
start_mysql_and_set_password() {
    echo "Starting MySQL server..."
    mysqld --defaults-file=$MY_CNF --datadir=$DATADIR --user=mysql --daemonize

    # Wait for MySQL to start
    until mysqladmin ping >/dev/null 2>&1; do
        echo "Waiting for MySQL to be ready..."
        sleep 2
    done

    echo "Setting root password and permissions..."
    mysql -uroot <<-EOSQL
        CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        FLUSH PRIVILEGES;
EOSQL

    echo "Stopping MySQL server..."
    mysqladmin -uroot -p${MYSQL_ROOT_PASSWORD} shutdown
}

# Main execution
if [ ! "$(ls -A $DATADIR)" ]; then
    echo "Data directory is empty. Initializing new database..."
    initialize_db
    start_mysql_and_set_password
else
    echo "Existing database found. Using it."
fi

exec mysqld_safe --defaults-file=$MY_CNF --datadir=$DATADIR --user=mysql
