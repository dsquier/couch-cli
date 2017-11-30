# couchdb-utils

Shell scripts, test data, and related files used to manage CouchDB 2.x and above instances.

## Building CouchDB Chassis Tuner database

### 1. Create EC2 instance

Use the following AMI: `AMI-HERE`

Typically a `INSTANCE-TYPE` instance is used, but can be upgraded if load requires.

### 2. Create and mount EFS

Once the EC2 instance is created, SSH into it and run:

```
sudo apt-get install nfs-common
sudo mkdir /efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 fs-11111111.efs.us-west-2.amazonaws.com:/ /efs
sudo mkdir /efs/couchdb
sudo chown couchdb:couchdb /efs/couchdb
```

Add the EFS mount to fstab so it is automatically mounted on instance reboot:

```
sudo echo "fs-11111111.efs.us-west-2.amazonaws.com:/ /efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0" >> /etc/fstab
```

### 3. Create and seed `master` database

Configure `.env` file and run `seed.sh`

### 4. Setup backups on EC2 instance

As ubuntu user, create a `~ubuntu/cron` directory and copy the following files to it:

```
couchdb-backup
couchdb-restore
couchdb-list-backups
```

Then make them executab:

```
chmod +x ~ubuntu/cron/*
```

Finally, add the following line to crontab:

```
CRONTAB ENTRY HERE
```

## Creating a CouchDB AMI

* [CouchDB 2.1.1 Installation Guide](http://docs.couchdb.org/en/2.1.1/install/unix.html)

### 1. Create a new EC2 instance using Ubuntu 16.04LTS and update any packages

```
sudo apt-get update
sudo apt-get upgrade
```

### 2. Install latest CouchDB package

```
echo "deb https://apache.bintray.com/couchdb-deb xenial main" | sudo tee -a /etc/apt/sources.list
curl -L https://couchdb.apache.org/repo/bintray-pubkey.asc | sudo apt-key add -
sudo apt-get update && sudo apt-get install couchdb
```

### 3. Modify CouchDB configuration

Edit the following two parameters under `[chttpd]` in `/opt/couchdb/etc/local.ini` to match:

```
bind_address = 0.0.0.0
port = 5984
```

The updated block should then look like:

```
[chttpd]
port = 5984
bind_address = 0.0.0.0
; Options for the MochiWeb HTTP server.
;server_options = [{backlog, 128}, {acceptor_pool_size, 16}]
; For more socket options, consult Erlang's module 'inet' man page.
;socket_options = [{recbuf, 262144}, {sndbuf, 262144}, {nodelay, true}]
```

### 4. Save EC2 instance into a new AMI
