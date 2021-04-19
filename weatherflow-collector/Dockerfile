FROM grafana/promtail:2.2.0

RUN apt-get update && apt-get install -y bc curl dumb-init jq bash python procps coreutils

RUN mkdir /weatherflow-collector

COPY health_check.sh local-udp-influxdb.sh loki-config.yml remote-forecast-influxdb.sh remote-import-influxdb.sh remote-rest-influxdb.sh remote-socket-influxdb.sh start.sh weatherflow-listener.py websocat_amd64-linux-static /weatherflow-collector/

RUN chmod +x /weatherflow-collector/health_check.sh /weatherflow-collector/local-udp-influxdb.sh /weatherflow-collector/remote-forecast-influxdb.sh /weatherflow-collector/remote-rest-influxdb.sh /weatherflow-collector/remote-socket-influxdb.sh /weatherflow-collector/start.sh /weatherflow-collector/websocat_amd64-linux-static /weatherflow-collector/remote-import-influxdb.sh

HEALTHCHECK --interval=5s --timeout=3s CMD /weatherflow-collector/health_check.sh

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["/weatherflow-collector/start.sh"]
