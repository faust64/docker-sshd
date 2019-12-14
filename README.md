# SSHD

Image that can be run alongside any container, offering with SSH and Rsync
access to part of its filesystem, for backup purposes.

Build with:

```
$ make build
```

Start Demo in OpenShift:

```
$ make ocdemo
```

Cleanup OpenShift assets:

```
$ make ocpurge
```


Environment variables and volumes
----------------------------------

The image recognizes the following environment variables that you can set during
initialization by passing `-e VAR=VALUE` to the Docker `run` command.

|    Variable name     |    Description                  | Default                 |
| :------------------- | ------------------------------- | ----------------------- |
|  `HOSTKEY_SOURCE`    | SSHD Host Keys Source Directory | `/etc/ssh`              |
|  `HOSTKEY_TARGET`    | SSHD Host Keys Target Directory | `/var/backup/sshd`      |
|  `MY_HOME`           | SSHD Home Directory             | `/home/backup`          |
|  `SSH_USERNAME`      | SSHD Allowed Username           | `backup`                |
|  `SSHD_PORT`         | SSHD Port                       | `2222`                  |
|  `SSHD_TMPDIR`       | SSHD Temp Directory             | `/var/backup/tmp`       |

You can also set the following mount points by passing the `-v /host:/container`
flag to Docker.

|  Volume mount point  | Description                     |
| :------------------- | ------------------------------- |
|  `/.ssh`             | SSHD Authorized Keys            |


You may connect with username `backup`, on port `${SSHD_PORT}`, using the
private key matching the public key installed as `/.ssh/id_rsa.pub`.

This image is meant to be used alongside any container we may need ssh or
rsync access, backing up parts of its filesystem. Setup your DeploymentConfig
sharing proper directories and write your backup scripts according to those
paths you would have defined.
