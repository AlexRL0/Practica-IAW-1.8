#!/bin/bash

# Para mostrar los comandos que se van ejecutando
set -ex

# Importamos las variables de entorno
source .env

# Eliminamos descargas previas de moodle
rm -rf /tmp/moodle-latest-405.tgz

# Descargamos el código fuente de moodle
wget https://download.moodle.org/download.php/direct/stable405/moodle-latest-405.tgz -P /tmp

# Extraemos el paquete de moodle
tar -xzvf /tmp/moodle-latest-405.tgz -C /tmp

# Eliminamos el contenido de instalaciones previas en /var/www/html
rm -rf /var/www/html/*

# Movemos el código fuente de Moodle a /var/www/html
mv -f /tmp/moodle/* /var/www/html

# Creamos la base de datos y el usuario para Moodle
mysql -u root <<< "DROP DATABASE IF EXISTS $MOODLE_DB_NAME"
mysql -u root <<< "CREATE DATABASE $MOODLE_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $MOODLE_USUARIO@$MOODLE_DB_HOST"
mysql -u root <<< "CREATE USER $MOODLE_USUARIO@$MOODLE_DB_HOST IDENTIFIED BY '$MOODLE_CONTRA'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $MOODLE_DB_NAME.* TO $MOODLE_USUARIO@$MOODLE_DB_HOST"

# Asignamos los permisos necesarios
chown -R www-data:www-data /var/www/html
chmod -R 775 /var/www/html