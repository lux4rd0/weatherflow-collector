FROM grafana/promtail:2.2.0

RUN apt-get update && apt-get install -y bc curl jq bash python coreutils

RUN mkdir /weatherflow-collector

COPY start.sh weatherflow-listener.py local-udp-influxdb.sh remote-forecast-influxdb.sh remote-socket-influxdb.sh websocat_amd64-linux-static loki-config.yml remote-rest-influxdb.sh /weatherflow-collector/

RUN chmod +x /weatherflow-collector/start.sh /weatherflow-collector/local-udp-influxdb.sh /weatherflow-collector/remote-forecast-influxdb.sh /weatherflow-collector/remote-socket-influxdb.sh /weatherflow-collector/remote-rest-influxdb.sh /weatherflow-collector/websocat_amd64-linux-static

ENTRYPOINT ["/weatherflow-collector/start.sh"]
