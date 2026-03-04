#!/bin/bash
set -e

echo "🔐 Logando na subscription..."

az account set --subscription $SUBSCRIPTION_ID

echo "📦 Criando Resource Group..."

az group create \
  --name rg-github-actions \
  --location brazilsouth

echo "💾 Criando Storage Account..."

az storage account create \
  --name stgithub$RANDOM \
  --resource-group rg-github-actions \
  --location brazilsouth \
  --sku Standard_LRS

echo "✅ Deploy finalizado com sucesso!"
