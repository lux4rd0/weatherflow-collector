FROM grafana/promtail:2.2.0

RUN apt-get update && apt-get install -y bc curl jq bash python coreutils

RUN mkdir /weatherflow-listener

COPY start.sh weatherflow-listener.py udp-influxdb.sh rest-influxdb.sh websocat_amd64-linux-static loki-config.yml forecast-influxdb.sh /weatherflow-listener/

RUN chmod +x /weatherflow-listener/start.sh /weatherflow-listener/udp-influxdb.sh /weatherflow-listener/rest-influxdb.sh /weatherflow-listener/forecast-influxdb.sh /weatherflow-listener/websocat_amd64-linux-static

ENTRYPOINT ["/weatherflow-listener/start.sh"]
