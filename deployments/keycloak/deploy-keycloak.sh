#!/bin/bash

cd $(dirname $0) 

K8S_NAMESPACE=default

KEYCLOAK_ENDPOINT=${KEYCLOAK_ENDPOINT:-"http://keycloak.${K8S_NAMESPACE}:8080"}
KEYCLOAK_ADMIN_USER=${KEYCLOAK_ADMIN_USER:-"admin"}
KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD:-"admin"}
KEYCLOAK_REALM=${KEYCLOAK_REALM:-"realm01"}
KEYCLOAK_CLIENT_NAME=${KEYCLOAK_CLIENT_NAME:-"client01"}

KEYCLOAK_ORGANIZATION_01=${KEYCLOAK_ORGANIZATION_01:-"org01"}
KEYCLOAK_ORGANIZATION_DOMAIN_01=${KEYCLOAK_ORGANIZATION_DOMAIN_01:-"org01.com"}
USER_EMAIL_01=${USER_EMAIL_01:-"user01@${KEYCLOAK_ORGANIZATION_DOMAIN_01}"}
USER_PASSWORD_01=${USER_PASSWORD_01:-"Passw0rd!"}

KEYCLOAK_ORGANIZATION_02=${KEYCLOAK_ORGANIZATION_02:-"org02"}
KEYCLOAK_ORGANIZATION_DOMAIN_02=${KEYCLOAK_ORGANIZATION_DOMAIN_02:-"org02.com"}
USER_EMAIL_02=${USER_EMAIL_02:-"user02@${KEYCLOAK_ORGANIZATION_DOMAIN_02}"}
USER_PASSWORD_02=${USER_PASSWORD_02:-"Passw0rd!"}

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

echo "Creating organizations of keycloak.."
kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh create organizations -r ${KEYCLOAK_REALM} -s name=${KEYCLOAK_ORGANIZATION_01} -s domains='[{"name" : "'${KEYCLOAK_ORGANIZATION_DOMAIN_01}'", "verified" : true}]'
kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh create organizations -r ${KEYCLOAK_REALM} -s name=${KEYCLOAK_ORGANIZATION_02} -s domains='[{"name" : "'${KEYCLOAK_ORGANIZATION_DOMAIN_02}'", "verified" : true}]'

echo "Creating a client of the keycloak realm.."
OPENID_JWKS_ENDPOINT="${KEYCLOAK_ENDPOINT}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/certs"
kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh create clients -r ${KEYCLOAK_REALM} -s clientId=${KEYCLOAK_CLIENT_NAME} -s enabled=true -s directAccessGrantsEnabled=true -s redirectUris='["'${KEYCLOAK_ENDPOINT}'/*"]' -s attributes='{"jwks.url": "'${OPENID_JWKS_ENDPOINT}'", "use.jwks.url": "true"}'

echo "Creating users under the keycloak realm(${KEYCLOAK_REALM}).."
kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh create users -r ${KEYCLOAK_REALM} -s username=${USER_EMAIL_01} -s email=${USER_EMAIL_01} -s emailVerified=true -s enabled=true
kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh set-password -r ${KEYCLOAK_REALM} --username ${USER_EMAIL_01} --new-password ${USER_PASSWORD_01}

kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh create users -r ${KEYCLOAK_REALM} -s username=${USER_EMAIL_02} -s email=${USER_EMAIL_02} -s emailVerified=true -s enabled=true
kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh set-password -r ${KEYCLOAK_REALM} --username ${USER_EMAIL_02} --new-password ${USER_PASSWORD_02}

echo "Succeeded to deploy keycloak."
