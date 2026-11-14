#!/bin/bash
# 查看最近日志：参数 server|db|gateway|gm|edge|all
set -uo pipefail
WHAT=${1:-all}
cd /srv/dnf/ServerS5A3
if [ "$WHAT" = "server" ] || [ "$WHAT" = "all" ]; then
  echo "===== 游戏服务端日志 ====="
  docker logs --tail 120 servers5a3-local-server-1 2>&1
fi
if [ "$WHAT" = "db" ]; then
  echo "===== MariaDB 日志 ====="
  docker logs --tail 80 servers5a3-local-db-1 2>&1
fi
cd /srv/dnf/PurpleMagic
if [ "$WHAT" = "gateway" ] || [ "$WHAT" = "gm" ] || [ "$WHAT" = "edge" ] || [ "$WHAT" = "all" ]; then
  echo "===== PurpleMagic 日志 ====="
  docker compose --env-file runtime/selfhost/compose.env -f deploy/selfhost/compose.yaml logs --tail 80 gateway gm edge 2>&1
fi
