#!/bin/bash
# 启动整套服务（游戏服务端 + PurpleMagic 网关/GM/edge）
set -euo pipefail
cd /srv/dnf/ServerS5A3
sh deploy/docker/manage.sh up
cd /srv/dnf/PurpleMagic
docker compose --env-file runtime/selfhost/compose.env -f deploy/selfhost/compose.yaml up -d gateway gm edge
echo "== 状态 =="
docker compose --env-file runtime/selfhost/compose.env -f deploy/selfhost/compose.yaml ps
