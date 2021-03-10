#!/bin/sh

backend_type=$WEATHERFLOW_LISTENER_BACKEND_TYPE

if [ "$backend_type" = "loki" ]
then

/usr/bin/stdbuf -oL /usr/bin/python /weatherflow-listener/weatherflow-listener.py | /usr/bin/promtail --stdin --client.url "${WEATHERFLOW_LISTENER_LOKI_CLIENT_URL}" --client.external-labels=app=weatherflow,hostname=weatherflow

elif  [ "$backend_type" = "influxdb" ]
then

/usr/bin/stdbuf -oL /usr/bin/python /weatherflow-listener/weatherflow-listener.py | /weatherflow-listener/influxdb.sh

else

echo "No Backend Configured"

fi
