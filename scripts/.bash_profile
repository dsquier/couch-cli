stty erase ^H
set -o vi
PS1="\u:\$PWD> "

## SHELL SUGAR
alias c="clear"
alias l="ls -lt"
alias ll="ls -lat"
alias suc="sudo su - couchdb"

## CouchDB
alias dbstart="sudo service couchdb start"
alias dbstop="sudo service couchdb stop"
alias dbps="ps -ef | grep -i couchdb"
alias dblog="sudo tail -400f /var/log/couchdb/couchdb.log"