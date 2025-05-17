#!/bin/bash

# generate_certs.sh
# Generates self-signed certificates for internal services based on services.json

# Exit on error
set -e

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required. Please install jq."
  exit 1
fi

# Directory for certificates
CERT_DIR="certs"
mkdir -p "$CERT_DIR"

# Read domain from config.json
if [ ! -f "config.json" ]; then
  echo "Error: config.json not found."
  exit 1
fi
DOMAIN=$(jq -r '.domain' config.json)

# Read services from services.json
if [ ! -f "services.json" ]; then
  echo "Error: services.json not found."
  exit 1
fi
SERVICES=$(jq -r '.[] | .subdomain' services.json)

# Generate CA key and certificate if not exists
if [ ! -f "$CERT_DIR/ca.key" ] || [ ! -f "$CERT_DIR/ca.crt" ]; then
  echo "Generating CA key and certificate..."
  openssl genrsa -out "$CERT_DIR/ca.key" 2048
  openssl req -x509 -new -nodes -key "$CERT_DIR/ca.key" -sha256 -days 3650 -out "$CERT_DIR/ca.crt" -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=LocalCA"
else
  echo "CA key and certificate already exist."
fi

# Generate certificates for each service if not exists
for SUBDOMAIN in $SERVICES; do
  FULL_DOMAIN="$SUBDOMAIN.$DOMAIN"
  CERT_FILE="$CERT_DIR/$FULL_DOMAIN.crt"
  KEY_FILE="$CERT_DIR/$FULL_DOMAIN.key"
  if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "Generating certificate for $FULL_DOMAIN..."
    # Generate private key
    openssl genrsa -out "$KEY_FILE" 2048
    # Create CSR
    openssl req -new -key "$KEY_FILE" -out "$CERT_DIR/$FULL_DOMAIN.csr" -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=$FULL_DOMAIN"
    # Sign CSR with CA
    openssl x509 -req -in "$CERT_DIR/$FULL_DOMAIN.csr" -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" -CAcreateserial -out "$CERT_FILE" -days 365 -sha256
    # Clean up CSR
    rm "$CERT_DIR/$FULL_DOMAIN.csr"
  else
    echo "Certificate for $FULL_DOMAIN already exists."
  fi
done

echo "Certificates generated in $CERT_DIR"
echo "Install $CERT_DIR/ca.crt on client devices to trust the certificates."
