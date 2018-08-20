#!/bin/bash
SFILE=$1

if [ -f "$SFILE" ] ; then
    sudo docker-compose -f $SFILE down
    sudo docker-compose -f $SFILE up -d
    sudo docker-compose -f $SFILE logs &> $SFILE.log
    sudo docker-compose -f $SFILE ps
else
    echo "Insert docker-compose file name!"
fi
