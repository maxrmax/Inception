#!/bin/sh
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing database..."

    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    echo "Temp db start..."
    mariadbd --user=mysql --datadir=/var/lib/mysql &
    
    until mariadb-admin ping --silent; do
	echo "waiting for db availability..."
        sleep 1
    done

    echo "Running setup..."

    mariadb << EOF
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO '${SQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    echo "Shutting down temp init server..."
    mariadb-admin -u root -p${SQL_ROOT_PASSWORD} shutdown
fi

echo "Starting MariaDB..."
exec mariadbd --user=mysql --datadir=/var/lib/mysql --console
