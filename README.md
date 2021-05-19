# Especificacion tecnica
## Configuracion de la red
Se tiene una sola VPC, `proyecto2`

### Subredes
- `public-ue1a-proyecto2`, la subred publica en la region US East 1a
- `public-ue1b-proyecto2`, la subred publica en la region US East 1b
- `app-ue1a-proyecto2`, la subred donde estaran la instancias de wordpress (la "app") en la region US East 1a
- `app-ue1b-proyecto2`, la subred donde estaran la instancias de wordpress (la "app") en la region US East 1b
- `db-ue1a-proyecto2`, la subred donde estara la base de datos

Las subredes publicas dirigen el trafico a internet al internet gateway, mientras que las subredes `*-app-proyecto2` rutean el trafico hacia internet a dos instancias NAT en las subredes publicas:
- `natgw-ue1a-proyecto2` para la US East 1a
- `natgw-ue1b-proyecto2` para la US East 1b

### Grupos de seguridad
- `secgroup-bhost-proyecto2`, INBOUND: 
    - SSH: Anywhere

- `secgroup-db-proyecto2`, INBOUND: 
    - SQL: secgroup-web-proyecto2

- `secgroup-natgw-proyecto2`, INBOUND:
    - HTTPS: Anywhere
    - HTTPS: Anywhere
    - SSH: Anywhere

- `secgroup-web-proyecto2`, INBOUND: 
    - HTTPS: Anywhere
    - HTTPS: Anywhere
    - SSH: Anywhere

- `all-access`
    - SSH: Anywhere
    - 24007: Anywhere
    - 24008: Anywhere
    - 38465 - 38467: Anywhere
    - 49152 - 49155: Anywhere



## La base de datos
Para este proyecto se uso RDS desplegado a una sola zona con MySQL. El nombre de la instancia de RDS es `db-ssl-proyecto2` y el nombre de la base de datos por defecto es `wordpress`, el usuario y contasena son `exampleuser` y `examplepass`.

Se creo un subnet group y se asocio con las dos subnets de base de datos. Luego se indico este grupo en la creacion de la instancia RDS.

## El load balancer
Para este proyecto se uso una instancia de Ubuntu llamada `lb-proyecto2` corriendo HAproxy para hacer las veces de load balancer. Hace parte de `secgroup-web-proyecto2`. Esta instancia recupera una lista de otras instancias pertenecientes al grupo de auto-scaling llamado `auto-scale-proyecto2` y las agrega a su archivo `haproxy.cfg`. 

### El IAM role
Para recuperar la lista de instancias pertenecientes a un auto-scaling group, se requirio crear un IAM role llamado `iam-role-proyecto2` con el permission policy `AmazonEC2ReadOnlyAccess`. 

### HAproxy
En el directorio `lb-config` encontrara los siguientes archivos: 
- `lb-setup.sh`, un script que contiene los comandos para instalar haproxy, ruby, aws-sdk, entre otras. Luego instala certbot, genera un certificado ssl
, y lo ubica en una carpeta especifica de la que despues leera HAproxy.
- `haproxy.cfg.template`, un archivo que debe ir ubicado en `/etc/haproxy/`.Sirve como una plantilla para actualizar el archivo de configuracion real `haproxy.cfg`.
- `haproxy-script.rb`, este script de ruby usa el amazon-sdk para obtener una lista de las instancias pertenecientes al grupo de autoscaling `auto-scale-proyecto2`. Se debe configurar con crontab para correr cada cierto tiempo para asegurarse de que este al dia. 

Como se puede ver, el template usa dos front-end, uno para http y otro para https, ambos con el mismo back-end. Esta configurado de forma tal que http redireccione a https. La encripcion con ssl ocurre en el load balancer, no en las instancias.

## La instancia de wordpress
El AMI para las intancias de wordpress en el auto-scaling group se baso en una instancia corriendo Amazon Linux llamada `ami-template2` que hace parte de `secgroup-web-proyecto2` y `all-access`.

### La persistencia en la capa de archivos
Inicialmente teniamos la intencion de poner toda los archivos de wordpress en un mount-point de un bucket de S3. De esta forma, multiples instancias compartirian los archivos. Sin embargo, el 14/05/2021, esta solucion fallo y no nos quedo claro por que. El error que producia era 403, a pesar de muchos intentos de darle todos los permisos o setearlos a lo que era indicado por la documentacion en linea. 

Decidimos entonces realizar la persistencia de datos con EFS. Lamentablemente, tuvimos demasiados problemas montando EFS, incluso despues de incluir los cambios recomendados en la guia. Por este motivo optamos por utilizar GlusterFS y configurarlo nosotros mismos. 

Aun asi incluimos S3 en nuestra solucion, quizas de manera un poco redundante: Usamos un plugin de wordpress que copia los archivos cargados a un bucket S3. Para hacer esto tuvimos que darle a la instancia otro rol AMI llamado `iam-role-s3-proyecto2` con permisos `AmazonS3FullAccess` y creamos un bucket llamado `s3-bucket-ssl-proyecto2`.

### Configuracion
En el directorio `instance-config` se encontraran los siguientes archivos:
- `docker-compose.yml`, es el archivo encargado del setup del contenedor de wordpress. Tiene las credenciales requeridas para conectarse a la base de datos. 
- `install-cmds.sh` instala docker, docker-compose, y s3fs. Este ultimo es un vestigio de cuando queriamos usarlo para contener todos los archivos wordpress, decidimos incluirlo aun asi. 
- `s3-ssl-mount.sh` es otro vestigio de el uso que le queriamos dar a s3 inicialmente, este script se hubiera programado con crontab para correr cada vez que se iniciaba la maquina y montar manualmente el bucket s3.
- `gluster-config.sh` contiene los comandos para configurar gluster y comentarios explicando cada uno. 

## Bastion hosts
Las instancias que hacen las veces de bastion host (`bhost-ue1a/ue1b-proyecto2`) corren Amazon Linux y hacen parte de `secgroup-bhost-proyecto2`

## Las NAT instances
Las NAT instances `natgw-ue1a-proyecto2` y `natgw-ue1b-proyecto2` se crearon usando el AMI `amzn-ami-vpc-nat-hvm-2018.03.0.20181116-x86_64-ebs`. Hacen parte del grupo `secgroup-natgw-proyecto2`.
