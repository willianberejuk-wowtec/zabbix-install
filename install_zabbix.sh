#!/bin/bash

set -e

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

# =========================================================
#  1 - REPOSITORIO ZABBIX
# =========================================================

step "1/9" "Verificando repositorio Zabbix"

if dpkg -l | grep -q zabbix-release; then
    success "Repositorio Zabbix ja instalado."
else
    warning "Repositorio nao encontrado."

    echo "Baixando repositorio..."
    wget -q https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu22.04_all.deb

    echo "Instalando repositorio..."
    sudo dpkg -i zabbix-release_7.0-2+ubuntu22.04_all.deb

    success "Repositorio instalado."
fi

# =========================================================
#  2 - AJUSTE DO REPOSITORIO
# =========================================================

step "2/9" "Ajustando repositorio"

sudo tee /etc/apt/sources.list.d/zabbix.list > /dev/null << 'EOF'
deb [arch=amd64] http://repo.zabbix.com/zabbix/7.0/ubuntu jammy main
deb-src http://repo.zabbix.com/zabbix/7.0/ubuntu jammy main
EOF

success "Repositorio configurado."

# =========================================================
#  3 - UPDATE
# =========================================================

step "3/9" "Atualizando repositorios"

sudo apt update

success "Repositorios atualizados."

# =========================================================
#  4 - INSTALACAO DO AGENT
# =========================================================

step "4/9" "Verificando instalacao do Zabbix Agent"

if dpkg -l | grep -q zabbix-agent; then
    warning "Zabbix Agent ja instalado."
    echo "Atualizando configuracao existente..."
else
    echo "Instalando pacotes..."

    sudo apt install zabbix-agent lm-sensors -y

    success "Pacotes instalados."
fi

# =========================================================
#  5 - CONFIGURACAO
# =========================================================

step "5/9" "Atualizando configuracao do Zabbix"

sudo mkdir -p /etc/zabbix

# Backup configuracao antiga
if [ -f "$ZABBIX_CONF" ]; then
    BACKUP_FILE="${ZABBIX_CONF}.bkp"

    sudo cp "$ZABBIX_CONF" "$BACKUP_FILE"

    success "Backup criado em: $BACKUP_FILE"
fi

echo "Baixando configuracao..."
sudo wget -q -O "$ZABBIX_CONF" "$ZABBIX_CONF_URL"

success "Configuracao atualizada."

# =========================================================
#  6 - PERMISSOES
# =========================================================

step "6/9" "Ajustando permissoes"

sudo mkdir -p /var/run/zabbix
sudo mkdir -p /var/log/zabbix

sudo chown -R zabbix:zabbix /etc/zabbix
sudo chown -R zabbix:zabbix /var/run/zabbix
sudo chown -R zabbix:zabbix /var/log/zabbix

sudo chmod 644 "$ZABBIX_CONF"

success "Permissoes ajustadas."

# =========================================================
#  7 - SERVICOS
# =========================================================

step "7/9" "Reiniciando servicos"

sudo systemctl daemon-reload
sudo systemctl enable zabbix-agent
sudo systemctl restart zabbix-agent

sleep 2

if systemctl is-active --quiet zabbix-agent; then
    echo ""
    echo "========================================================="
    echo "      ZABBIX INSTALADO/ATUALIZADO COM SUCESSO"
    echo "========================================================="
else
    echo ""
    echo "========================================================="
    echo "         ERRO AO INICIAR O ZABBIX AGENT"
    echo "========================================================="

    sudo systemctl status zabbix-agent --no-pager

    exit 1
fi

# =========================================================
#  8 - USB MONITOR
# =========================================================

step "8/9" "Verificando USB Monitor Videosoft"

echo "Baixando instalador do USB Monitor..."

wget -q -O /tmp/instalar_videosoft_usb_monitor.sh "$USB_MONITOR_URL"

chmod +x /tmp/instalar_videosoft_usb_monitor.sh

echo "Executando instalador..."
sudo /tmp/instalar_videosoft_usb_monitor.sh

echo ""
echo "Validando instalacao..."

if [ -f /etc/cron.d/videosoft-usb-monitor ]; then
    success "CRON instalado com sucesso:"
    echo ""

    cat /etc/cron.d/videosoft-usb-monitor
else
    error "Cron do USB Monitor nao encontrado."
    exit 1
fi

echo ""
echo "Ultimas linhas do log:"
sudo tail -n 20 /var/log/videosoft-usb-monitor.log || true

echo ""
echo "========================================================="
echo "        USB MONITOR INSTALADO COM SUCESSO"
echo "========================================================="

# =========================================================
#  9 - FINALIZACAO
# =========================================================

step "9/9" "Finalizando processo"

echo ""
echo "========================================================="
echo "              PROCESSO FINALIZADO"
echo "========================================================="
echo ""

sudo systemctl status zabbix-agent --no-pager
