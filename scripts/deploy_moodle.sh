#!/bin/bash

# Para mostrar los comandos que se van ejecutando
set -ex

# Importamos las variables de entorno
source .env

# Eliminamos descargas previas de Moodle
rm -rf /tmp/moodle*

# Eliminamos descargas previas de /var/www/
rm -rf /var/www/*

# Descargamos Moodle
wget https://download.moodle.org/download.php/direct/stable405/moodle-latest-405.tgz -P /tmp

# Extraemos Moodle
tar -zxvf /tmp/moodle-latest-405.tgz -C /tmp

# Movemos Moodle al directorio deseado
mv /tmp/moodle $MOODLE_DIRECTORY

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

# Configuramos Moodle
cp $MOODLE_DIRECTORY/config-dist.php $MOODLE_DIRECTORY/config.php
sed -i "s/'localhost'/'${MOODLE_DB_HOST//\//\\/}'/g" $MOODLE_DIRECTORY/config.php 
sed -i "s/'moodle'/'${MOODLE_DB_NAME//\//\\/}'/g" $MOODLE_DIRECTORY/config.php 
sed -i "s/'username'/'${MOODLE_DB_USER//\//\\/}'/g" $MOODLE_DIRECTORY/config.php 
sed -i "s/'password'/'${MOODLE_DB_PASSWORD//\//\\/}'/g" $MOODLE_DIRECTORY/config.php 
sed -i "s/'wwwroot'.*/'${MOODLE_DOMAIN//\//\\/}'/g" $MOODLE_DIRECTORY/config.php 
sed -i "s/'dataroot'.*/'${MOODLE_DATA_DIRECTORY//\//\\/}'/g" $MOODLE_DIRECTORY/config.php 

# Creamos el directorio de datos de Moodle
mkdir -p $MOODLE_DATA_DIRECTORY
chown -R www-data:www-data $MOODLE_DATA_DIRECTORY
chmod -R 755 $MOODLE_DATA_DIRECTORY