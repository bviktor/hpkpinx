#!/bin/sh

set -e

NGINX_ROOT='/etc/nginx'
HPKPINX_ROOT='/opt/hpkpinx'
MULTIPLE_HPKP_CONF=0
STATIC_PIN_FILE=""

. ${HPKPINX_ROOT}/config.sh

generate_pin ()
{
    echo -n "pin-sha256=\""
    set +e
    grep -i "begin ec private key" --quiet ${1}
    USE_RSA=$?
    set -e
    if [ ${USE_RSA} -eq 1 ]
    then
        ALGO='rsa'
    else
        ALGO='ec'
    fi
    PIN=$(openssl ${ALGO} -in ${1} -pubout 2>/dev/null | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64)
    if [ ${PIN} = '47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=' ]
    then
        echo -n 'MISSING KEY!'
    else
        echo -n ${PIN}
    fi
    echo -n "\"; "
}

if [ "$#" -ne 2 ]
then
    echo 'Usage:'
    echo -e '\thpkpinx.sh generate_pin <key.pem>'
    echo -e '\thpkpinx.sh deploy_cert <domain.name>'
    exit 1
fi

if [ ${1} = "generate_pin" ]
then
    generate_pin ${2}
    echo ""
elif [ ${1} = "deploy_cert" ]
then
    CERT_NAME=${2} # The second argument is the name of the cert
    if [ ${MULTIPLE_HPKP_CONF} -eq 1 ] # if we want multiple conf files we have to prefix the config file with the name
    then
        HPKP_CONF=${NGINX_ROOT}/${CERT_NAME}-hpkp.conf
    else
        HPKP_CONF=${NGINX_ROOT}/hpkp.conf
    fi
    if [ ${STATIC_PIN_FILE} != "" ] # if an path to an STATIC_PIN_FILE is set use it
    then
        # get the pin
        STATIC_PIN=$(cat "${STATIC_PIN_FILE}" | grep "${CERT_NAME}" | cut -d ' ' -f 2)
    fi
    if [ -e ${HPKP_CONF} ]
    then
        echo 'Backing up current hpkp.conf'
        \cp -f ${HPKP_CONF} ${HPKP_CONF}.bak
    fi
    echo 'Regenerating public key pins using new private keys'
    echo '# THIS FILE IS GENERATED, ANY MODIFICATION WILL BE DISCARDED' > ${HPKP_CONF}
    if [ ${DEPLOY_HPKP} -eq 1 ]
    then
        echo -n "add_header Public-Key-Pins '" >> ${HPKP_CONF}
    else
        echo -n "add_header Public-Key-Pins-Report-Only '" > ${HPKP_CONF}
    fi
    echo -n "pin-sha256=\"${STATIC_PIN}\"; " >> ${HPKP_CONF}
    generate_pin "${NGINX_ROOT}/certs/${CERT_NAME}/privkey.pem" >> ${HPKP_CONF}
    generate_pin "${NGINX_ROOT}/certs/${CERT_NAME}/privkey.roll.pem" >> ${HPKP_CONF}
    echo "max-age=${HPKP_AGE}';" >> ${HPKP_CONF}
fi
