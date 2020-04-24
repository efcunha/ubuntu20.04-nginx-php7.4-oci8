# Ubuntu 19.10 Nginx PHP7.4 with OCI8 driver
A project to build a docker image with php7.4, Nginx and oci8 driver.

Ler em [português](https://github.com/efcunha/nginx-php7.4-oci8/tree/master/translation)

```
git clone https://github.com/efcunha/nginx-php7.4-oci8.git
docker build -t efcunha/nginx-php7.4-oci8.git:7.4 .
```

## Running
To simply run the container:
```
docker run -d --name nginx -p 8080:80 efcunha/nginx-php7.4-oci8:7.4
```

You can then browse to ```http://<DOCKER_HOST>:8080``` to view the default install files.
### Volumes
If you want to link to your web site directory on the docker host to the container run:
```
docker run -d --name nginx -p 8080:80 -v /your_code_directory:/var/www efcunha/nginx-php7.4-oci8:7.4
```

### Linking
Linking to containers also exposes the linked container environment variables 
which is useful for templating and configuring web apps.

Run MySQL container with some extra details:
```
docker run --name some-mysql -e MYSQL_ROOT_PASSWORD=yayMySQL -e MYSQL_DATABASE=wordpress \
-e MYSQL_USER=wordpress_user -e MYSQL_PASSWORD=wordpress_password -d mysql
```

This exposes the following environment variables to the container when linked:
```
MYSQL_ENV_MYSQL_DATABASE=wordpress
MYSQL_ENV_MYSQL_ROOT_PASSWORD=yayMySQL
MYSQL_PORT_3306_TCP_PORT=3306
MYSQL_PORT_3306_TCP=tcp://XXX.XXX.XXX.XXX:3306
MYSQL_ENV_MYSQL_USER=wordpress_user
MYSQL_ENV_MYSQL_PASSWORD=wordpress_password
MYSQL_ENV_MYSQL_VERSION=5.6.22
MYSQL_NAME=/sick_mccarthy/mysql
MYSQL_PORT_3306_TCP_PROTO=tcp
MYSQL_PORT_3306_TCP_ADDR=XXX.XXX.XXX.XXX
MYSQL_ENV_MYSQL_MAJOR=5.6
MYSQL_PORT=tcp://XXX.XXX.XXX.XXX:3306
```

## Special Features
### Push code to Git
To push code changes back to git simply run:
```
docker exec -t -i <CONTAINER_NAME> /usr/bin/push
```

### Pull code from Git (Refresh)
In order to refresh the code in a container and pull newer code form git simply run:
```
docker exec -t -i <CONTAINER_NAME> /usr/bin/pull
```

### Templating
**NOTE: You now need to enable templates**
This container will automatically configure your web application if you template your code. 
For example if you are linking to MySQL like above, and you have a config.php file where 
you need to set the MySQL details include $$_MYSQL_ENV_MYSQL_DATABASE_$$ style template tags.

Example:
```
<?php
database_name = $$_MYSQL_ENV_MYSQL_DATABASE_$$;
database_host = $$_MYSQL_PORT_3306_TCP_ADDR_$$;
...
?>
```

### Using environment variables
If you want to link to an external MySQL DB and not using linking you can pass variables directly 
to the container that will be automatically configured by the container.

Example:
```
sudo docker run -e 'GIT_REPO=git@git.ngd.io:ngineered/ngineered-website.git' \
-e 'TEMPLATE_NGINX_HTML=1' -e 'GIT_BRANCH=stage' -e 'MYSQL_HOST=host.x.y.z' \
-e 'MYSQL_USER=username' -e 'MYSQL_PASS=password' -v /opt/ngddeploy/:/root/.ssh -p 8080:80 \
-d efcunha/nginx-php7.4-oci8:7.4
```

This will expose the following variables that can be used to template your code.
```
MYSQL_HOST=host.x.y.z
MYSQL_USER=username
MYSQL_PASS=password
```

To use these variables in a template you'd do the following in your file:
```
<?php
database_host = $$_MYSQL_HOST_$$;
database_user = $$_MYSQL_USER_$$;
database_pass = $$_MYSQL_PASS_$$
...
?>
```

### Enable Templating
In order to speed up boot time templating is now disabled by default, 
if you wish to enable it simply include the flag below:
```
-e TEMPLATE_NGINX_HTML=1
```

### Template anything
Yes ***ANYTHING***, any variable exposed by a linked container or the **-e** 
flag lets you template your configuration files. 
This means you can add redis, mariaDB, memcache or anything you want to your application very easily.

## Logging and Errors

### Logging
All logs should now print out in stdout/stderr and are available via the docker logs command:
```
docker logs <CONTAINER_NAME>
```

### Displaying Errors
If you want to display PHP errors on screen (in the browser) for debugging purposes use this feature:
```
-e ERRORS=1
```