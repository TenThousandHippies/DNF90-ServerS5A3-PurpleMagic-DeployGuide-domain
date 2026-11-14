#!/bin/bash
# 停止整套服务（保留数据库卷与所有数据）
set -euo pipefail
cd /srv/dnf/PurpleMagic
docker compose --env-file runtime/selfhost/compose.env -f deploy/selfhost/compose.yaml stop
cd /srv/dnf/ServerS5A3
sh deploy/docker/manage.sh down
