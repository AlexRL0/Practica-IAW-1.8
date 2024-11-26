# Practica-IAW-1.8- Implantación de Moodle en Amazon Web Services (AWS)

## Pasos previos a la instalación

**para la instalación vamos a tener que crear la siguiente estructura de directorios y archivos:**

![](imagenes/directorio-1.7.png)

**Una vez creados los archivos y directorios, procedemos a la instalación de las herramientas.**

## Administración de Wordpress con la utilidad WP-CLI

## 1. Creamos un nombre de dominio para nuestro servidor con la web `no-ip`

### Paso 1. Crear el nombre del dominio 

Para crear el nombre de dominio en la página, tenemos que registrarnos y dirigirnos al sitio que muestra la captura y darle a **crear nombre de host**.

![](imagenes/no-ip-1.7.png)

Una vez dado al recuadro de crear el nombre, nos sale un asistente para poner el nombre de host que queramos, el dominio que queremos que lleve, la dirección ip de la máquina o pc que queremos que tenga ese nombre de host y el tipo de registro que queremos que lleve, en nuestro caso es el **DNS Host A**

![](imagenes/no-ip2-1.7.png)

Hecho esto ya podemos automatizar el proceso de la administración de Wordpress con la utilidad WP-CLI

## 2. Creación del archivo `deploy_wordpress_with_wpcli` para la instalación en la raíz

### Paso 1. Importamos el archivo de variables y mostramos los comandos que se van ejecutando 

```bash
source .env
```

```bash
set -ex
```

### Paso 2. Eliminamos descargas previas de WP-CLI

```bash
rm -rf /tmp/wp-cli.phar
```

> [!TIP]  
> Hacemos esto para evitar que haya duplicados dentro de ese directorio a la hora de descargarnos el WP-CLI.

### Paso 3. Descargamos el WP-CLI

```bash
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /tmp
```

### Paso 4. Le asignamos permisos de ejecución

```bash
chmod +x /tmp/wp-cli.phar
```

### Paso 5. Movemos el script WP-CLI al directorio /usr/local/bin

```bash
mv /tmp/wp-cli.phar /usr/local/bin/wp
```

### Paso 6. Eliminamos instalaciones previas en /var/www/html

```bash
rm -rf ${WORDPRESS_DIRECTORY}/*
```

### Paso 7. Descargamos el código fuente de WordPress

```bash
wp core download --locale=es_ES --path=$WORDPRESS_DIRECTORY --allow-root
```

### Paso 8. Creamos la base de datos y el usuario para WordPress

```bash
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
```

> [!IMPORTANT]  
> Las variables las cambiamos por las que tenemos en el archivo `.env` configuradas para que se cree todo correctamente.

### Paso 9. Creamos el archivo de configuración de WordPress

```bash
wp config create --dbname=$WORDPRESS_DB_NAME --dbuser=$WORDPRESS_DB_USER --dbpass=$WORDPRESS_DB_PASSWORD --dbhost=$WORDPRESS_DB_HOST --path=$WORDPRESS_DIRECTORY --allow-root
```

### Paso 10. Instalamos WordPress

```bash
wp core install --url=$LE_DOMAIN --title=$WORDPRESS_TITULO --admin_user=$WORDPRESS_USUARIO_ADMIN --admin_password=$WORDPRESS_CONTRA_ADMIN --admin_email=$WORDPRESS_EMAIL_ADMIN --path=$WORDPRESS_DIRECTORY --allow-root
```

> [!IMPORTANT]
> A continuación, se especifican los siguientes parámetros:
> 
> - **`--url`**: Es el dominio del sitio WordPress. En el ejemplo anterior, usamos el dominio `practica-wordpress.ddns.net`, que es el nombre configurado en el servidor DNS. En una instalación en una máquina local, también podríamos usar `localhost` o la dirección IP del servidor.
> - **`--title`**: Es el título del sitio WordPress.
> - **`--admin_user`**: Es el nombre del usuario administrador.
> - **`--admin_password`**: Es la contraseña del usuario administrador.
> - **`--admin_email`**: Es el correo electrónico del usuario administrador.
>
> Las variables las cambiamos por las que tenemos en el archivo `.env` configuradas para que se cree todo correctamente.

### Paso 11. Instalamos y activamos el theme mindscape

```bash
wp theme install mindscape --activate --path=$WORDPRESS_DIRECTORY --allow-root
```

### Paso 12. Instalamos un plugin

```bash
wp plugin install wps-hide-login --activate --path=$WORDPRESS_DIRECTORY --allow-root
```

### Paso 13. Configuramos el plugin de WHL

```bash
wp option update whl_page "$WORDPRESS_HIDE_LOGIN_URL" --path=$WORDPRESS_DIRECTORY --allow-root
```

> [!IMPORTANT]
> Esto lo hacemos para configurar el nombre de la URL que vamos a utilizar para acceder al panel de administración de wordpress.
>  
> La variable la cambiamos por la que tenemos en el archivo `.env` configurada para que se active correctamente.

### Paso 14. Configuramos los enlaces permanentes

```bash
wp rewrite structure '/%postname%/' --path=$WORDPRESS_DIRECTORY --allow-root
```

> [!IMPORTANT]
> El parámetro `/ %postname%/` indica el patrón de reescritura que se quiere usar. Existen otros patrones de reescritura disponibles:
> 
> - `/%year%/%monthnum%/%day%/%postname%/`: Año, mes, día y nombre de la entrada.
> - `/%year%/%monthnum%/%postname%/`: Año, mes y nombre de la entrada.
> - `/%year%/%postname%/`: Año y nombre de la entrada.
> - `/%postname%/`: Nombre de la entrada.
> 
> Es importante mencionar que para que los enlaces permanentes funcionen correctamente, el módulo `mod_rewrite` de Apache debe estar activado y la directiva `AllowOverride All` debe estar configurada en el sitio virtual de Apache.

### Paso 15. Cambiamos el propietario y el grupo al directorio /var/www/html/

```bash
chown -R www-data:www-data /var/www/html/
```

### Paso 16. Comprobación de que WordPress y los plugins funcionan

![](imagenes/WordPress2-1.7.png)

![](imagenes/WordPress-1.7.png)

![](imagenes/WordPress3-1.7.png)

![](imagenes/WordPress4-1.7.png)

> [!IMPORTANT]  
> Esto pasa al poner en la dirección web `https://practicawsarl.zapto.org/wp-admin/` ya que instalemos el plugin `wps-hide-login` que lo que hace es ocultar la página de inicio de sesión de wordpress al poner `wp-admin`. Si queremos ir al panel de administración, tendremos que poner la palabra que pusimos en la variable que le indiquemos al configurar el plugin, que en mi caso es `noimporta`.

![](imagenes/WordPress5-1.7.png)

![](imagenes/WordPress6-1.7.png)