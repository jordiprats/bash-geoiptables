#!/bin/bash

PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"

BASEDIRSCRIPT=$(dirname $0)
BASENAMESCRIPT=$(basename $0)

IPDENY_BASEURL="http://www.ipdeny.com/ipblocks/data/countries/"

GEOCHAIN="bannedcountries"

if [ ! -z "$1" ] && [ -f "$1" ];
then
  . $1 2>/dev/null
else
  if [[ -s "$BASEDIRSCRIPT/${BASENAMESCRIPT%%.*}.config" ]];
  then
    . $BASEDIRSCRIPT/${BASENAMESCRIPT%%.*}.config 2>/dev/null
  else
    echo "config file missing"
    exit 1
  fi
fi

if [ -z "${BANED_COUNTRIES}" ];
then
    echo "no countries defined"
    exit 1
fi

if [ -z "${GEOCHAIN}" ];
then
    echo "ERROR - geochain empty"
    exit 1
fi

iptables -F $GEOCHAIN > /dev/null 2>&1
iptables -X $GEOCHAIN > /dev/null 2>&1
iptables -N $GEOCHAIN

for COUNTRY in $BANED_COUNTRIES;
do
    OUT=$(mktemp /tmp/output.XXXXXXXXXX)
    curl "${IPDENY_BASEURL}/${COUNTRY}.zone" -o $OUT

    if [ -z "$(head -n1 $OUT)"];
    then
        echo "skipping country ${COUNTRY}"
    else
        IPS=$(egrep -v "^#|^$" $OUT)
        for IP in $IPS
        do
            iptables -A $GEOCHAIN -s $IP -j LOG --log-prefix "ban country ${COUNTRY}"
            iptables -A $GEOCHAIN -s $IP -j DROP
        done
    fi

    rm $OUT
done