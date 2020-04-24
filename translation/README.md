# Ubuntu 20.04 Nginx PHP7.4 with OCI8 driver
Um projeto para construir uma imagem docker Ubuntu 20.04 com Nginx, php7.4 e driver oci8.

Para baixar a imagem:
```
git clone https://github.com/efcunha/ubuntu20.04-nginx-php7.4-oci8.git
docker build -t efcunha/ubuntu20.04-nginx-php7.4-oci8:7.4 .
```

## Instanciando o container
Comando para executar co container:
```
docker run -d --name nginx -p 8080:80 efcunha/ubuntu20.04-nginx-php7.4-oci8:7.4
```

Para visualizar abra um browze   ```http://<DOCKER_HOST>:8080```  Voçê visualizará uma pagina padrão.

### Diretorio

Se voçê desejar adicionar um diretorio de uma aplicação Web no Container:
```
docker run -d --name nginx -p 8080:80 -v caminho/para/sua/aplicação_php:/var/www efcunha/ubuntu20.04-nginx-php7.4-oci8:7.4
```
### Conectando em um Banco MYSQL
A vinculação a contêiners também expõe as variáveis de ambiente do contêiner.
Úteis para modelar e configurar aplicativos da web.

Run MySQL container com alguns detalhes extras:
```
docker run --name some-mysql -e MYSQL_ROOT_PASSWORD=yayMySQL -e MYSQL_DATABASE=wordpress -e \
MYSQL_USER=wordpress_user -e MYSQL_PASSWORD=wordpress_password -d mysql
```

Isso expõe as seguintes variáveis de ambiente ao contêiner quando vinculado:
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

## Características especiais
### Empurre o código para o Git
Para enviar as alterações de código de volta ao git, basta executar:
`` ``
docker exec -t -i <CONTAINER_NAME> /usr/bin/push
`` ``

### Retirar código do Git (Atualizar)
Para atualizar o código em um contêiner e puxar o formulário de código mais recente, git simplesmente execute:
`` ``
docker exec -t -i <CONTAINER_NAME> /usr/bin/pull
`` ``

### Modelo
** NOTA: Agora você precisa ativar os modelos **
Este contêiner configurará automaticamente seu aplicativo Web se você modelar seu código. 
Por exemplo, se você está vinculando ao MySQL como acima, e você tem um arquivo config.php 
no qual precisa definir os detalhes do MySQL, inclua tags de modelo de estilo $$ _ MYSQL_ENV_MYSQL_DATABASE _ $$.

Exemplo:
`` ``
<? php
database_name = $$ _ MYSQL_ENV_MYSQL_DATABASE _ $$;
database_host = $$ _ MYSQL_PORT_3306_TCP_ADDR _ $$;
...
?>
`` ``

### Usando variáveis de ambiente
Se você deseja vincular a um banco de dados MySQL externo e não usar o linking, 
pode passar variáveis diretamente para o contêiner que será configurado automaticamente pelo contêiner.

Exemplo:
```
docker run -e 'GIT_REPO=git@git.ngd.io:ngineered/ngineered-website.git' -e 'TEMPLATE_NGINX_HTML=1' \
-e 'GIT_BRANCH=stage' -e 'MYSQL_HOST=host.x.y.z' -e 'MYSQL_USER=username' -e 'MYSQL_PASS=password' \
-v /opt/ngddeploy/:/root/.ssh -p 8080:80 -d efcunha/ubuntu20.04-nginx-php7.4-oci8:7.4
```
Isso irá expor as seguintes variáveis que podem ser usadas para modelar seu código.
`` ``
MYSQL_HOST=host.x.y.z
MYSQL_USER=username
MYSQL_PASS=password
```
Para usar essas variáveis em um modelo, faça o seguinte em seu arquivo:
`` ``
<?php
database_host = $$_MYSQL_HOST_$$;
database_user = $$_MYSQL_USER_$$;
database_pass = $$_MYSQL_PASS_$$
...
?>
```

### Ativar modelo
Para acelerar o tempo de inicialização, a modelagem agora está desativada por padrão, 
se você deseja ativá-la, basta incluir o sinalizador abaixo:
`` ``
-e TEMPLATE_NGINX_HTML=1
```
### Template qualquer coisa
Sim *** ANYTHING ***, qualquer variável expostada por um contêiner vinculado ou pelo sinalizador ** - e ** 
permite modelar seus arquivos de configuração. Isso significa que você pode adicionar redis, mariaDB, 
memcache ou qualquer coisa que desejar ao seu aplicativo com muita facilidade.

## Registro e erros

### Exploração madeireira
Todos os logs agora devem ser impressos em stdout/stderr e estão disponíveis através do comando docker logs:
`` ``
docker logs <CONTAINER_NAME>
```
### Exibindo erros
Se você deseja exibir erros de PHP na tela (no navegador) para fins de depuração, use este recurso:
`` ``
-e ERROS = 1
`` ``

Para mais opções em instanciação de containers, leia a:
 [docker run reference](https://docs.docker.com/engine/reference/run/)