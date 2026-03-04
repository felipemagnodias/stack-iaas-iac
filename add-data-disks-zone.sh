#!/bin/bash
set -e

echo "🔄 Setando subscription..."
az account set --subscription "$SUBSCRIPTION_ID"

echo "🔎 Validando quantidade de discos..."

if [ "$NUM_DISKS" -lt 1 ] || [ "$NUM_DISKS" -gt 4 ]; then
  echo "❌ Você pode adicionar no mínimo 1 e no máximo 4 discos."
  exit 1
fi

echo "🔎 Obtendo próximo LUN disponível..."

NEXT_LUN=$(az vm show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --query "storageProfile.dataDisks | length(@)" -o tsv)

for (( i=1; i<=NUM_DISKS; i++ ))
do
  LUN_NUMBER=$NEXT_LUN
  NEXT_LUN=$((NEXT_LUN+1))

  DISK_NAME="${VM_NAME}-datadisk-${LUN_NUMBER}"

  echo "🧩 Criando disco $DISK_NAME (${DATA_DISK_SIZE}GB - $DATA_DISK_SKU)"

  if [ "$DISK_ZONE" == "none" ]; then

    az disk create \
      --resource-group "$RESOURCE_GROUP" \
      --name "$DISK_NAME" \
      --size-gb "$DATA_DISK_SIZE" \
      --sku "$DATA_DISK_SKU" \
      --location "$LOCATION"

  else

    az disk create \
      --resource-group "$RESOURCE_GROUP" \
      --name "$DISK_NAME" \
      --size-gb "$DATA_DISK_SIZE" \
      --sku "$DATA_DISK_SKU" \
      --location "$LOCATION" \
      --zone "$DISK_ZONE"

  fi

  echo "🔗 Anexando disco ao VM (LUN $LUN_NUMBER)"

  az vm disk attach \
    --resource-group "$RESOURCE_GROUP" \
    --vm-name "$VM_NAME" \
    --name "$DISK_NAME" \
    --lun "$LUN_NUMBER" \
    --caching "$DATA_DISK_CACHE"

  echo "✅ Disco $DISK_NAME anexado com sucesso!"
done

echo "🎉 Processo finalizado com sucesso!"
