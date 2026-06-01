#!/bin/bash

set -e

echo "====================================="
echo " INSTALACAO ZABBIX AGENT - VIDEOSOFT"
echo "====================================="

ZABBIX_CONF_URL="https://raw.githubusercontent.com/willianberejuk-wowtec/zabbix-install/main/zabbix_agentd.conf"
USB_MONITOR_URL="http://noc-totens.videosoft.com.br/instalar_videosoft_usb_monitor.sh"

ZABBIX_CONF="/etc/zabbix/zabbix_agentd.conf"

cd /tmp

echo "[1/9] Verificando repositorio Zabbix..."

if dpkg -l | grep -q zabbix-release; then
    echo "Repositorio Zabbix ja instalado."
else
    echo "Baixando repositorio Zabbix..."

    wget -q https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu22.04_all.deb

    echo "Instalando repositorio Zabbix..."

    sudo dpkg -i zabbix-release_7.0-2+ubuntu22.04_all.deb
fi

echo "[2/9] Ajustando repositorio..."

cat > /etc/apt/sources.list.d/zabbix.list << 'EOF'
deb [arch=amd64] http://repo.zabbix.com/zabbix/7.0/ubuntu jammy main
deb-src http://repo.zabbix.com/zabbix/7.0/ubuntu jammy main
EOF

echo "[3/9] Atualizando repositorios..."

sudo apt update

echo "[4/9] Verificando instalacao do Zabbix Agent..."

if dpkg -l | grep -q zabbix-agent; then
    echo "Zabbix Agent ja instalado. Atualizando configuracao..."
else
    echo "Instalando Zabbix Agent..."

    sudo apt install zabbix-agent lm-sensors -y
fi

echo "[5/9] Atualizando configuracao do Zabbix..."

sudo mkdir -p /etc/zabbix

if [ -f "$ZABBIX_CONF" ]; then
    sudo cp "$ZABBIX_CONF" "${ZABBIX_CONF}.bkp"
fi

sudo wget -q -O "$ZABBIX_CONF" "$ZABBIX_CONF_URL"

echo "[6/9] Ajustando permissoes..."

sudo mkdir -p /var/run/zabbix
sudo mkdir -p /var/log/zabbix

sudo chown -R zabbix:zabbix /etc/zabbix
sudo chown -R zabbix:zabbix /var/run/zabbix
sudo chown -R zabbix:zabbix /var/log/zabbix

sudo chmod 644 "$ZABBIX_CONF"

echo "[7/9] Reiniciando servicos..."

sudo systemctl daemon-reload
sudo systemctl enable zabbix-agent
sudo systemctl restart zabbix-agent

sleep 2

if systemctl is-active --quiet zabbix-agent; then
    echo ""
    echo "====================================="
    echo " ZABBIX INSTALADO/ATUALIZADO COM SUCESSO"
    echo "====================================="
else
    echo ""
    echo "====================================="
    echo " ERRO AO INICIAR O ZABBIX AGENT"
    echo "====================================="

    sudo systemctl status zabbix-agent --no-pager
    exit 1
fi

echo ""
echo "[8/9] Instalando USB Monitor Videosoft..."
echo ""

rm -f /tmp/instalar_videosoft_usb_monitor.sh

echo "Limpando cache GEO..."

sudo rm -rf /opt/videosoft/geo/geo.cache

echo "Cache GEO removido."

echo "Baixando instalador do USB Monitor..."

wget -q -O /tmp/instalar_videosoft_usb_monitor.sh "$USB_MONITOR_URL"

if [ ! -f /tmp/instalar_videosoft_usb_monitor.sh ]; then
    echo "ERRO: Falha ao baixar instalador do USB Monitor."
    exit 1
fi

chmod +x /tmp/instalar_videosoft_usb_monitor.sh

echo "Executando instalador..."

bash /tmp/instalar_videosoft_usb_monitor.sh

echo ""
echo "Validando instalacao do USB Monitor..."

if [ -f /etc/cron.d/videosoft-usb-monitor ]; then
    echo "CRON instalado com sucesso:"
    cat /etc/cron.d/videosoft-usb-monitor
else
    echo "ERRO: cron do USB Monitor nao encontrado."
    exit 1
fi

echo ""
echo "Ultimas linhas do log:"
sudo tail -n 20 /var/log/videosoft-usb-monitor.log || true

echo ""
echo "====================================="
echo " USB MONITOR INSTALADO COM SUCESSO"
echo "====================================="

echo ""
echo "[9/9] Finalizando..."
echo ""

echo "====================================="
echo " PROCESSO FINALIZADO"
echo "====================================="
echo ""

sudo systemctl status zabbix-agent --no-pager
