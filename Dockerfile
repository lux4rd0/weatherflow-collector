FROM grafana/promtail:2.2.0

RUN apt-get update && apt-get install -y bc curl jq bash python coreutils

RUN mkdir /weatherflow-listener

COPY start.sh weatherflow-listener.py local-udp-influxdb.sh remote-socket-influxdb.sh websocat_amd64-linux-static loki-config.yml remote-rest-influxdb.sh /weatherflow-listener/

RUN chmod +x /weatherflow-listener/start.sh /weatherflow-listener/local-udp-influxdb.sh /weatherflow-listener/remote-socket-influxdb.sh /weatherflow-listener/remote-rest-influxdb.sh /weatherflow-listener/websocat_amd64-linux-static

ENTRYPOINT ["/weatherflow-listener/start.sh"]
