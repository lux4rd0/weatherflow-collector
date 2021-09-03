docker build  -f Dockerfile.amd64 -t lux4rd0/weatherflow-collector:latest -t lux4rd0/weatherflow-collector:$1 -t docker01.tylephony.com:5000/lux4rd0/weatherflow-collector:latest -t docker01.tylephony.com:5000/lux4rd0/weatherflow-collector:$1 .
docker push docker01.tylephony.com:5000/lux4rd0/weatherflow-collector:latest
docker push docker01.tylephony.com:5000/lux4rd0/weatherflow-collector:$1
docker push lux4rd0/weatherflow-collector:latest
docker push lux4rd0/weatherflow-collector:$1
