#!/bin/bash

cd $(dirname $0) 

K8S_NAMESPACE=default

KEYCLOAK_ENDPOINT=${KEYCLOAK_ENDPOINT:-"http://keycloak.${K8S_NAMESPACE}:8080"}
KEYCLOAK_ADMIN_USER=${KEYCLOAK_ADMIN_USER:-"admin"}
KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD:-"admin"}
KEYCLOAK_REALM=${KEYCLOAK_REALM:-"realm01"}
KEYCLOAK_CLIENT_NAME=${KEYCLOAK_CLIENT_NAME:-"client01"}
USER_EMAIL=${USER_EMAIL:-"user01@email.com"}
USER_PASSWORD=${USER_PASSWORD:-"Passw0rd!"}

set -e
echo "Deploying keycloak.."
kubectl -n ${K8S_NAMESPACE} apply -f ./keycloak.yaml

echo "Waiting for keycloak.."
sleep 10
kubectl -n ${K8S_NAMESPACE} wait --timeout=10m --for=condition=ready pod -l app=keycloak

echo "Logging into keycloak.."
kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh config credentials --server ${KEYCLOAK_ENDPOINT} --realm master --user ${KEYCLOAK_ADMIN_USER} --password ${KEYCLOAK_ADMIN_PASSWORD}

echo "Creating a realm of keycloak.."
kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh create realms -s realm=${KEYCLOAK_REALM} -s enabled=true

echo "Creating a client of the keycloak realm.."
OPENID_JWKS_ENDPOINT="${KEYCLOAK_ENDPOINT}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/certs"
kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh create clients -r ${KEYCLOAK_REALM} -s clientId=${KEYCLOAK_CLIENT_NAME} -s enabled=true -s directAccessGrantsEnabled=true -s redirectUris='["'${KEYCLOAK_ENDPOINT}'/*"]' -s attributes='{"jwks.url": "'${OPENID_JWKS_ENDPOINT}'", "use.jwks.url": "true"}'

echo "Creating a user under the keycloak realm(${KEYCLOAK_REALM}).."
kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh create users -r ${KEYCLOAK_REALM} -s username=${USER_EMAIL} -s email=${USER_EMAIL} -s emailVerified=true -s enabled=true
kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh set-password -r ${KEYCLOAK_REALM} --username ${USER_EMAIL} --new-password ${USER_PASSWORD}

echo "Succeeded to deploy keycloak."
