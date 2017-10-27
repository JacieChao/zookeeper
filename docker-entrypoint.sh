#!/bin/bash

set -e

# Allow the container to be started with `--user`
if [ "$1" = 'zkServer.sh' -a "$(id -u)" = '0' ]; then
    chown -R "$ZOO_USER" "$ZOO_DATA_DIR" "$ZOO_DATA_LOG_DIR"
    exec su-exec "$ZOO_USER" "$0" "$@"
fi

# Generate the config only if it doesn't exist
if [ ! -f "$ZOO_CONF_DIR/zoo.cfg" ]; then
    CONFIG="$ZOO_CONF_DIR/zoo.cfg"
    echo "clientPort=$ZOO_PORT" >> "$CONFIG"
    echo "dataDir=$ZOO_DATA_DIR" >> "$CONFIG"
    echo "dataLogDir=$ZOO_DATA_LOG_DIR" >> "$CONFIG"

    echo "tickTime=$ZOO_TICK_TIME" >> "$CONFIG"
    echo "initLimit=$ZOO_INIT_LIMIT" >> "$CONFIG"
    echo "syncLimit=$ZOO_SYNC_LIMIT" >> "$CONFIG"

	echo $PODNAME

    # for server in $ZOO_SERVERS; do
    #     echo "$server" >> "$CONFIG"
    # done
    for ((count=1; count<=$REPLICOUNT; ++count));
    do
    	if [ "$[count-1]" -eq "$(hostname | awk -F'-' '{print $2}')" ];then
    		echo "server.$count=0.0.0.0:2888:3888:participant" >> "$CONFIG";
    	else
        	echo "server.$count=zoo-$[count-1].$DNS:2888:3888:participant" >> "$CONFIG";
        fi
    done
fi

# Write myid only if it doesn't exist
if [ ! -f "$ZOO_DATA_DIR/myid" ]; then
#    echo "${ZOO_MY_ID:-1}" > "$ZOO_DATA_DIR/myid"
    zooId=$(hostname | awk -F'-' '{print $2}')
    echo "$[zooId+1]" > "$ZOO_DATA_DIR/myid"
fi

exec "$@"