#!/bin/bash

set -e

echo "====================================="
echo " INSTALACAO ZABBIX AGENT - VIDEOSOFT"
echo "====================================="

ZABBIX_CONF_URL="https://raw.githubusercontent.com/willianberejuk-wowtec/zabbix-install/main/zabbix_agentd.conf"

cd /tmp

echo "[1/8] Baixando repositorio Zabbix..."

wget -q https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu22.04_all.deb

echo "[2/8] Instalando repositorio..."

sudo dpkg -i zabbix-release_7.0-2+ubuntu22.04_all.deb

echo "[3/8] Ajustando repositorio..."

cat > /etc/apt/sources.list.d/zabbix.list << 'EOF'
deb [arch=amd64] http://repo.zabbix.com/zabbix/7.0/ubuntu jammy main
deb-src http://repo.zabbix.com/zabbix/7.0/ubuntu jammy main
EOF

echo "[4/8] Atualizando repositorios..."

sudo apt update

echo "[5/8] Removendo instalacoes antigas..."

sudo apt remove zabbix-agent -y || true

echo "[6/8] Instalando Zabbix Agent..."

sudo apt install zabbix-agent lm-sensors -y

echo "[7/8] Baixando configuracao personalizada..."

sudo mkdir -p /etc/zabbix

sudo wget -O /etc/zabbix/zabbix_agentd.conf "$ZABBIX_CONF_URL"

echo "[8/8] Ajustando permissoes e iniciando servico..."

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
