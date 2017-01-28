#!/bin/sh

set -e

NGINX_ROOT='/etc/nginx'
HPKPINX_ROOT='/opt/hpkpinx'

echo 'Generating initial hpkpinx config'
cat << EOF > ${HPKPINX_ROOT}/config.sh
# the age of your policy
HPKP_AGE=10
# this is the pin of the backup key generated during initial setup
STATIC_PIN=fixme
# changing this can render your site permanently inaccessible, handle with extreme caution!
DEPLOY_HPKP=0
EOF

echo 'Setting up hpkp.conf'

read -p "Hostname (FQDN): " HNAME
PKEY_FILE="${HPKPINX_ROOT}/privkey-backup-${HNAME}.pem"
openssl genrsa -out ${PKEY_FILE} 4096
BACKUP_PIN=$(openssl rsa -in ${PKEY_FILE} -pubout 2>/dev/null | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64)
sed -i "s@fixme@${BACKUP_PIN}@g" ${HPKPINX_ROOT}/config.sh
echo "Backup key saved as ${HPKPINX_ROOT}/${PKEY_FILE}. Please move it to a secure location, preferably off-server."
sh ${HPKPINX_ROOT}/hpkpinx.sh deploy_cert ${HNAME}
ln -s ${NGINX_ROOT}/hpkp.conf ${HPKPINX_ROOT}/hpkp.conf
