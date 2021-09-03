docker build  -f Dockerfile.arm -t lux4rd0/weatherflow-collector:latest-arm64 -t lux4rd0/weatherflow-collector:$1-arm64 -t docker01.tylephony.com:5000/lux4rd0/weatherflow-collector:latest-arm64 -t docker01.tylephony.com:5000/lux4rd0/weatherflow-collector:$1-arm64 .
docker push docker01.tylephony.com:5000/lux4rd0/weatherflow-collector:latest-arm64
docker push docker01.tylephony.com:5000/lux4rd0/weatherflow-collector:$1-arm64
docker push lux4rd0/weatherflow-collector:latest-arm64
docker push lux4rd0/weatherflow-collector:$1-arm64
