FROM grafana/promtail:latest

RUN apt-get update && apt-get install -y curl jq bash python coreutils

RUN mkdir /weatherflow-listener

COPY start.sh /weatherflow-listener
COPY weatherflow-listener.py /weatherflow-listener
COPY backend-influxdb.sh /weatherflow-listener

RUN chmod +x /weatherflow-listener/start.sh
RUN chmod +x /weatherflow-listener/backend-influxdb.sh

ENTRYPOINT ["/weatherflow-listener/start.sh"]
