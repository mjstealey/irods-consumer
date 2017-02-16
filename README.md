# irods-consumer
Docker implementation of iRODS consumer

## Supported tags and respective Dockerfile links

- 4.2.0, latest ([4.2.0/Dockerfile](https://github.com/mjstealey/irods-consumer/blob/master/4.2.0/Dockerfile))

### Pull image from dockerhub

```
docker pull mjstealey/irods-consumer:latest
```

### Usage:

**Example 1.** The iRODS consumer assumes that there is an already running instance of an iRODS provider server reachable over the network.

In this example we've previously launched a daemonized instance of [irods-provider-postgres:latest](https://github.com/mjstealey/irods-provider-postgres) and have specified that both it's docker name and hostname are **provider**:

```
$ docker run -d --name provider \
  --hostname provider \
  irods-provider-postgres:latest
```

When launching our iRODS **consumer** we want to match the version of the iRODS **provider** server and pass along a few attributes to allow the container to bind with the already running **provider** instance. We'll use the **--link** attribute to specify which container it should have IP information for, the **--hostname** attribute to use a known name for the created container, as well as specify the environment variable **IRODS\_PROVIDER\_HOST_NAME** to match the hostname we gave to the **provider** container.

```
$ docker run -d --name consumer \
  --hostname consumer \
  -e IRODS_PROVIDER_HOST_NAME=provider \
  --link provider:provider \
  mjstealey/irods-consumer:latest
```
This call has been daemonized with the **-d** flag, which would most likely be used in an actual environment.

On completion a running container named **consumer** is spawned with the following configuration:

```
-------------------------------------------
Zone name:                  tempZone
iRODS catalog host:         provider
iRODS server port:          1247
iRODS port range (begin):   20000
iRODS port range (end):     20199
Control plane port:         1248
Schema validation base URI: file:///var/lib/irods/configuration_schemas
iRODS server administrator: rods
-------------------------------------------
```

If deploying in a strictly docker environment, the /etc/hosts of the provider would also require the information for the consumer. We were able to pass the **--link** option to the consumer when it was created as the provider already existed, but this needs to be manually added to the provider.

Get the IP Address from the consumer.

```
$ docker exec consumer /sbin/ip -f inet -4 -o addr | grep eth | cut -d '/' -f 1 | rev | cut -d ' ' -f 1 | rev
172.17.0.3
``` 

Add the consumer host information to the /etc/hosts file of the provider

```
$ docker exec provider sh -c 'echo "172.17.0.3 consumer" >> /etc/hosts'
$ docker exec provider cat /etc/hosts
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::0	ip6-localnet
ff00::0	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
172.17.0.2	provider
172.17.0.3 consumer
```

Use the **docker exec** call to at the terminal interact with the container. Add the user definition of **-u irods** to specify that commands should be run as the **irods** user.

- Sample **iadmin lr**:

  ```
  $ docker exec -u irods provider iadmin lr
  bundleResc
  demoResc
  consumerResource
  $ docker exec -u irods consumer iadmin lr
  bundleResc
  demoResc
  consumerResource
  ```
From this call you can see the newly launched **consumerResource** from both the **provider** server as well as the **consumer** server.

- Sample **iadmin lr consumerResource**

  ```
  $ docker exec -u irods provider iadmin lr consumerResource
  resc_id: 10016
  resc_name: consumerResource
  zone_name: tempZone
  resc_type_name: unixfilesystem
  resc_net: consumer
  resc_def_path: /var/lib/irods/iRODS/Vault
  free_space:
  free_space_ts Never
  resc_info:
  r_comment:
  resc_status:
  create_ts 2017-02-16.20:18:03
  modify_ts 2017-02-16.20:18:03
  resc_children:
  resc_context:
  resc_parent:
  resc_objcount: 0
  resc_parent_context:
  ```

**Example 2.** iput a file from the provider container onto the consumerResource in the consumer container

- Get on the provider container as the irods user, create a sample file and iput it to the consumerResource.

  ```
  $ docker exec -ti -u irods provider /bin/bash
  $ cd ~
  irods@provider:~$ pwd
  /var/lib/irods
  irods@provider:~$ ipwd
  /tempZone/home/rods
  irods@provider:~$ touch hello.txt
  irods@provider:~$ iput -R consumerResource hello.txt
  irods@provider:~$ ils -l
  /tempZone/home/rods:
    rods              0 consumerResource            0 2017-02-16.20:48 & hello.txt
  ```

- Get on the consumer container and verify that the sample file is in the consumer vault.

  ```
  $ docker exec -ti -u irods consumer /bin/bash
  irods@consumer:/$ ils -l
  /tempZone/home/rods:
    rods              0 consumerResource            0 2017-02-16.20:48 & hello.txt
  irods@consumer:/$ ls -alh /var/lib/irods/iRODS/Vault/home/rods/
  total 8.0K
  drwxr-x--- 2 irods irods 4.0K Feb 16 20:48 .
  drwxr-x--- 3 irods irods 4.0K Feb 16 20:18 ..
  -rw------- 1 irods irods    0 Feb 16 20:48 hello.txt
  ```

**Example 3.** Use an environment file to pass the required environment variables for the iRODS `setup_irods.sh` call.

```
$ docker run -d --name resource \
  --env-file sample-env-file.env \
  --hostname resource \
  --link provider:provider \
  mjstealey/irods-consumer:latest
```
- Using sample environment file named `sample-env-file.env` (Update as required for your iRODS installation)

  ```bash
  IRODS_SERVICE_ACCOUNT_NAME=irods
  IRODS_SERVICE_ACCOUNT_GROUP=irods
  IRODS_PROVIDER_ZONE_NAME=tempZone
  IRODS_PROVIDER_HOST_NAME=provider
  IRODS_PORT=1247
  IRODS_PORT_RANGE_BEGIN=20000
  IRODS_PORT_RANGE_END=20199
  IRODS_CONTROL_PLANE_PORT=1248
  IRODS_SCHEMA_VALIDATION=file:///var/lib/irods/configuration_schemas
  IRODS_SERVER_ADMINISTRATOR_USER_NAME=rods
  IRODS_SERVER_ZONE_KEY=TEMPORARY_zone_key
  IRODS_SERVER_NEGOTIATION_KEY=TEMPORARY_32byte_negotiation_key
  IRODS_CONTROL_PLANE_KEY=TEMPORARY__32byte_ctrl_plane_key
  IRODS_SERVER_ADMINISTRATOR_PASSWORD=rods
  IRODS_VAULT_DIRECTORY=/var/lib/irods/iRODS/Vault
  ```

The outcome of this call would be identical to that described in Example 1, with the same results for the `docker exec -u irods provider iadmin ...` calls.
