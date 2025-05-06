#!/bin/bash

# Script para comprobar la conectividad entre frontend y backend en el monorepo actual
set -e

echo "===> IP de lm-backend-nginx:"
API_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' lm-backend-nginx)
echo "$API_IP"

echo "===> IP de lm-frontend-nginx:"
FRONT_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' lm-frontend-nginx)
echo "$FRONT_IP"

echo "===> Ping desde lm-frontend-app a lm-backend-nginx:"
docker exec lm-frontend-app ping -c 3 $API_IP || echo "No hay respuesta desde lm-backend-nginx"

echo "===> Ping desde lm-backend-api a lm-frontend-nginx:"
docker exec lm-backend-api ping -c 3 $FRONT_IP || echo "No hay respuesta desde lm-frontend-nginx"
