#!/bin/bash

set -e
set -u
set -o pipefail

optparams="h:f:d:c:Ha"
help_text=$(
    cat <<EOF
Adds a given cert to the system

Usage:
    add_cert.sh [options]

Options:
    -f  cert file to add
    -h  show help
EOF
)

if (! getopts $optparams opt); then
    echo -e "$help_text"
    exit 2
fi

# parse option parameters
while getopts $optparams OPTION; do
    case $OPTION in
    f)
        CERT_FILE=$OPTARG
        ;;
    h)
        echo -e "$help_text"
        exit 2
        ;;
    *)
        echo "Incorrect options provided"
        echo -e "$help_text"
        exit 1
        ;;
    esac
done

CERT_FILE=${CERT_FILE:-"$HOME/.certs/wildcard.local.com.crt"}

if [ -f $CERT_FILE ]; then
    # echo "Removing old Certificate"
    # certutil -d sql:$HOME/.pki/nssdb -D -n $CERT_FILE

    echo "Adding new Certificate to your trusted certs..."
    certutil -d sql:$HOME/.pki/nssdb -A -t "P,," -n $CERT_FILE -i $CERT_FILE

    echo "Show local certificates:"
    certutil -d sql:$HOME/.pki/nssdb -L -n $CERT_FILE
else
    echo "Cert file $CERT_FILE does not exist"
fi
