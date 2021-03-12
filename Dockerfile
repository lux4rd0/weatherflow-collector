FROM grafana/promtail:latest

RUN apt-get update && apt-get install -y bc curl jq bash python coreutils

RUN mkdir /weatherflow-listener

COPY start.sh /weatherflow-listener
COPY weatherflow-listener.py /weatherflow-listener
COPY udp-influxdb.sh /weatherflow-listener
COPY websocat_amd64-linux-static /weatherflow-listener
COPY loki-config.yml /weatherflow-listener

RUN chmod +x /weatherflow-listener/start.sh
RUN chmod +x /weatherflow-listener/udp-influxdb.sh
RUN chmod +x /weatherflow-listener/websocat_amd64-linux-static

ENTRYPOINT ["/weatherflow-listener/start.sh"]
