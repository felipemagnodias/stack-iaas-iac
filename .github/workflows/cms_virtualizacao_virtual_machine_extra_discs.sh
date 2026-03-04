#!/bin/bash
set -e

echo "🔐 ID da Subscription:"; read SUBSCRIPTION_ID
echo "📦 Nome do Resource Group da VM:"; read RESOURCE_GROUP
echo "🌐 Nome do Resource Group da VNet:"; read VNET_RG
echo "🖥️ Nome da VM:"; read VM_NAME
echo "🌍 Região (ex: eastus, brazilsouth):"; read LOCATION
echo "💡 Tamanho da VM (ex: Standard_D2as_v5):"; read VM_SIZE
echo "🖼️ Nome da imagem (ex: Canonical:0001-com-ubuntu-server-focal:20_04-lts:latest):"; read IMAGE
echo "👤 Nome do usuário administrador:"; read ADMIN_USER
read -s -p "🔑 Senha do usuário $ADMIN_USER: " ADMIN_PASS; echo ""

echo "🔌 Nome da Virtual Network EXISTENTE:"; read VNET_NAME
echo "📶 Nome da Subnet EXISTENTE:"; read SUBNET_NAME

echo "🌐 Deseja IP fixo? (sim/nao)"; read IP_FIXO
if [ "$IP_FIXO" == "sim" ]; then
    echo "Digite o IP privado desejado (ex: 10.0.1.10):"
    read PRIVATE_IP
fi

echo "🚀 Habilitar Accelerated Networking? (sim/nao)"
read ACCEL_NET

echo "💽 Tamanho do disco OS (GB):"; read OS_DISK_SIZE
echo "💾 Tipo do disco (Standard_LRS, Premium_LRS, StandardSSD_LRS):"; read STORAGE_SKU
echo "📦 Nome da conta de armazenamento para Boot Diagnostics:"; read BOOT_DIAG_STORAGE

# Tags
echo "🏷️ Hostname:"; read TAG_HOSTNAME
echo "🏷️ Environment:"; read TAG_ENV
TAG_SERVICE="Virtual Machine"
TAG_MANAGEMENT="TAM"
echo "🏷️ Sistema:"; read TAG_SISTEMA
echo "🏷️ Faturável (Sim/Não):"; read TAG_FATURAVEL
echo "🏷️ CHG:"; read TAG_CHG
echo "🏷️ TVT:"; read TAG_TVT

echo "🔄 Alterando subscription..."
az account set --subscription "$SUBSCRIPTION_ID"

echo "🔎 Buscando ID da Subnet existente..."
SUBNET_ID=$(az network vnet subnet show \
  --resource-group "$VNET_RG" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_NAME" \
  --query id -o tsv)

echo "🧩 Criando NIC..."

if [ "$IP_FIXO" == "sim" ]; then
    az network nic create \
      --resource-group "$RESOURCE_GROUP" \
      --name "${VM_NAME}-nic" \
      --subnet "$SUBNET_ID" \
      --private-ip-address "$PRIVATE_IP" \
      $( [ "$ACCEL_NET" == "sim" ] && echo "--accelerated-networking true" )
else
    az network nic create \
      --resource-group "$RESOURCE_GROUP" \
      --name "${VM_NAME}-nic" \
      --subnet "$SUBNET_ID" \
      $( [ "$ACCEL_NET" == "sim" ] && echo "--accelerated-networking true" )
fi

echo "🚀 Criando VM (SEM ZONA)..."

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
  --subscription "$SUBSCRIPTION_ID" \
  --tags hostname="$TAG_HOSTNAME" environment="$TAG_ENV" service="$TAG_SERVICE" management="$TAG_MANAGEMENT" sistema="$TAG_SISTEMA" faturavel="$TAG_FATURAVEL" CHG="$TAG_CHG" TVT="$TAG_TVT"

echo "✅ VM criada com sucesso (modelo regional - sem Availability Zone)!"

# ==========================================
# ADICIONAR DISCOS ADICIONAIS - SEM ZONA
# ==========================================

echo "💾 Deseja adicionar discos de dados? (sim/nao)"
read ADD_DISKS

if [ "$ADD_DISKS" == "sim" ]; then

    echo "🔎 Validando limite máximo de discos suportado pela VM..."

    MAX_DISKS=$(az vm list-skus \
        --location "$LOCATION" \
        --size "$VM_SIZE" \
        --query "[].capabilities[?name=='MaxDataDiskCount'].value" -o tsv)

    echo "ℹ️ Esta VM suporta até $MAX_DISKS discos de dados."

    echo "🔢 Quantos discos deseja adicionar?"
    read NUM_DISKS

    if [ "$NUM_DISKS" -gt "$MAX_DISKS" ]; then
        echo "❌ Quantidade excede limite suportado."
        exit 1
    fi

    NEXT_LUN=$(az vm show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$VM_NAME" \
        --query "storageProfile.dataDisks | length(@)" -o tsv)

    for (( i=1; i<=NUM_DISKS; i++ ))
    do
        echo "------------------------------"
        echo "📀 Configuração do disco $i"

        echo "Tamanho do disco (GB):"
        read DATA_DISK_SIZE

        echo "Tipo do disco (Standard_LRS, Premium_LRS, StandardSSD_LRS):"
        read DATA_DISK_SKU

        echo "Cache (None, ReadOnly, ReadWrite):"
        read DATA_DISK_CACHE

        echo "Deseja definir LUN manual? (sim/nao)"
        read MANUAL_LUN

        if [ "$MANUAL_LUN" == "sim" ]; then
            echo "Digite o número do LUN:"
            read LUN_NUMBER
        else
            LUN_NUMBER=$NEXT_LUN
            NEXT_LUN=$((NEXT_LUN+1))
        fi

        DISK_NAME="${VM_NAME}-datadisk-$LUN_NUMBER"

        echo "🧩 Criando disco $DISK_NAME (SEM ZONA)..."

        az disk create \
            --resource-group "$RESOURCE_GROUP" \
            --name "$DISK_NAME" \
            --size-gb "$DATA_DISK_SIZE" \
            --sku "$DATA_DISK_SKU" \
            --location "$LOCATION"

        echo "🔗 Anexando disco à VM (LUN $LUN_NUMBER)..."

        az vm disk attach \
            --resource-group "$RESOURCE_GROUP" \
            --vm-name "$VM_NAME" \
            --name "$DISK_NAME" \
            --lun "$LUN_NUMBER" \
            --caching "$DATA_DISK_CACHE"

        echo "✅ Disco $DISK_NAME anexado com sucesso!"
    done
fi

echo "🎉 Processo finalizado com sucesso!"
