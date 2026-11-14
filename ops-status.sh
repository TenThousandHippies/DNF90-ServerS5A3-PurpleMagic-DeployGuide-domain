#!/bin/bash
# 查看状态、健康检查与最近日志
set -uo pipefail
echo "===== 游戏服务 ====="
cd /srv/dnf/ServerS5A3
docker compose -p servers5a3-local -f runtime/docker/compose.json ps
curl -s --max-time 5 http://127.0.0.1:17002/api/status; echo
echo "===== PurpleMagic ====="
cd /srv/dnf/PurpleMagic
docker compose --env-file runtime/selfhost/compose.env -f deploy/selfhost/compose.yaml ps
curl -s --max-time 5 --cacert runtime/selfhost/tls-player/ca.pem https://players.purplemagic.test:8443/api/status; echo
curl -s --max-time 5 --cacert runtime/selfhost/tls-player/ca.pem -o /dev/null -w 'bootstrap=%{http_code}\n' https://players.purplemagic.test:8443/launcher/v2/bootstrap.json
echo "===== 监听端口（游戏频道数量） ====="
HOST_IP=$(python3 -c "import json;print(json.load(open('/srv/dnf/ServerS5A3/runtime/docker/instance.json'))['host_ip'])")
ss -lnt | grep -c "$HOST_IP:10"
ss -lnt | grep -E ":(7001|8443|443|17002)\b"
