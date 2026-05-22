#!/bin/bash

set -e

echo "====================================="
echo " INSTALACAO ZABBIX AGENT - VIDEOSOFT"
echo "====================================="

ZABBIX_CONF="/etc/zabbix/zabbix_agentd.conf"

cd /tmp

echo "[1/8] Baixando repositorio Zabbix..."

wget -q https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu22.04_all.deb

echo "[2/8] Instalando repositorio..."

dpkg -i zabbix-release_7.0-2+ubuntu22.04_all.deb

echo "[3/8] Ajustando arquitetura do repositorio..."

# Limpar e recriar o arquivo zabbix.list com a arquitetura correta
cat > /etc/apt/sources.list.d/zabbix.list << 'EOF'
deb [arch=amd64] http://repo.zabbix.com/zabbix/7.0/ubuntu jammy main
deb-src http://repo.zabbix.com/zabbix/7.0/ubuntu jammy main
EOF

echo "[4/8] Atualizando repositorios..."

apt update

echo "[5/8] Removendo instalacoes antigas..."

apt remove zabbix-agent -y || true

echo "[6/8] Instalando Zabbix Agent..."

apt install zabbix-agent lm-sensors -y || true

echo "[7/8] Configurando arquivo de configuracao..."

# Criar configuração padrão se não existir
if [ ! -f "$ZABBIX_CONF" ]; then
    echo "Criando arquivo de configuração padrão..."
    mkdir -p /etc/zabbix
    cat > "$ZABBIX_CONF" << 'EOF'
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=127.0.0.1
ListenPort=10050
ListenIP=0.0.0.0
StartAgents=3
Hostname=Zabbix Agent
RefreshActiveChecks=120
BufferSend=5
BufferSize=100
MaxLinesPerSecond=20
Timeout=3
AllowRoot=0
EnableRemoteCommands=0
LogRemoteCommands=0
UnsafeUserParameters=0
EOF
fi

# Garantir permissões corretas
chown zabbix:zabbix "$ZABBIX_CONF"
chmod 644 "$ZABBIX_CONF"
mkdir -p /var/run/zabbix /var/log/zabbix
chown zabbix:zabbix /var/run/zabbix /var/log/zabbix

echo "[8/8] Habilitando e reiniciando servico..."

systemctl daemon-reload
systemctl enable zabbix-agent
systemctl restart zabbix-agent

echo ""
echo "====================================="
echo " ZABBIX INSTALADO COM SUCESSO"
echo "====================================="
echo ""

sleep 2
systemctl status zabbix-agent --no-pager
