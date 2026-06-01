#!/bin/bash

set -e

echo "====================================="
echo " INSTALACAO ZABBIX AGENT - VIDEOSOFT"
echo "====================================="
# =========================================================
#  INSTALADOR ZABBIX AGENT + USB MONITOR - VIDEOSOFT
# =========================================================

ZABBIX_CONF_URL="https://raw.githubusercontent.com/willianberejuk-wowtec/zabbix-install/main/zabbix_agentd.conf"
USB_MONITOR_URL="http://noc-totens.videosoft.com.br/instalar_videosoft_usb_monitor.sh"

ZABBIX_CONF="/etc/zabbix/zabbix_agentd.conf"

# =========================================================
#  FUNCOES
# =========================================================

print_header() {
    clear
    echo "========================================================="
    echo "        INSTALACAO ZABBIX AGENT - VIDEOSOFT"
    echo "========================================================="
    echo ""
}

step() {
    echo ""
    echo "[$1] $2"
    echo "---------------------------------------------------------"
}

success() {
    echo "[OK] $1"
}

warning() {
    echo "[AVISO] $1"
}

error() {
    echo "[ERRO] $1"
}

# =========================================================
#  INICIO
# =========================================================

print_header

cd /tmp

echo "[1/9] Verificando repositorio Zabbix..."
# =========================================================
#  1 - REPOSITORIO ZABBIX
# =========================================================

step "1/9" "Verificando repositorio Zabbix"

if dpkg -l | grep -q zabbix-release; then
    echo "Repositorio Zabbix ja instalado."
    success "Repositorio Zabbix ja instalado."
else
    echo "Baixando repositorio Zabbix..."
    warning "Repositorio nao encontrado."

    echo "Baixando repositorio..."
wget -q https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu22.04_all.deb

    echo "Instalando repositorio Zabbix..."

    echo "Instalando repositorio..."
sudo dpkg -i zabbix-release_7.0-2+ubuntu22.04_all.deb

    success "Repositorio instalado."
fi

echo "[3/9] Ajustando repositorio..."
# =========================================================
#  2 - AJUSTE DO REPOSITORIO
# =========================================================

step "2/9" "Ajustando repositorio"

cat > /etc/apt/sources.list.d/zabbix.list << 'EOF'
sudo tee /etc/apt/sources.list.d/zabbix.list > /dev/null << 'EOF'
deb [arch=amd64] http://repo.zabbix.com/zabbix/7.0/ubuntu jammy main
deb-src http://repo.zabbix.com/zabbix/7.0/ubuntu jammy main
EOF

echo "[4/9] Atualizando repositorios..."
success "Repositorio configurado."

# =========================================================
#  3 - UPDATE
# =========================================================

step "3/9" "Atualizando repositorios"

sudo apt update

echo "[5/9] Verificando instalacao do Zabbix Agent..."
success "Repositorios atualizados."

# =========================================================
#  4 - INSTALACAO DO AGENT
# =========================================================

step "4/9" "Verificando instalacao do Zabbix Agent"

if dpkg -l | grep -q zabbix-agent; then
    echo "Zabbix Agent ja instalado. Atualizando configuracao..."
    warning "Zabbix Agent ja instalado."
    echo "Atualizando configuracao existente..."
else
    echo "Instalando Zabbix Agent..."
    echo "Instalando pacotes..."

sudo apt install zabbix-agent lm-sensors -y

    success "Pacotes instalados."
fi

echo "[6/9] Atualizando configuracao do Zabbix..."
# =========================================================
#  5 - CONFIGURACAO
# =========================================================

step "5/9" "Atualizando configuracao do Zabbix"

sudo mkdir -p /etc/zabbix

# Backup do conf antigo
# Backup configuracao antiga
if [ -f "$ZABBIX_CONF" ]; then
    sudo cp "$ZABBIX_CONF" "${ZABBIX_CONF}.bkp"
    BACKUP_FILE="${ZABBIX_CONF}.bkp"

    sudo cp "$ZABBIX_CONF" "$BACKUP_FILE"

    success "Backup criado em: $BACKUP_FILE"
