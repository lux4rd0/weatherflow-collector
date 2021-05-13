FROM grafana/promtail:2.2.1

RUN apt-get update && apt-get install -y bc curl dumb-init bash python procps coreutils sysstat

RUN mkdir /weatherflow-collector

COPY health_check.sh host-performance-influxdb.sh local-udp-influxdb.sh loki-config.yml remote-forecast-influxdb.sh remote-import-influxdb.sh remote-rest-influxdb.sh remote-socket-influxdb.sh start.sh logcli-linux-amd64 weatherflow-listener.py websocat_amd64-linux-static jq /weatherflow-collector/

COPY jq /usr/bin/

RUN chmod +x /weatherflow-collector/health_check.sh /weatherflow-collector/host-performance-influxdb.sh /weatherflow-collector/local-udp-influxdb.sh /weatherflow-collector/remote-forecast-influxdb.sh /weatherflow-collector/remote-rest-influxdb.sh /weatherflow-collector/logcli-linux-amd64 /weatherflow-collector/jq /weatherflow-collector/remote-socket-influxdb.sh /weatherflow-collector/start.sh /weatherflow-collector/websocat_amd64-linux-static /weatherflow-collector/remote-import-influxdb.sh

RUN chmod +x /usr/bin/jq

HEALTHCHECK --interval=5s --timeout=3s CMD /weatherflow-collector/health_check.sh

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

WORKDIR /weatherflow-collector

CMD ["/weatherflow-collector/start.sh"]
