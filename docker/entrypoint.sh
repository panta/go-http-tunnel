#!/bin/sh
# docker entrypoint script

set -e

# If no command is provided, start an interactive shell
if [ -z "$1" ]; then
    set - "/bin/sh" -l
fi

if [ ! -d $CERT_DIR ]; then
  echo "[i] Make certs directory: ${CERT_DIR}"
  mkdir -p "${CERT_DIR}"
fi

if [ "$1" = 'tunneld' ]; then
  # generate three tier certificate chain

  echo "[i] Start OpenSSL, cert file save path: $CERT_DIR"
  SUBJ="/C=$COUNTY/ST=$STATE/L=$LOCATION/O=$ORGANISATION"

  if [ ! -f "$CERT_DIR/$ROOT_NAME.crt" ]; then
    echo "[i] Generate root cert $ROOT_NAME.crt"

    # generate root certificate
    ROOT_SUBJ="$SUBJ/CN=$ROOT_CN"

    openssl genrsa \
      -out "$ROOT_NAME.key" \
      "$RSA_KEY_NUMBITS"

    openssl req \
      -new \
      -key "$ROOT_NAME.key" \
      -out "$ROOT_NAME.csr" \
      -subj "$ROOT_SUBJ"

    openssl req \
      -x509 \
      -key "$ROOT_NAME.key" \
      -in "$ROOT_NAME.csr" \
      -out "$ROOT_NAME.crt" \
      -days "$DAYS"
      # -subj "$ROOT_SUBJ"

    # copy certificate to volume
    cp "$ROOT_NAME.crt" "$CERT_DIR"
  fi

  if [ ! -f "$CERT_DIR/$ISSUER_NAME.crt" ]; then
    echo "[i] Generate issuer cert $ISSUER_NAME.crt"
    # generate issuer certificate
    ISSUER_SUBJ="$SUBJ/CN=$ISSUER_CN"

    openssl genrsa \
      -out "$ISSUER_NAME.key" \
      "$RSA_KEY_NUMBITS"

    openssl req \
      -new \
      -key "$ISSUER_NAME.key" \
      -out "$ISSUER_NAME.csr" \
      -subj "$ISSUER_SUBJ"

    openssl x509 \
      -req \
      -in "$ISSUER_NAME.csr" \
      -CA "$ROOT_NAME.crt" \
      -CAkey "$ROOT_NAME.key" \
      -out "$ISSUER_NAME.crt" \
      -CAcreateserial \
      -extfile issuer.ext \
      -days "$DAYS"

    # copy certificate to volume
    cp "$ISSUER_NAME.crt" "$CERT_DIR"
  fi

  if [ ! -f "$CERT_DIR/$SERVER_NAME.key" ]; then
    echo "[i] Generate server key $SERVER_NAME.key"
    # generate server cert rsa key
    openssl genrsa \
      -out "$SERVER_NAME.key" \
      "$RSA_KEY_NUMBITS"

    # copy server cert rsa key to volume
    cp "$SERVER_NAME.key" "$CERT_DIR"
  fi

  if [ ! -f "$CERT_DIR/$SERVER_NAME.crt" ]; then
    echo "[i] Generate server certificate $SERVER_NAME.crt"
    # generate server certificate
    SERVER_SUBJ="$SUBJ/CN=$SERVER_CN"
    openssl req \
      -new \
      -key "$SERVER_NAME.key" \
      -out "$SERVER_NAME.csr" \
      -subj "$SERVER_SUBJ"

    openssl x509 \
      -req \
      -in "$SERVER_NAME.csr" \
      -CA "$ISSUER_NAME.crt" \
      -CAkey "$ISSUER_NAME.key" \
      -out "$SERVER_NAME.crt" \
      -CAcreateserial \
      -extfile server.ext \
      -days "$DAYS"

    # copy server certificate to volume
    cp "$SERVER_NAME.crt" "$CERT_DIR"
  fi

  if [ ! -f "$CERT_DIR/ca.pem" ]; then
    echo "[i] Make combined root and issuer ca.pem"
    # make combined root and issuer ca.pem
    cat "$CERT_DIR/$ISSUER_NAME.crt" "$CERT_DIR/$ROOT_NAME.crt" > "$CERT_DIR/ca.pem"
  fi

  if [ $# -eq 0 ]; then
    CMD="/usr/bin/tunneld --tlsCrt "$CERT_DIR/$SERVER_NAME.crt" --tlsKey "$CERT_DIR/$SERVER_NAME.key""
    if [[ -z "${CLIENTS}" ]]; then
      echo "no clients were specified"
    else
      CMD="${CMD} --clients="$CLIENTS""
    fi
    if [[ "${DEBUG}" == 'true' ]]; then
      CMD="${CMD} --debug"
      echo "debug on"
    fi
    if [[ "${DISABLE_HTTPS}" == 'true' ]]; then
      CMD="${CMD} --httpsAddr="" "
      echo "disabled https"
    fi
  else
    CMD="$@"
  fi
  echo "$CMD"
  exec $CMD
elif [ "$1" = 'tunnel' ]; then
  if [ ! -f "$CERT_DIR/$CLIENT_NAME.crt" ]; then
    echo "[i] Generate client certificate $CLIENT_NAME.crt"
    CLIENT_SUBJ="/C=$COUNTY/ST=$STATE/L=$LOCATION/O=$ORGANISATION/OU=$OU/CN=$CLIENT_CN"
    openssl req \
      -x509 \
      -nodes \
      -newkey rsa:${RSA_KEY_NUMBITS} \
      -keyout "${CERT_DIR}/${CLIENT_NAME}.key" \
      -out "${CERT_DIR}/${CLIENT_NAME}.crt" \
      -days ${DAYS} \
      -subj "${CLIENT_SUBJ}"
  fi

  if [ $# -eq 0 ]; then
    CMD="/usr/bin/tunnel -config "${TUNNEL_CONFIG}" start-all"
  else
    CMD="$@"
  fi
  echo "$CMD"
  exec $CMD
else
  # run the provided command
  exec "$@"
fi
