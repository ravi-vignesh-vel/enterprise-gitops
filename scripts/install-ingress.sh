#!/bin/bash

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo update

helm upgrade --install ingress-nginx \
ingress-nginx/ingress-nginx \
-n ingress-nginx \
--create-namespace \
--set controller.service.type=LoadBalancer