fi

sudo wget -O "$ZABBIX_CONF" "$ZABBIX_CONF_URL"
echo "Baixando configuracao..."
sudo wget -q -O "$ZABBIX_CONF" "$ZABBIX_CONF_URL"

success "Configuracao atualizada."

# =========================================================
#  6 - PERMISSOES
# =========================================================

echo "[7/9] Ajustando permissoes..."
step "6/9" "Ajustando permissoes"

sudo mkdir -p /var/run/zabbix
sudo mkdir -p /var/log/zabbix
@@ -70,7 +146,13 @@ sudo chown -R zabbix:zabbix /var/log/zabbix

sudo chmod 644 "$ZABBIX_CONF"

echo "[8/9] Reiniciando servicos..."
success "Permissoes ajustadas."

# =========================================================
#  7 - SERVICOS
# =========================================================

step "7/9" "Reiniciando servicos"

sudo systemctl daemon-reload
sudo systemctl enable zabbix-agent
@@ -80,43 +162,48 @@ sleep 2

if systemctl is-active --quiet zabbix-agent; then
echo ""
    echo "====================================="
    echo " ZABBIX INSTALADO/ATUALIZADO COM SUCESSO"
    echo "====================================="
    echo "========================================================="
    echo "      ZABBIX INSTALADO/ATUALIZADO COM SUCESSO"
    echo "========================================================="
else
echo ""
    echo "====================================="
    echo " ERRO AO INICIAR O ZABBIX AGENT"
    echo "====================================="
    echo "========================================================="
    echo "         ERRO AO INICIAR O ZABBIX AGENT"
    echo "========================================================="

sudo systemctl status zabbix-agent --no-pager

exit 1
fi

echo ""
echo "[9/9] Verificando USB Monitor Videosoft..."
echo ""
# =========================================================
#  8 - USB MONITOR
# =========================================================

step "8/9" "Verificando USB Monitor Videosoft"

if [ -f /etc/cron.d/videosoft-usb-monitor ]; then
    echo "USB Monitor ja instalado. Pulando instalacao..."
    warning "USB Monitor ja instalado. Pulando instalacao..."
else
    echo "Instalando USB Monitor..."
    echo "Baixando instalador do USB Monitor..."

    wget -O /tmp/instalar_videosoft_usb_monitor.sh "$USB_MONITOR_URL"
    wget -q -O /tmp/instalar_videosoft_usb_monitor.sh "$USB_MONITOR_URL"

chmod +x /tmp/instalar_videosoft_usb_monitor.sh

    echo "Executando instalador..."
/tmp/instalar_videosoft_usb_monitor.sh

echo ""
    echo "Validando instalacao do USB Monitor..."
    echo "Validando instalacao..."

if [ -f /etc/cron.d/videosoft-usb-monitor ]; then
        echo "CRON instalado com sucesso:"
        success "CRON instalado com sucesso:"
        echo ""

cat /etc/cron.d/videosoft-usb-monitor
else
        echo "ERRO: cron do USB Monitor nao encontrado."
        error "Cron do USB Monitor nao encontrado."
exit 1
fi

@@ -125,15 +212,21 @@ else
sudo tail -n 20 /var/log/videosoft-usb-monitor.log || true

echo ""
    echo "====================================="
    echo " USB MONITOR INSTALADO COM SUCESSO"
    echo "====================================="
    echo "========================================================="
    echo "        USB MONITOR INSTALADO COM SUCESSO"
    echo "========================================================="
fi

# =========================================================
#  9 - FINALIZACAO
# =========================================================

step "9/9" "Finalizando processo"

echo ""
echo "====================================="
echo " PROCESSO FINALIZADO"
echo "====================================="
echo "========================================================="
echo "              PROCESSO FINALIZADO"
echo "========================================================="
echo ""

sudo systemctl status zabbix-agent --no-pager
