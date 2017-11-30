#!/bin/bash

##
## install-couch
##
## Installs CouchDB using pre-built binaries to an Ubuntu 16.04 server
##
## Assumes pre-build binary is called: couchdb2.0.tar
##

TARFILE="/home/ubuntu/couchdb2.0.tar.gz"
SYSTEM="/etc/systemd/system"
LOCAL="."

echo "Creating couchdb user and group"

sudo adduser --system --shell /bin/bash --group --gecos "CouchDB Administrator" couchdb

echo "Untaring CouchDB 2.0 binaries to /home/couchdb"

sudo tar xvf $TARFILE -C /home/couchdb

echo "Setting permissions on /home/couchdb"

sudo chown -R couchdb:couchdb /home/couchdb

echo "Creating couchdb.service file"

sudo cat >$LOCAL/couchdb.service <<EOL
[Unit]
Description=CouchDB Server
After=network.target

[Service]
Type=simple
User=couchdb
ExecStart=/home/couchdb/couchdb/bin/couchdb -o /dev/stdout -e /dev/stderr
Restart=always
LimitNOFILE=65535

[Install]
WantedBy=default.target
EOL

echo "Creating fauxton.service file"

sudo cat >$LOCAL/fauxton.service <<EOL
[Unit]
Description=CouchDB Fauxton UI

[Service]
Type=simple
User=couchdb
ExecStart=/usr/bin/fauxton
Restart=always

[Install]
WantedBy=default.target
EOL

echo "Copying couchdb.service to $SYSTEM"

sudo cp $LOCAL/couchdb.service $SYSTEM

echo "Copying fauxton.service to $SYSTEM"

sudo cp $LOCAL/fauxton.service $SYSTEM

echo "Enable couchdb.service to start on reboot"

sudo systemctl enable couchdb.service

echo "Enable fauxton.service to start on reboot"

sudo systemctl enable fauxton.service
