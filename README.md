# irods-consumer

iRODS consumer in Docker

- v4.2.2 - Debian:stretch based (16.04 Xenial iRODS packages)
- v4.2.1 - Debian:jessie based (14.04 Trusty iRODS packages)
- v4.2.0 - Debian:jessie based (14.04 Trusty iRODS packages)

Jump to [Real world usage](#real_usage) example

**Note**: The iRODS consumer requires a pre-existing iRODS catalog provider to connect to as the consumer does not contain a catalog database of it's own. Most examples provided herein additionally make use of the [irods-provider-postgres](https://github.com/mjstealey/irods-provider-postgres) docker work running in a docker network named `irods_nw`.

```
$ docker network create \
	--driver bridge \
	irods_nw
$ docker run -d --name=provider \
	--network=irods_nw \
	--hostname=provider \
	mjstealey/irods-provider-postgres:4.2.2 \
	-i run_irods
``` 

## Supported tags and respective Dockerfile links

- 4.2.2, latest ([4.2.2/Dockerfile](https://github.com/mjstealey/irods-consumer/blob/master/4.2.2/Dockerfile))
- 4.2.1 ([4.2.1/Dockerfile](https://github.com/mjstealey/irods-consumer/blob/master/4.2.1/Dockerfile)) - In progress
- 4.2.0 ([4.2.0/Dockerfile](https://github.com/mjstealey/irods-consumer/blob/master/4.2.0/Dockerfile)) - In progress

### Pull image from dockerhub

```bash
$ docker pull mjstealey/irods-consumer:latest
```

### Build locally

```bash
$ cd irods-consumer/4.2.2
$ docker build -t consumer-4.2.2 .
$ docker run -d --name consumer consumer-4.2.2:latest
```

## Usage:

An entry point script named `docker-entrypoint.sh` that is internal to the container will have the provided arguments passed to it.

Supported arguments are:

- `-h`: show brief help
- `-i run_irods`: initialize iRODS consumer
- `-x run_irods`: use existing iRODS consumer files
- `-v`: verbose output

The options can be referenced by passing in `-h` as in the following example:

```
$ docker run --rm mjstealey/irods-provider-postgres:latest -h
$ docker run --rm mjstealey/irods-consumer -h
Usage: /docker-entrypoint.sh [-h] [-ix run_irods] [-v] [arguments]

options:
-h                    show brief help
-i run_irods          initialize iRODS 4.2.2 consumer
-x run_irods          use existing iRODS 4.2.2 consumer files
-v                    verbose output

Example:
  $ docker run --rm mjstealey/irods-consumer:4.2.2 -h           # show help
  $ docker run -d mjstealey/irods-consumer:4.2.2 -i run_irods   # init with default settings
```

### Example: Simple container deploy

```bash
$ docker run -d--name=consumer \
	--network=irods_nw \
	--hostname=consumer \
	mjstealey/irods-consumer:latest \
	-i run_irods
```
This call has been daemonized (additional **-d** flag) which would most likely be used in an actual environment

On completion a running container named **consumer** is spawned:

```
$ docker ps
CONTAINER ID        IMAGE                                     COMMAND                  CREATED             STATUS              PORTS                                      NAMES
397b1ef6d9e7        mjstealey/irods-consumer:4.2.2            "/docker-entrypoin..."   17 seconds ago      Up 18 seconds       1247-1248/tcp, 20000-20199/tcp             consumer
0cfa7cb35171        mjstealey/irods-provider-postgres:4.2.2   "/irods-docker-ent..."   3 minutes ago       Up 3 minutes        1247-1248/tcp, 5432/tcp, 20000-20199/tcp   provider
```

Default configuration is based on the default environment variables of the container which are defined as:

```
# default iRODS env
IRODS_SERVICE_ACCOUNT_NAME=irods
IRODS_SERVICE_ACCOUNT_GROUP=irods
# 1. provider, 2. consumer
IRODS_SERVER_ROLE=2
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
# UID / GID settings
UID_IRODS=998
GID_IRODS=998
```
Interaction with the iRODS server can be done with the `docker exec` command. The container has a definition of the `irods` Linux service account that has been associated with the `rods` **rodsadmin** user in iRODS. Interaction would look as follows:

- Sample **ilsresc**:

	```
	$ docker exec -u irods consumer ilsresc
	consumerResource:unixfilesystem
	demoResc:unixfilesystem
	```

- Sample **ils**:

  ```
  $ docker exec -u irods consumer ils
  /tempZone/home/rods:
  ```

- Sample **iadmin lz**:

  ```
  $ docker exec -u irods consumer iadmin lz
  tempZone
  ```
- Sample **ienv**:

	```
	$ docker exec -u irods consumer ienv
	irods_version - 4.2.2
	irods_host - consumer
	irods_user_name - rods
	irods_transfer_buffer_size_for_parallel_transfer_in_megabytes - 4
	irods_zone_name - tempZone
	irods_server_control_plane_encryption_num_hash_rounds - 16
	schema_version - v3
	irods_encryption_salt_size - 8
	irods_encryption_num_hash_rounds - 16
	irods_default_resource - consumerResource
	irods_home - /tempZone/home/rods
	irods_session_environment_file - /var/lib/irods/.irods/irods_environment.json.0
	irods_port - 1247
	irods_encryption_algorithm - AES-256-CBC
	schema_name - irods_environment
	irods_server_control_plane_encryption_algorithm - AES-256-CBC
	irods_environment_file - /var/lib/irods/.irods/irods_environment.json
	irods_default_number_of_transfer_threads - 4
	irods_cwd - /tempZone/home/rods
	irods_default_hash_scheme - SHA256
	irods_match_hash_policy - compatible
	irods_client_server_policy - CS_NEG_REFUSE
	irods_encryption_key_size - 32
	irods_server_control_plane_port - 1248
	irods_server_control_plane_key - TEMPORARY__32byte_ctrl_plane_key
	irods_client_server_negotiation - request_server_negotiation
	irods_maximum_size_for_single_buffer_in_megabytes - 32
	```

### Example: Persisting data

By sharing volumes from the host to the container, the user can persist data between container instances even if the original container definition is removed from the system.

Volumes to mount:

- **iRODS home**: map to `/var/lib/irods/` on the container
- **iRODS configuration**: map to `/etc/irods/` on the container

It is also necessary to define a **hostname** for the container when persisting data as the hostname information is written to the data store on initialization.

1. Create volumes on the host:

	```
	$ mkdir var_irods  # map to /var/lib/irods/
	$ mkdir etc_irods  # map to /etc/irods/
	```

2. Run the docker container with the `-i` flag for **init**:

	```
	$ docker run -d --name=consumer \
		--network=irods_nw \
		--hostname=consumer \
		-v $(pwd)/var_irods:/var/lib/irods \
		-v $(pwd)/etc_irods:/etc/irods \
		mjstealey/irods-consumer:latest \
		-i run_irods
	```
	Note, the host volumes now contain the relevant data to the iRODS deployment
	
	```
	$ ls var_irods
	VERSION.json          clients               configuration_schemas irodsctl              msiExecCmd_bin        scripts
	VERSION.json.dist     config                iRODS                 log                   packaging             test
	
	
	$ ls etc_irods
	core.dvm                        core.re                         hosts_config.json               service_account.config
	core.fnm                        host_access_control_config.json server_config.json
	```
	
	Go ahead and `iput` some data and verify it in the catalog.
	
	```
	$ docker exec -u irods consumer iput VERSION.json
	$ docker exec -u irods consumer ils -Lr
	/tempZone/home/rods:
	  rods              0 consumerResource          224 2017-11-12.04:34 & VERSION.json
	        generic    /var/lib/irods/iRODS/Vault/home/rods/VERSION.json
	```
	
	Note, the physical file can be found at: `$(pwd)/var_irods/iRODS/Vault/home/rods/VERSION.json` of the host

3. Stop and remove the provider container:

	```
	$ docker stop consumer
	$ docker rm -fv consumer
	```
	This destroys any host level definitions or default docker volumes related to the provider container and makes it impossible to recover the data from that container if we had not persisted it locally

4. Run a new docker container with the `-x` flag for **use existing**:

	```
	$ docker run -d --name=consumer \
		--network=irods_nw \
		--hostname=consumer \
		-v $(pwd)/var_irods:/var/lib/irods \
		-v $(pwd)/etc_irods:/etc/irods \
		mjstealey/irods-consumer:latest \
		-x run_irods
	```
	The name of the docker container needs to stay the same in this example due to the way the docker networking was established, the shared host volume mounts and defined hostname that the container should use remained the same.
	
	Verify that the file put from the previous container has persisted on the new container instance.
	
	```
	$ docker exec -u irods consumer ils -Lr
	/tempZone/home/rods:
	  rods              0 consumerResource          224 2017-11-12.04:34 & VERSION.json
	        generic    /var/lib/irods/iRODS/Vault/home/rods/VERSION.json
	```


