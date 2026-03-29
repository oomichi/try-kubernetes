#!/bin/bash

cd $(dirname $0)

source ./set-test-env.sh

echo "Creating organizations of keycloak.."
kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh create organizations -r ${KEYCLOAK_REALM} -s name=${KEYCLOAK_ORGANIZATION_01} -s domains='[{"name" : "'${KEYCLOAK_ORGANIZATION_DOMAIN_01}'", "verified" : true}]'
kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh create organizations -r ${KEYCLOAK_REALM} -s name=${KEYCLOAK_ORGANIZATION_02} -s domains='[{"name" : "'${KEYCLOAK_ORGANIZATION_DOMAIN_02}'", "verified" : true}]'

function create_user() {
	USER_EMAIL=$1
	USER_PASSWORD=$2
	FIRST_NAME=$(echo ${USER_EMAIL} | awk -F@ '{print $1}' | awk -F. '{print $1}')
	LAST_NAME=$(echo ${USER_EMAIL} | awk -F@ '{print $1}' | awk -F. '{print $2}')
	kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh create users -r ${KEYCLOAK_REALM} -s username=${USER_EMAIL} -s firstName=${FIRST_NAME} -s lastName=${LAST_NAME} -s email=${USER_EMAIL} -s emailVerified=true -s enabled=true
	kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh set-password -r ${KEYCLOAK_REALM} --username ${USER_EMAIL} --new-password ${USER_PASSWORD}
}

function add_user_into_organization() {
	USERNAME=$1
	KEYCLOAK_ORGANIZATION=$2

	echo "Add ${USERNAME} into the organization ${KEYCLOAK_ORGANIZATION}.."
	ORG_ID=$(kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh get organizations -r ${KEYCLOAK_REALM} | jq -r 'map(select(.name=="'${KEYCLOAK_ORGANIZATION}'"))[0].id')
	USER_ID=$(kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh get users -r ${KEYCLOAK_REALM} | jq -r 'map(select(.username=="'${USERNAME}'"))[0].id')
	kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh create organizations/${ORG_ID}/members -r ${KEYCLOAK_REALM} -b ${USER_ID}
}

create_user ${USER_EMAIL_01} ${USER_PASSWORD_01}
create_user ${USER_EMAIL_02} ${USER_PASSWORD_02}

add_user_into_organization ${USER_EMAIL_01} ${KEYCLOAK_ORGANIZATION_01}
add_user_into_organization ${USER_EMAIL_02} ${KEYCLOAK_ORGANIZATION_02}

echo "Getting client_id of keycloak.."
KEYCLOAK_CLIENT_ID=$(kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh get clients -r ${KEYCLOAK_REALM} | jq -r 'map(select(.clientId=="'${KEYCLOAK_CLIENT_NAME}'"))[0].id')
if [ -z "${KEYCLOAK_CLIENT_ID}" ]; then
	echo "Failed to get KEYCLOAK_CLIENT_ID for ${KEYCLOAK_CLIENT_NAME}." 1>&2
	exit 1
fi

echo "Getting client_secret of keycloak.."
KEYCLOAK_CLIENT_SECRET=$(kubectl -n ${K8S_NAMESPACE} exec keycloak-0 -- /opt/keycloak/bin/kcadm.sh get clients/${KEYCLOAK_CLIENT_ID}/client-secret -r ${KEYCLOAK_REALM} | jq -r '.value')
if [ -z "${KEYCLOAK_CLIENT_SECRET}" ] || [ "${KEYCLOAK_CLIENT_SECRET}" == "null" ]; then
	echo "Failed to get KEYCLOAK_CLIENT_SECRET for ${KEYCLOAK_CLIENT_NAME}." 1>&2
	exit 1
fi

echo "Getting access_token of keycloak for ${USER_EMAIL_01}.."
ACCESS_TOKEN=$(curl --silent -d 'scope=organization' -d 'client_id='${KEYCLOAK_CLIENT_NAME} -d 'client_secret='${KEYCLOAK_CLIENT_SECRET} -d 'username='${USER_EMAIL_01} -d 'password='${USER_PASSWORD_01} -d 'grant_type=password' http://localhost:18080/realms/${KEYCLOAK_REALM}/protocol/openid-connect/token | jq -r .access_token)
if [ -z "${ACCESS_TOKEN}" ] || [ "${ACCESS_TOKEN}" == "null" ]; then
	curl -d 'scope=organization' -d 'client_id='${KEYCLOAK_CLIENT_NAME} -d 'client_secret='${KEYCLOAK_CLIENT_SECRET} -d 'username='${USER_EMAIL_01} -d 'password='${USER_PASSWORD_01} -d 'grant_type=password' http://localhost:18080/realms/${KEYCLOAK_REALM}/protocol/openid-connect/token
	echo "Failed to get ACCESS_TOKEN for ${USER_EMAIL_01}." 1>&2
	exit 1
fi

echo "Checking the expected organization name(${KEYCLOAK_ORGANIZATION_01}) could be gotten from access_token.."
ORGANIZATION=$(echo ${ACCESS_TOKEN} | jq -R 'split(".") | .[1] | @base64d | fromjson' | jq -r '.organization[0]')
if [ "${ORGANIZATION}" != "${KEYCLOAK_ORGANIZATION_01}" ]; then
	echo "ORGANIZATION: ${ORGANIZATION}"
	echo "KEYCLOAK_ORGANIZATION_01: ${KEYCLOAK_ORGANIZATION_01}"
	exit 1
fi

echo "Succeeded to test keycloak."
