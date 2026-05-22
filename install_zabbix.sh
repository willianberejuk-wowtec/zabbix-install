#!/bin/bash

set -e

echo "====================================="
echo " INSTALACAO ZABBIX AGENT - VIDEOSOFT"
echo "====================================="

ZABBIX_CONF_URL="https://raw.githubusercontent.com/willianberejuk-wowtec/zabbix-install/main/zabbix_agentd.conf"
USB_MONITOR_URL="http://noc-totens.videosoft.com.br/instalar_videosoft_usb_monitor.sh"

cd /tmp

echo "[1/9] Baixando repositorio Zabbix..."

wget -q https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu22.04_all.deb

echo "[2/9] Instalando repositorio..."

sudo dpkg -i zabbix-release_7.0-2+ubuntu22.04_all.deb

echo "[3/9] Ajustando repositorio..."

cat > /etc/apt/sources.list.d/zabbix.list << 'EOF'
deb [arch=amd64] http://repo.zabbix.com/zabbix/7.0/ubuntu jammy main
deb-src http://repo.zabbix.com/zabbix/7.0/ubuntu jammy main
EOF

echo "[4/9] Atualizando repositorios..."

sudo apt update

echo "[5/9] Removendo instalacoes antigas..."

sudo apt remove zabbix-agent -y || true

echo "[6/9] Instalando Zabbix Agent..."

sudo apt install zabbix-agent lm-sensors -y

echo "[7/9] Baixando configuracao personalizada..."

sudo mkdir -p /etc/zabbix

sudo wget -O /etc/zabbix/zabbix_agentd.conf "$ZABBIX_CONF_URL"

echo "[8/9] Ajustando permissoes e iniciando servico..."

sudo mkdir -p /var/run/zabbix
sudo mkdir -p /var/log/zabbix

sudo chown -R zabbix:zabbix /etc/zabbix
sudo chown -R zabbix:zabbix /var/run/zabbix
sudo chown -R zabbix:zabbix /var/log/zabbix

sudo chmod 644 /etc/zabbix/zabbix_agentd.conf

sudo systemctl daemon-reload
sudo systemctl enable zabbix-agent
sudo systemctl restart zabbix-agent

echo ""
echo "====================================="
echo " ZABBIX INSTALADO COM SUCESSO"
echo "====================================="
echo ""

sleep 2

sudo systemctl status zabbix-agent --no-pager

echo ""
echo "[9/9] Instalando USB Monitor Videosoft..."
echo ""

wget -O /tmp/instalar_videosoft_usb_monitor.sh "$USB_MONITOR_URL"

sudo chmod +x /tmp/instalar_videosoft_usb_monitor.sh

sudo /tmp/instalar_videosoft_usb_monitor.sh

echo ""
echo "====================================="
echo " USB MONITOR INSTALADO COM SUCESSO"
echo "====================================="
echo ""
