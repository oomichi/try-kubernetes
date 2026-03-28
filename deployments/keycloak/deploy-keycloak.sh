#!/bin/bash

cd $(dirname $0) 

source ./set-test-env.sh

set -e
echo "Deploying keycloak.."
kubectl -n ${K8S_NAMESPACE} apply -f ./keycloak.yaml

echo "Waiting for keycloak.."
sleep 10
kubectl -n ${K8S_NAMESPACE} wait --timeout=10m --for=condition=ready pod -l app=keycloak

echo "Logging into keycloak.."
kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh config credentials --server ${KEYCLOAK_ENDPOINT} --realm master --user ${KEYCLOAK_ADMIN_USER} --password ${KEYCLOAK_ADMIN_PASSWORD}

echo "Creating a realm of keycloak.."
kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh create realms -s realm=${KEYCLOAK_REALM} -s organizationsEnabled=true -s enabled=true

echo "Creating a client of the keycloak realm.."
OPENID_JWKS_ENDPOINT="${KEYCLOAK_ENDPOINT}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/certs"
kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh create clients -r ${KEYCLOAK_REALM} -s clientId=${KEYCLOAK_CLIENT_NAME} -s enabled=true -s directAccessGrantsEnabled=true -s redirectUris='["'${KEYCLOAK_ENDPOINT}'/*", "http://localhost:18080/*"]' -s attributes='{"jwks.url": "'${OPENID_JWKS_ENDPOINT}'", "use.jwks.url": "true"}'

echo "Succeeded to deploy keycloak."
