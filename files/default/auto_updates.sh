#!/bin/bash

LOGFILE=/var/log/automatic-updates.log
ERRFILE=/var/log/automatic-updates.err
RECFILE=/var/log/automatic-updates.rec


# Set path
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH



apt-get update | ts '%Y-%m-%d %T' >> $LOGFILE 2>> $ERRFILE
apt-get autoclean -y | ts '%Y-%m-%d %T' >> $LOGFILE 2>> $ERRFILE
DEBCONF_PRIORITY=critical DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -q --assume-yes -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" | ts '%Y-%m-%d %T' >> $LOGFILE 2>> $ERRFILE
apt-get check >> $LOGFILE 2>> $ERRFILE 
if [ $? -ne 0 ]
then
   dpkg --configure -a | ts '%Y-%m-%d %T' > $RECFILE  2>&1 
   apt-get -y --fix-broken install | ts '%Y-%m-%d %T' > $RECFILE  2>&1 
fi


