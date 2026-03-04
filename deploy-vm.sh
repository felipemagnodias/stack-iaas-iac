#!/bin/bash
set -e

echo "🔄 Alterando subscription..."
az account set --subscription "$SUBSCRIPTION_ID"

echo "🔎 Buscando ID da Subnet existente..."
SUBNET_ID=$(az network vnet subnet show \
  --resource-group "$VNET_RG" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_NAME" \
  --query id -o tsv)

echo "🧩 Criando NIC..."

NIC_CMD="az network nic create \
  --resource-group $RESOURCE_GROUP \
  --name ${VM_NAME}-nic \
  --subnet $SUBNET_ID"

if [ "$IP_FIXO" == "sim" ]; then
  NIC_CMD="$NIC_CMD --private-ip-address $PRIVATE_IP"
fi

if [ "$ACCEL_NET" == "sim" ]; then
  NIC_CMD="$NIC_CMD --accelerated-networking true"
fi

eval $NIC_CMD

echo "🚀 Criando VM..."

az vm create \
  --name "$VM_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --size "$VM_SIZE" \
  --image "$IMAGE" \
  --admin-username "$ADMIN_USER" \
  --admin-password "$ADMIN_PASS" \
  --authentication-type password \
  --nics "${VM_NAME}-nic" \
  --os-disk-size-gb "$OS_DISK_SIZE" \
  --storage-sku "$STORAGE_SKU" \
  --boot-diagnostics-storage "$BOOT_DIAG_STORAGE" \
  --public-ip-address "" \
  --tags hostname="$TAG_HOSTNAME" \
         environment="$TAG_ENV" \
         service="Virtual Machine" \
         management="TAM" \
         sistema="$TAG_SISTEMA" \
         faturavel="$TAG_FATURAVEL" \
         CHG="$TAG_CHG" \
         TVT="$TAG_TVT"

echo "✅ VM criada com sucesso!"
