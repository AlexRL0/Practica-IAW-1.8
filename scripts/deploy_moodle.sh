#!/bin/bash

# Para mostrar los comandos que se van ejecutando
set -ex

# Importamos las variables de entorno
source .env

# Actualizamos el sistema y instalamos dependencias necesarias
apt-get update -y
apt-get upgrade -y
apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql php-cli php-curl php-zip php-xml php-mbstring php-gd

# Eliminamos descargas previas de Moodle
rm -rf /tmp/moodle*

# Descargamos Moodle
wget https://download.moodle.org/download.php/direct/stable40/moodle-latest-40.tgz -O /tmp/moodle-latest.tgz

# Extraemos Moodle
tar -zxvf /tmp/moodle-latest.tgz -C /var/www/

# Movemos Moodle al directorio deseado
mv /var/www/moodle $MOODLE_DIRECTORY

# Configuramos permisos para Moodle
chown -R www-data:www-data $MOODLE_DIRECTORY
chmod -R 755 $MOODLE_DIRECTORY

# Creamos la base de datos y el usuario para Moodle
mysql -u root <<< "DROP DATABASE IF EXISTS $MOODLE_DB_NAME"
mysql -u root <<< "CREATE DATABASE $MOODLE_DB_NAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
mysql -u root <<< "DROP USER IF EXISTS '$MOODLE_DB_USER'@'localhost'"
mysql -u root <<< "CREATE USER '$MOODLE_DB_USER'@'localhost' IDENTIFIED BY '$MOODLE_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $MOODLE_DB_NAME.* TO '$MOODLE_DB_USER'@'localhost'"
mysql -u root <<< "FLUSH PRIVILEGES"

# Configuramos Apache para Moodle
cat > /etc/apache2/sites-available/moodle.conf <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot $MOODLE_DIRECTORY
    ServerName $MOODLE_DOMAIN

    <Directory $MOODLE_DIRECTORY>
        Options FollowSymLinks
        AllowOverride None

        <IfModule mod_php7.c>
            php_admin_flag engine on
            php_admin_value upload_max_filesize 2M
            php_admin_value post_max_size 2M
        </IfModule>

        <IfModule mod_rewrite.c>
            Options +FollowSymLinks
            RewriteEngine On
        </IfModule>
    </Directory>

    <Directory $MOODLE_DIRECTORY/>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Activamos la configuración de Apache
a2ensite moodle.conf
a2enmod rewrite
systemctl restart apache2

# Configuramos Moodle
cp $MOODLE_DIRECTORY/config-dist.php $MOODLE_DIRECTORY/config.php
sed -i "s/'localhost'/'$MOODLE_DB_HOST'/g" $MOODLE_DIRECTORY/config.php
sed -i "s/'moodle'/'$MOODLE_DB_NAME'/g" $MOODLE_DIRECTORY/config.php
sed -i "s/'username'/'$MOODLE_DB_USER'/g" $MOODLE_DIRECTORY/config.php
sed -i "s/'password'/'$MOODLE_DB_PASSWORD'/g" $MOODLE_DIRECTORY/config.php
sed -i "s/'\/your\/moodle\/directory'/'$MOODLE_DIRECTORY'/g" $MOODLE_DIRECTORY/config.php
sed -i "s/'\/your\/data\/directory'/'$MOODLE_DATA_DIRECTORY'/g" $MOODLE_DIRECTORY/config.php

# Creamos el directorio de datos de Moodle
mkdir -p $MOODLE_DATA_DIRECTORY
chown -R www-data:www-data $MOODLE_DATA_DIRECTORY
chmod -R 755 $MOODLE_DATA_DIRECTORY

echo "Moodle ha sido instalado y configurado correctamente!"
