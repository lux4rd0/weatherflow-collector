FROM grafana/promtail:2.2.0

RUN apt-get update && apt-get install -y bc curl jq bash python coreutils

RUN mkdir /weatherflow-collector

COPY local-udp-influxdb.sh loki-config.yml remote-forecast-influxdb.sh remote-import-influxdb.sh remote-rest-influxdb.sh remote-socket-influxdb.sh start.sh weatherflow-listener.py websocat_amd64-linux-static /weatherflow-collector/

RUN chmod +x /weatherflow-collector/local-udp-influxdb.sh /weatherflow-collector/remote-forecast-influxdb.sh /weatherflow-collector/remote-rest-influxdb.sh /weatherflow-collector/remote-socket-influxdb.sh /weatherflow-collector/start.sh /weatherflow-collector/websocat_amd64-linux-static /weatherflow-collector/remote-import-influxdb.sh

ENTRYPOINT ["/weatherflow-collector/start.sh"]
