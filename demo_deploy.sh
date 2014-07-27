#!/bin/bash

set -e

DOMAIN=${DOMAIN:-184.72.224.23.xip.io}
TARGET=api.${DOMAIN}

cf api | grep ${TARGET} || cf api ${TARGET} --skip-ssl-validation
cf apps | grep OK || cf login

TMPHOME=$(cd `dirname "$0"` && pwd)
if [ "$PREFIX" == "NONE" ]; then 
    PREFIX=
else 
    PREFIX=$USER
fi

PLATFORM_HOME=${PLATFORM_HOME:-$TMPHOME}
echo Home: $PLATFORM_HOME

DEMO_HOME=${DEMO_HOME:-$PLATFORM_HOME/customers-stores}
# TODO: clone and build

function deploy_app() {

    APP=$PREFIX$1
    NAME=$1
    [ "$1" == "stores" ] && NAME=store

    cf push $APP -m 512m -p $DEMO_HOME/rest-microservices-$NAME/target/*.jar --no-start
    cf env $APP | grep SPRING_PROFILES_ACTIVE || cf set-env $APP SPRING_PROFILES_ACTIVE cloud
    
    cf bind-service $APP ${PREFIX}configserver
    cf bind-service $APP ${PREFIX}eureka
    [ "$1" == "stores" ] &&  cf bind-service $APP ${PREFIX}mongodb
    
    cf restart $APP

}

apps=$*
if [ -z $1 ]; then
    apps='stores customers'
fi
for f in $apps; do
    deploy_app $f
done