#!/bin/bash
set -e

echo "🔄 Alterando subscription..."
az account set --subscription "$SUBSCRIPTION_ID"

echo "🔧 Criando Resource Group '$RG_NAME' na região '$LOCATION'..."

az group create \
  --name "$RG_NAME" \
  --location "$LOCATION" \
  --tags hostname="$TAG_HOSTNAME" \
         environment="$TAG_ENV" \
         service="$TAG_SERVICE" \
         management="$TAG_MANAGEMENT" \
         sistema="$TAG_SISTEMA" \
         faturavel="$TAG_FATURAVEL" \
         CHG="$TAG_CHG" \
         TVT="$TAG_TVT"

echo "✅ Resource Group criado com sucesso!"
