docker build  . -t lux4rd0/weatherflow-listener:latest -t lux4rd0/weatherflow-listener:$1 -t docker01.tylephony.com:5000/lux4rd0/weatherflow-listener:latest -t docker01.tylephony.com:5000/lux4rd0/weatherflow-listener:$1 --no-cache                                  
docker push docker01.tylephony.com:5000/lux4rd0/weatherflow-listener:latest
docker push docker01.tylephony.com:5000/lux4rd0/weatherflow-listener:$1
docker push lux4rd0/weatherflow-listener:latest
docker push lux4rd0/weatherflow-listener:$1
