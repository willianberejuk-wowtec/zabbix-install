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

dpkg -i zabbix-release_7.0-2+ubuntu22.04_all.deb

echo "[3/8] Ajustando arquitetura do repositorio..."

sed -i 's/^deb /deb [arch=amd64] /g' /etc/apt/sources.list.d/zabbix.list

echo "[4/8] Atualizando repositorios..."

apt update

echo "[5/8] Removendo instalacoes antigas..."

apt remove zabbix-agent -y || true

echo "[6/8] Instalando Zabbix Agent..."

apt install zabbix-agent lm-sensors -y

echo "[7/8] Baixando configuracao personalizada..."

wget -O /etc/zabbix/zabbix_agentd.conf "$ZABBIX_CONF_URL"

echo "[8/8] Reiniciando servico..."

systemctl enable zabbix-agent
systemctl restart zabbix-agent

echo ""
echo "====================================="
echo " ZABBIX INSTALADO COM SUCESSO"
echo "====================================="
echo ""

systemctl status zabbix-agent --no-pager
